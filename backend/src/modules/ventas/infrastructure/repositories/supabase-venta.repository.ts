import { Injectable, InternalServerErrorException, ConflictException } from '@nestjs/common';
import { SupabaseService } from '../../../../shared/infrastructure/supabase/supabase.service';
import { NumeroDocumentoService } from '../../../../shared/infrastructure/supabase/numero-documento.service';
import { IVentaRepository, RegistrarVentaData, VentaFilter, VentaListResult } from '../../domain/ports/venta.repository.port';
import { Venta } from '../../domain/entities/venta.entity';
import { DetalleVenta } from '../../domain/entities/detalle-venta.entity';

@Injectable()
export class SupabaseVentaRepository implements IVentaRepository {
  constructor(
    private readonly supabase: SupabaseService,
    private readonly numeracion: NumeroDocumentoService,
  ) {}

  async registrar(codigoEmpresa: string, d: RegistrarVentaData): Promise<Venta> {
    const numeroDocumento = await this.numeracion.siguiente(codigoEmpresa, d.codigoDocumento, d.serie);

    const IGV = 0.18;

    const lineasProc = d.lineas.map((l) => {
      const descPct  = l.descuentoPct ?? 0;
      const base     = l.cantidad * l.precioUnitario;
      const importe  = parseFloat((base * (1 - descPct / 100)).toFixed(2));
      return { ...l, importe, descuentoPct: descPct };
    });

    const subtotal = parseFloat(lineasProc.reduce((s, l) => s + l.importe, 0).toFixed(2));
    const igv      = parseFloat((subtotal * IGV).toFixed(2));
    const total    = parseFloat((subtotal + igv).toFixed(2));

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
        venta_id:        venta.id,
        codigo_empresa:  codigoEmpresa,
        codigo_articulo: l.codigoArticulo,
        cantidad:        l.cantidad,
        precio_unitario: l.precioUnitario,
        descuento_pct:   l.descuentoPct,
        importe:         l.importe,
      })));
    if (detErr) throw new InternalServerErrorException(detErr.message);

    // Salida de almacén via RPC
    const { error: rpcErr } = await this.supabase.db.rpc('registrar_movimiento', {
      p_empresa:     codigoEmpresa,
      p_cod_doc:     d.codigoDocumento,
      p_num_doc:     numeroDocumento,
      p_fecha:       d.fecha,
      p_tipo:        'SALIDA',
      p_alm_origen:  d.codigoAlmacen,
      p_alm_dest:    null,
      p_observacion: d.observacion ?? null,
      p_concepto:    'VENTA',
      p_cod_usuario: d.codigoUsuario,
      p_lineas:      JSON.stringify(lineasProc.map((l) => ({
        codigoArticulo: l.codigoArticulo,
        cantidad:       l.cantidad,
        precioUnitario: l.precioUnitario,
      }))),
    });
    if (rpcErr) throw new InternalServerErrorException(`Stock error: ${rpcErr.message}`);

    // CxC automática para ventas a crédito
    if (d.tipoVenta === 'CREDITO') {
      const { data: nextProv } = await this.supabase.db
        .from('cuentas_cobrar')
        .select('numero_provision')
        .eq('codigo_empresa', codigoEmpresa)
        .order('numero_provision', { ascending: false })
        .limit(1)
        .maybeSingle();

      const numProv = ((nextProv?.numero_provision as number) ?? 0) + 1;

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

    // Revertir movimiento de almacén
    const { data: movRow } = await this.supabase.db
      .from('movimientos_almacen')
      .select('id')
      .eq('codigo_empresa', codigoEmpresa)
      .eq('codigo_documento', venta.codigoDocumento)
      .eq('numero_documento', venta.numeroDocumento)
      .maybeSingle();

    if (movRow) {
      await this.supabase.db.rpc('anular_movimiento', {
        p_empresa: codigoEmpresa, p_mov_id: movRow.id, p_cod_usuario: codigoUsuario,
      });
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

    const total = count ?? 0;
    return {
      data: (data ?? []).map((r) => this.toEntity(r, [])),
      total, page, lastPage: Math.ceil(total / limit) || 1,
    };
  }

  async findById(id: string, codigoEmpresa: string): Promise<Venta | null> {
    const { data, error } = await this.supabase.db
      .from('ventas').select('*, detalle_ventas(*)')
      .eq('id', id).eq('codigo_empresa', codigoEmpresa).maybeSingle();
    if (error) throw new InternalServerErrorException(error.message);
    if (!data) return null;
    return this.toEntity(data, (data.detalle_ventas ?? []).map(this.toDetalle));
  }

  private toEntity(r: Record<string, unknown>, detalles: DetalleVenta[]): Venta {
    return {
      id: r.id as string,
      codigoEmpresa: r.codigo_empresa as string,
      codigoDocumento: r.codigo_documento as string,
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
      tipoVenta: r.tipo_venta as Venta['tipoVenta'],
      plazoDias: Number(r.plazo_dias),
      fechaVencimiento: r.fecha_vencimiento as string | undefined,
      anulado: r.anulado as boolean,
      createdAt: r.created_at as string | undefined,
      detalles,
    };
  }

  private toDetalle(r: Record<string, unknown>): DetalleVenta {
    return {
      id: r.id as string,
      ventaId: r.venta_id as string,
      codigoEmpresa: r.codigo_empresa as string,
      codigoArticulo: r.codigo_articulo as string,
      cantidad: Number(r.cantidad),
      precioUnitario: Number(r.precio_unitario),
      descuentoPct: Number(r.descuento_pct),
      importe: Number(r.importe),
    };
  }
}
