import { Injectable, InternalServerErrorException, ConflictException } from '@nestjs/common';
import { SupabaseService } from '../../../../shared/infrastructure/supabase/supabase.service';
import { NumeroDocumentoService } from '../../../../shared/infrastructure/supabase/numero-documento.service';
import { IFormulaRepository } from '../../../maestros/domain/ports/formula.repository.port';
import { IVentaRepository, RegistrarVentaData, VentaFilter, VentaListResult, ReporteVentasFilter, ReporteGeneralFilter } from '../../domain/ports/venta.repository.port';
import { Venta } from '../../domain/entities/venta.entity';
import { DetalleVenta } from '../../domain/entities/detalle-venta.entity';

@Injectable()
export class SupabaseVentaRepository implements IVentaRepository {
  constructor(
    private readonly supabase: SupabaseService,
    private readonly numeracion: NumeroDocumentoService,
    private readonly formulas: IFormulaRepository,
  ) {}

  async registrar(codigoEmpresa: string, d: RegistrarVentaData): Promise<Venta> {
    const numeroDocumento = await this.numeracion.siguiente(codigoEmpresa, d.codigoDocumento, d.serie);

    // IGV dinámico: leer de parametros y verificar aplica_igv del documento
    const [paramRes, docRes] = await Promise.all([
      this.supabase.db.from('parametros').select('igv, almacen_partes')
        .eq('codigo_empresa', codigoEmpresa).maybeSingle(),
      this.supabase.db.from('documentos').select('aplica_igv')
        .eq('codigo_empresa', codigoEmpresa)
        .eq('codigo', d.codigoDocumento).maybeSingle(),
    ]);
    const aplicaIgv = docRes.data?.aplica_igv ?? true;
    const igvRate    = aplicaIgv ? (Number(paramRes.data?.igv ?? 18) / 100) : 0;
    const moneda     = d.moneda ?? 'PEN';
    const tipoCambio = d.tipoCambio ?? 1;
    // Almacén de Partes: si está configurado, las Partes explotadas de una fórmula
    // se descuentan de ese almacén; si no, caen en el almacén elegido en la venta.
    const almacenPartesDestino = (paramRes.data as any)?.almacen_partes || d.codigoAlmacen;

    const lineasProc = d.lineas.map((l) => {
      const descPct     = l.descuentoPct ?? 0;
      const base        = l.cantidad * l.precioUnitario;
      const importeMon  = parseFloat((base * (1 - descPct / 100)).toFixed(2));

      const importePen  = moneda === 'USD' ? parseFloat((importeMon * tipoCambio).toFixed(2)) : importeMon;
      const importeUsd  = moneda === 'USD' ? importeMon : parseFloat((importeMon / tipoCambio).toFixed(2));
      const precUsd     = moneda === 'USD' ? l.precioUnitario : parseFloat((l.precioUnitario / tipoCambio).toFixed(4));

      return { ...l, importe: importePen, importeUsd, descuentoPct: descPct, precioUnitarioUsd: precUsd };
    });

    const subtotal    = parseFloat(lineasProc.reduce((s, l) => s + l.importe, 0).toFixed(2));
    const igv         = parseFloat((subtotal * igvRate).toFixed(2));
    const total       = parseFloat((subtotal + igv).toFixed(2));
    const subtotalUsd = parseFloat(lineasProc.reduce((s, l) => s + l.importeUsd, 0).toFixed(2));
    const igvUsd      = parseFloat((subtotalUsd * igvRate).toFixed(2));
    const totalUsd    = parseFloat((subtotalUsd + igvUsd).toFixed(2));

    let fechaVencimiento = d.fechaVencimiento;
    if (d.tipoVenta === 'CREDITO' && !fechaVencimiento && d.plazoDias) {
      const base = new Date(d.fecha);
      base.setDate(base.getDate() + d.plazoDias);
      fechaVencimiento = base.toISOString().substring(0, 10);
    }

    const { data: venta, error } = await this.supabase.db
      .from('ventas')
      .insert({
        codigo_empresa:    codigoEmpresa,
        codigo_documento:  d.codigoDocumento,
        serie:             d.serie,
        numero_documento:  numeroDocumento,
        fecha:             d.fecha,
        observacion:       d.observacion ?? null,
        codigo_almacen:    d.codigoAlmacen,
        codigo_cliente:    d.codigoCliente,
        codigo_usuario:    d.codigoUsuario,
        subtotal, igv, total,
        subtotal_usd: subtotalUsd,
        igv_usd:      igvUsd,
        total_usd:    totalUsd,
        moneda,
        tipo_cambio:  tipoCambio,
        tipo_venta:        d.tipoVenta,
        plazo_dias:        d.plazoDias ?? 0,
        fecha_vencimiento: fechaVencimiento ?? null,
      })
      .select().single();

    if (error) {
      if (error.code === '23505') throw new ConflictException('Número de documento ya registrado');
      throw new InternalServerErrorException(error.message);
    }

    const { error: detErr } = await this.supabase.db
      .from('detalle_ventas')
      .insert(lineasProc.map((l) => ({
        venta_id:             venta.id,
        codigo_empresa:       codigoEmpresa,
        codigo_articulo:      l.codigoArticulo,
        cantidad:             l.cantidad,
        precio_unitario:      moneda === 'USD' ? parseFloat((l.precioUnitario * tipoCambio).toFixed(4)) : l.precioUnitario,
        descuento_pct:        l.descuentoPct,
        importe:              l.importe,
        precio_unitario_usd:  l.precioUnitarioUsd,
        importe_usd:          l.importeUsd,
      })));
    if (detErr) throw new InternalServerErrorException(detErr.message);

    // Explosión de fórmula (BOM): además del Principal, descontar sus Partes
    const codigosVendidos = [...new Set(lineasProc.map((l) => l.codigoArticulo))];
    const formulasActivas = await this.formulas.findActivasByArticulos(codigoEmpresa, codigosVendidos);

    const lineasPartes: { codigoArticulo: string; cantidad: number; precioUnitario: number }[] = [];
    if (formulasActivas.size) {
      const codigosComponentes = [...new Set(
        [...formulasActivas.values()].flat().map((c) => c.codigoArticulo),
      )];
      const { data: stockComponentes } = await this.supabase.db
        .from('stock')
        .select('codigo_articulo, costo_promedio')
        .eq('codigo_empresa', codigoEmpresa)
        .eq('codigo_almacen', almacenPartesDestino)
        .in('codigo_articulo', codigosComponentes);
      const costoMap = new Map((stockComponentes ?? []).map((s: any) => [s.codigo_articulo, Number(s.costo_promedio)]));

      for (const l of lineasProc) {
        const componentes = formulasActivas.get(l.codigoArticulo);
        if (!componentes) continue;
        for (const c of componentes) {
          lineasPartes.push({
            codigoArticulo: c.codigoArticulo,
            cantidad:       l.cantidad * c.cantidad,
            precioUnitario: costoMap.get(c.codigoArticulo) ?? 0,
          });
        }
      }
    }

    // Salida de almacén via RPC (Principal + Partes explotadas de su fórmula).
    // Si el Almacén de Partes configurado difiere del almacén de la venta, se
    // generan dos movimientos: uno para el/los Principal(es) en el almacén de
    // la venta (como siempre), y otro (sufijo "-P") para las Partes en el
    // Almacén de Partes.
    const lineasPrincipales = lineasProc.map((l) => ({
      codigoArticulo: l.codigoArticulo,
      cantidad:       l.cantidad,
      precioUnitario: l.precioUnitario,
    }));
    const registrarSalida = (numDoc: string, almOrigen: string, lineas: typeof lineasPrincipales) =>
      this.supabase.db.rpc('registrar_movimiento', {
        p_empresa:     codigoEmpresa,
        p_cod_doc:     d.codigoDocumento,
        p_num_doc:     numDoc,
        p_fecha:       d.fecha,
        p_tipo:        'SALIDA',
        p_alm_origen:  almOrigen,
        p_alm_dest:    null,
        p_observacion: d.observacion ?? null,
        p_concepto:    'VENTA',
        p_cod_usuario: d.codigoUsuario,
        p_lineas:      lineas,
        p_serie:       d.serie ?? '0001',
      });

    if (lineasPartes.length && almacenPartesDestino !== d.codigoAlmacen) {
      const { error: rpcErr1 } = await registrarSalida(numeroDocumento, d.codigoAlmacen, lineasPrincipales);
      if (rpcErr1) throw new InternalServerErrorException(`Stock error: ${rpcErr1.message}`);

      const { error: rpcErr2 } = await registrarSalida(`${numeroDocumento}-P`, almacenPartesDestino, lineasPartes);
      if (rpcErr2) throw new InternalServerErrorException(`Stock error (partes): ${rpcErr2.message}`);
    } else {
      const { error: rpcErr } = await registrarSalida(numeroDocumento, d.codigoAlmacen, [...lineasPrincipales, ...lineasPartes]);
      if (rpcErr) throw new InternalServerErrorException(`Stock error: ${rpcErr.message}`);
    }

    // CxC automática para ventas a crédito
    if (d.tipoVenta === 'CREDITO') {
      const { data: maxRow } = await this.supabase.db
        .from('cuentas_cobrar')
        .select('numero_provision')
        .eq('codigo_empresa', codigoEmpresa)
        .order('numero_provision', { ascending: false })
        .limit(1)
        .maybeSingle();
      const numProv = (maxRow?.numero_provision ?? 0) + 1;

      await this.supabase.db.from('cuentas_cobrar').insert({
        codigo_empresa:    codigoEmpresa,
        numero_provision:  numProv,
        tipo:              'VENTA',
        codigo_documento:  d.codigoDocumento,
        numero_documento:  numeroDocumento,
        monto_total:       total,
        monto_pagado:      0,
        saldo:             total,
        fecha_emision:     d.fecha,
        fecha_vencimiento: fechaVencimiento ?? null,
        codigo_cliente:    d.codigoCliente,
        pendiente:         true,
      });
    }

    return this.toEntity(venta, []);
  }

  async anular(codigoEmpresa: string, ventaId: string, codigoUsuario: string): Promise<Venta> {
    const venta = await this.findById(ventaId, codigoEmpresa);
    if (!venta) throw new InternalServerErrorException('Venta no encontrada');

    const { data, error } = await this.supabase.db
      .from('ventas')
      .update({ anulado: true })
      .eq('id', ventaId).eq('codigo_empresa', codigoEmpresa)
      .select().single();
    if (error) throw new InternalServerErrorException(error.message);

    // Revertir movimiento(s) de almacén. Si la venta incluía artículos con fórmula
    // y el Almacén de Partes difería del almacén de la venta, se generaron dos
    // movimientos (el propio y uno con sufijo "-P" para las Partes); se revierten
    // ambos si existen.
    const numerosDocumento = [venta.numeroDocumento, `${venta.numeroDocumento}-P`];
    for (const numDoc of numerosDocumento) {
      const { data: movRow } = await this.supabase.db
        .from('movimientos_almacen')
        .select('id')
        .eq('codigo_empresa', codigoEmpresa)
        .eq('codigo_documento', venta.codigoDocumento)
        .eq('numero_documento', numDoc)
        .maybeSingle();

      if (movRow) {
        await this.supabase.db.rpc('anular_movimiento', {
          p_empresa: codigoEmpresa, p_mov_id: movRow.id, p_cod_usuario: codigoUsuario,
        });
        // Eliminar registros físicamente para que movimientos_almacen quede limpio
        await this.supabase.db.from('detalle_movimientos').delete()
          .eq('movimiento_id', movRow.id).eq('codigo_empresa', codigoEmpresa);
        await this.supabase.db.from('movimientos_almacen').delete()
          .eq('id', movRow.id).eq('codigo_empresa', codigoEmpresa);
      }
    }

    // Marcar CxC como no pendiente (anulada de facto)
    await this.supabase.db
      .from('cuentas_cobrar')
      .update({ pendiente: false })
      .eq('codigo_empresa', codigoEmpresa)
      .eq('codigo_documento', venta.codigoDocumento)
      .eq('numero_documento', venta.numeroDocumento);

    return this.toEntity(data, venta.detalles ?? []);
  }

  async eliminar(codigoEmpresa: string, id: string): Promise<void> {
    const venta = await this.findById(id, codigoEmpresa);
    if (!venta) throw new InternalServerErrorException('Venta no encontrada');
    if (!venta.anulado) throw new InternalServerErrorException('Solo se pueden eliminar ventas anuladas');

    await this.supabase.db.from('detalle_ventas').delete()
      .eq('venta_id', id).eq('codigo_empresa', codigoEmpresa);

    const { error } = await this.supabase.db.from('ventas').delete()
      .eq('id', id).eq('codigo_empresa', codigoEmpresa);
    if (error) throw new InternalServerErrorException(error.message);
  }

  async list(f: VentaFilter): Promise<VentaListResult> {
    const page  = f.page ?? 1;
    const limit = Math.min(f.limit ?? 20, 100);
    const from  = (page - 1) * limit;

    let q = this.supabase.db
      .from('ventas').select('*', { count: 'exact' })
      .eq('codigo_empresa', f.codigoEmpresa)
      .order('fecha', { ascending: false })
      .order('created_at', { ascending: false })
      .range(from, from + limit - 1);

    if (f.codigoCliente)  q = q.eq('codigo_cliente',  f.codigoCliente);
    if (f.codigoAlmacen)  q = q.eq('codigo_almacen',  f.codigoAlmacen);
    if (f.desde)          q = q.gte('fecha', f.desde);
    if (f.hasta)          q = q.lte('fecha', f.hasta);
    if (f.soloAnuladas !== undefined) q = q.eq('anulado', f.soloAnuladas);

    const { data, error, count } = await q;
    if (error) throw new InternalServerErrorException(error.message);

    const rows = data ?? [];
    const clienteCodes   = [...new Set(rows.map((r) => r.codigo_cliente  as string))];
    const almacenCodes   = [...new Set(rows.map((r) => r.codigo_almacen  as string))];
    const documentoCodes = [...new Set(rows.map((r) => r.codigo_documento as string))];

    const [{ data: clientes }, { data: almacenes }, { data: documentos }] = await Promise.all([
      clienteCodes.length
        ? this.supabase.db.from('clientes').select('codigo, razon_social').eq('codigo_empresa', f.codigoEmpresa).in('codigo', clienteCodes)
        : Promise.resolve({ data: [] }),
      almacenCodes.length
        ? this.supabase.db.from('almacenes').select('codigo, descripcion').eq('codigo_empresa', f.codigoEmpresa).in('codigo', almacenCodes)
        : Promise.resolve({ data: [] }),
      documentoCodes.length
        ? this.supabase.db.from('documentos').select('codigo, abreviatura').eq('codigo_empresa', f.codigoEmpresa).in('codigo', documentoCodes)
        : Promise.resolve({ data: [] }),
    ]);

    const clienteMap   = new Map((clientes  ?? []).map((c: any) => [c.codigo, c.razon_social]));
    const almacenMap   = new Map((almacenes ?? []).map((a: any) => [a.codigo, a.descripcion]));
    const documentoMap = new Map((documentos ?? []).map((d: any) => [d.codigo, d.abreviatura]));

    const total = count ?? 0;
    return {
      data: rows.map((r) => this.toEntity(r, [], {
        razonSocialCliente:  clienteMap.get(r.codigo_cliente  as string),
        descripcionAlmacen:  almacenMap.get(r.codigo_almacen  as string),
        abreviaturaDocumento: documentoMap.get(r.codigo_documento as string),
      })),
      total, page, lastPage: Math.ceil(total / limit) || 1,
    };
  }

  async findById(id: string, codigoEmpresa: string): Promise<Venta | null> {
    const { data, error } = await this.supabase.db
      .from('ventas').select('*, detalle_ventas(*, articulos(descripcion))')
      .eq('id', id).eq('codigo_empresa', codigoEmpresa).maybeSingle();
    if (error) throw new InternalServerErrorException(error.message);
    if (!data) return null;

    const [{ data: cliente }, { data: almacen }, { data: documento }] = await Promise.all([
      this.supabase.db.from('clientes').select('razon_social').eq('codigo_empresa', codigoEmpresa).eq('codigo', data.codigo_cliente).maybeSingle(),
      this.supabase.db.from('almacenes').select('descripcion').eq('codigo_empresa', codigoEmpresa).eq('codigo', data.codigo_almacen).maybeSingle(),
      this.supabase.db.from('documentos').select('abreviatura').eq('codigo_empresa', codigoEmpresa).eq('codigo', data.codigo_documento).maybeSingle(),
    ]);

    return this.toEntity(data, (data.detalle_ventas ?? []).map(this.toDetalle), {
      razonSocialCliente:  cliente?.razon_social,
      descripcionAlmacen:  almacen?.descripcion,
      abreviaturaDocumento: (documento as any)?.abreviatura,
    });
  }

  async reporteVentas(codigoEmpresa: string, params: ReporteVentasFilter): Promise<unknown[]> {
    let query = this.supabase.db
      .from('ventas')
      .select('id, fecha, serie, numero_documento, tipo_venta, anulado, subtotal, igv, total, codigo_cliente, codigo_documento')
      .eq('codigo_empresa', codigoEmpresa)
      .order('tipo_venta')
      .order('fecha');

    if (params.desde) query = query.gte('fecha', params.desde);
    if (params.hasta) query = query.lte('fecha', params.hasta);
    if (params.almacen) query = query.eq('codigo_almacen', params.almacen);
    if (params.tipoVenta) query = query.eq('tipo_venta', params.tipoVenta.toUpperCase());

    const { data: ventas, error } = await query;
    if (error) throw new InternalServerErrorException(error.message);
    if (!ventas?.length) return [];

    const clienteCodigos = [...new Set(ventas.map((v: any) => v.codigo_cliente))];
    const docCodigos = [...new Set(ventas.map((v: any) => v.codigo_documento))];

    const [{ data: clientes }, { data: docs }] = await Promise.all([
      this.supabase.db.from('clientes').select('codigo, razon_social').eq('codigo_empresa', codigoEmpresa).in('codigo', clienteCodigos),
      this.supabase.db.from('documentos').select('codigo, abreviatura').eq('codigo_empresa', codigoEmpresa).in('codigo', docCodigos),
    ]);

    const clienteMap: Record<string, string> = Object.fromEntries((clientes ?? []).map((c: any) => [c.codigo, c.razon_social]));
    const docMap: Record<string, string>     = Object.fromEntries((docs ?? []).map((d: any) => [d.codigo, d.abreviatura]));

    if (params.tipo === 'general') {
      return ventas.map((v: any) => ({
        tipoVenta: v.tipo_venta,
        fecha: v.fecha,
        documento: docMap[v.codigo_documento] ?? v.codigo_documento,
        serie: v.serie,
        numero: v.numero_documento,
        cliente: clienteMap[v.codigo_cliente] ?? v.codigo_cliente,
        anulado: v.anulado as boolean,
        subtotal: Number(v.subtotal),
        igv: Number(v.igv),
        total: Number(v.total),
      }));
    }

    // Detallado
    const ventaIds = ventas.map((v: any) => v.id);
    const ventaMap: Record<string, any> = Object.fromEntries(ventas.map((v: any) => [v.id, v]));

    const { data: detalles, error: detError } = await this.supabase.db
      .from('detalle_ventas')
      .select('venta_id, codigo_articulo, cantidad, importe')
      .in('venta_id', ventaIds);
    if (detError) throw new InternalServerErrorException(detError.message);
    if (!detalles?.length) return [];

    const artCodigos = [...new Set(detalles.map((d: any) => d.codigo_articulo))];
    const { data: articulos } = await this.supabase.db
      .from('articulos')
      .select('codigo, descripcion, codigo_medida')
      .eq('codigo_empresa', codigoEmpresa)
      .in('codigo', artCodigos);

    const artMap: Record<string, any> = Object.fromEntries((articulos ?? []).map((a: any) => [a.codigo, a]));

    return detalles.map((d: any) => {
      const v = ventaMap[d.venta_id];
      const art = artMap[d.codigo_articulo] ?? {};
      return {
        tipoVenta: v?.tipo_venta,
        fecha: v?.fecha,
        documento: docMap[v?.codigo_documento] ?? v?.codigo_documento,
        serie: v?.serie,
        numero: v?.numero_documento,
        cliente: clienteMap[v?.codigo_cliente] ?? v?.codigo_cliente,
        articulo: art.descripcion ?? d.codigo_articulo,
        unidadMedida: art.codigo_medida ?? '',
        cantidad: Number(d.cantidad),
        total: Number(d.importe),
      };
    });
  }

  async reporteGeneral(codigoEmpresa: string, params: ReporteGeneralFilter): Promise<unknown[]> {
    let ventasQuery = this.supabase.db
      .from('ventas')
      .select('id, fecha, codigo_cliente, codigo_almacen, codigo_usuario')
      .eq('codigo_empresa', codigoEmpresa)
      .eq('anulado', false);

    if (params.desde) ventasQuery = ventasQuery.gte('fecha', params.desde);
    if (params.hasta) ventasQuery = ventasQuery.lte('fecha', params.hasta);
    if (params.almacen) ventasQuery = ventasQuery.eq('codigo_almacen', params.almacen);
    if (params.cliente) ventasQuery = ventasQuery.eq('codigo_cliente', params.cliente);
    if (params.usuario) ventasQuery = ventasQuery.eq('codigo_usuario', params.usuario);

    const { data: ventas, error: ventasError } = await ventasQuery;
    if (ventasError) throw new InternalServerErrorException(ventasError.message);
    if (!ventas?.length) return [];

    const ventaIds  = ventas.map((v: any) => v.id);
    const ventaMap: Record<string, any> = Object.fromEntries(ventas.map((v: any) => [v.id, v]));

    const clienteCodigos = [...new Set(ventas.map((v: any) => v.codigo_cliente).filter(Boolean))];
    const almacenCodigos = [...new Set(ventas.map((v: any) => v.codigo_almacen).filter(Boolean))];
    const usuarioCodigos = [...new Set(ventas.map((v: any) => v.codigo_usuario).filter(Boolean))];

    let detallesQuery = this.supabase.db
      .from('detalle_ventas')
      .select('venta_id, codigo_articulo, cantidad, importe')
      .in('venta_id', ventaIds);
    if (params.articulo) detallesQuery = detallesQuery.eq('codigo_articulo', params.articulo);

    const [
      { data: detalles, error: detError },
      { data: clientes },
      { data: almacenes },
      { data: usuarios },
    ] = await Promise.all([
      detallesQuery,
      clienteCodigos.length
        ? this.supabase.db.from('clientes').select('codigo, razon_social').eq('codigo_empresa', codigoEmpresa).in('codigo', clienteCodigos)
        : Promise.resolve({ data: [] }),
      almacenCodigos.length
        ? this.supabase.db.from('almacenes').select('codigo, descripcion').eq('codigo_empresa', codigoEmpresa).in('codigo', almacenCodigos)
        : Promise.resolve({ data: [] }),
      usuarioCodigos.length
        ? this.supabase.db.from('usuarios').select('codigo, nombre').eq('codigo_empresa', codigoEmpresa).in('codigo', usuarioCodigos)
        : Promise.resolve({ data: [] }),
    ]);

    if (detError) throw new InternalServerErrorException(detError.message);
    if (!detalles?.length) return [];

    const clienteMap: Record<string, string> = Object.fromEntries((clientes ?? []).map((c: any) => [c.codigo, c.razon_social]));
    const almacenMap: Record<string, string> = Object.fromEntries((almacenes ?? []).map((a: any) => [a.codigo, a.descripcion]));
    const usuarioMap: Record<string, string> = Object.fromEntries((usuarios ?? []).map((u: any) => [u.codigo, u.nombre ?? u.codigo]));

    const artCodigos = [...new Set(detalles.map((d: any) => d.codigo_articulo))];
    const { data: articulos } = await this.supabase.db
      .from('articulos')
      .select('codigo, descripcion, codigo_medida, codigo_linea')
      .eq('codigo_empresa', codigoEmpresa)
      .in('codigo', artCodigos);

    const lineaCodigos = [...new Set((articulos ?? []).map((a: any) => a.codigo_linea).filter(Boolean))];
    const { data: lineas } = lineaCodigos.length
      ? await this.supabase.db.from('lineas').select('codigo, descripcion').eq('codigo_empresa', codigoEmpresa).in('codigo', lineaCodigos)
      : { data: [] };

    const artMap: Record<string, any>      = Object.fromEntries((articulos ?? []).map((a: any) => [a.codigo, a]));
    const lineaMap: Record<string, string> = Object.fromEntries((lineas ?? []).map((l: any) => [l.codigo, l.descripcion as string]));

    const rows = detalles.map((d: any) => {
      const v   = ventaMap[d.venta_id] ?? {};
      const art = artMap[d.codigo_articulo] ?? {};
      return {
        codigoLinea:  art.codigo_linea ?? '',
        linea:        lineaMap[art.codigo_linea] ?? art.codigo_linea ?? 'Sin línea',
        fecha:        v.fecha ?? '',
        cliente:      clienteMap[v.codigo_cliente] ?? v.codigo_cliente ?? '',
        almacen:      almacenMap[v.codigo_almacen] ?? v.codigo_almacen ?? '',
        usuario:      usuarioMap[v.codigo_usuario] ?? v.codigo_usuario ?? '',
        articulo:     art.descripcion ?? d.codigo_articulo,
        unidadMedida: art.codigo_medida ?? '',
        cantidad:     Number(d.cantidad),
        total:        Number(d.importe),
      };
    });

    return rows.sort((a: any, b: any) => a.codigoLinea.localeCompare(b.codigoLinea));
  }

  private toEntity(r: Record<string, unknown>, detalles: DetalleVenta[], extras: { razonSocialCliente?: string; descripcionAlmacen?: string; abreviaturaDocumento?: string } = {}): Venta {
    return {
      id: r.id as string,
      codigoEmpresa: r.codigo_empresa as string,
      codigoDocumento: r.codigo_documento as string,
      abreviaturaDocumento: extras.abreviaturaDocumento,
      serie: (r.serie as string) ?? '0001',
      numeroDocumento: r.numero_documento as string,
      fecha: r.fecha as string,
      observacion: r.observacion as string | undefined,
      codigoAlmacen: r.codigo_almacen as string,
      codigoCliente: r.codigo_cliente as string,
      codigoUsuario: r.codigo_usuario as string,
      subtotal: Number(r.subtotal),
      igv: Number(r.igv),
      total: Number(r.total),
      subtotalUsd: Number(r.subtotal_usd ?? 0),
      igvUsd: Number(r.igv_usd ?? 0),
      totalUsd: Number(r.total_usd ?? 0),
      moneda: (r.moneda as string) ?? 'PEN',
      tipoCambio: Number(r.tipo_cambio ?? 1),
      tipoVenta: r.tipo_venta as Venta['tipoVenta'],
      plazoDias: Number(r.plazo_dias),
      fechaVencimiento: r.fecha_vencimiento as string | undefined,
      anulado: r.anulado as boolean,
      createdAt: r.created_at as string | undefined,
      detalles,
      razonSocialCliente:  extras.razonSocialCliente,
      descripcionAlmacen:  extras.descripcionAlmacen,
    };
  }

  private toDetalle(r: Record<string, unknown>): DetalleVenta {
    const art = r.articulos as Record<string, unknown> | null | undefined;
    return {
      id: r.id as string,
      ventaId: r.venta_id as string,
      codigoEmpresa: r.codigo_empresa as string,
      codigoArticulo: r.codigo_articulo as string,
      descripcionArticulo: art?.descripcion as string | undefined,
      cantidad: Number(r.cantidad),
      precioUnitario: Number(r.precio_unitario),
      descuentoPct: Number(r.descuento_pct),
      importe: Number(r.importe),
      precioUnitarioUsd: Number(r.precio_unitario_usd ?? 0),
      importeUsd: Number(r.importe_usd ?? 0),
    };
  }
}
