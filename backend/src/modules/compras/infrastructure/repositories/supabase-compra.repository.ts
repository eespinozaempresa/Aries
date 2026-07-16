import { Injectable, InternalServerErrorException, ConflictException } from '@nestjs/common';
import { SupabaseService } from '../../../../shared/infrastructure/supabase/supabase.service';
import { NumeroDocumentoService } from '../../../../shared/infrastructure/supabase/numero-documento.service';
import { ICompraRepository, RegistrarCompraData, CompraFilter, CompraListResult } from '../../domain/ports/compra.repository.port';
import { Compra } from '../../domain/entities/compra.entity';
import { DetalleCompra } from '../../domain/entities/detalle-compra.entity';

@Injectable()
export class SupabaseCompraRepository implements ICompraRepository {
  constructor(
    private readonly supabase: SupabaseService,
    private readonly numeracion: NumeroDocumentoService,
  ) {}

  async registrar(codigoEmpresa: string, d: RegistrarCompraData): Promise<Compra> {
    const numeroDocumento = await this.numeracion.siguiente(codigoEmpresa, d.codigoDocumento, d.serie);

    const igvRate = 0.18;
    const tipoCambio = d.tipoCambio ?? 1;

    // Calcular totales
    let subtotal = 0;
    const lineasProc = d.lineas.map((l) => {
      const importe = parseFloat((l.cantidad * l.precioUnitario).toFixed(2));
      subtotal += importe;
      return { ...l, importe, importeUsd: parseFloat((importe / tipoCambio).toFixed(2)), precioUnitarioUsd: parseFloat((l.precioUnitario / tipoCambio).toFixed(4)) };
    });
    subtotal = parseFloat(subtotal.toFixed(2));
    const igv   = parseFloat((subtotal * igvRate).toFixed(2));
    const total = parseFloat((subtotal + igv).toFixed(2));

    // Fecha vencimiento para crédito
    let fechaVencimiento = d.fechaVencimiento;
    if (d.formaPago === 'CREDITO' && !fechaVencimiento && d.plazoDias) {
      const base = new Date(d.fecha);
      base.setDate(base.getDate() + d.plazoDias);
      fechaVencimiento = base.toISOString().substring(0, 10);
    }

    const { data: compra, error } = await this.supabase.db
      .from('compras')
      .insert({
        codigo_empresa:   codigoEmpresa,
        codigo_documento: d.codigoDocumento,
        serie:            d.serie,
        numero_documento: numeroDocumento,
        fecha:            d.fecha,
        forma_pago:       d.formaPago,
        plazo_dias:       d.plazoDias ?? 0,
        fecha_vencimiento: fechaVencimiento ?? null,
        observacion:      d.observacion ?? null,
        codigo_almacen:   d.codigoAlmacen,
        codigo_proveedor: d.codigoProveedor,
        codigo_usuario:   d.codigoUsuario,
        subtotal,
        igv,
        total,
        subtotal_usd: parseFloat((subtotal / tipoCambio).toFixed(2)),
        igv_usd:      parseFloat((igv / tipoCambio).toFixed(2)),
        total_usd:    parseFloat((total / tipoCambio).toFixed(2)),
        moneda:       d.moneda ?? 'PEN',
        tipo_cambio:  tipoCambio,
      })
      .select()
      .single();

    if (error) {
      if (error.code === '23505') throw new ConflictException('Número de documento ya registrado');
      throw new InternalServerErrorException(error.message);
    }

    // Insertar detalles
    const { error: detErr } = await this.supabase.db
      .from('detalle_compras')
      .insert(lineasProc.map((l) => ({
        compra_id:           compra.id,
        codigo_empresa:      codigoEmpresa,
        codigo_articulo:     l.codigoArticulo,
        cantidad:            l.cantidad,
        precio_unitario:     l.precioUnitario,
        importe:             l.importe,
        fecha_vencimiento:   l.fechaVencimiento ?? null,
        precio_unitario_usd: l.precioUnitarioUsd,
        importe_usd:         l.importeUsd,
      })));

    if (detErr) throw new InternalServerErrorException(detErr.message);

    // Ingreso de stock via RPC (tipo INGRESO)
    const { error: rpcErr } = await this.supabase.db.rpc('registrar_movimiento', {
      p_empresa:     codigoEmpresa,
      p_cod_doc:     d.codigoDocumento,
      p_num_doc:     numeroDocumento,
      p_fecha:       d.fecha,
      p_tipo:        'INGRESO',
      p_alm_origen:  d.codigoAlmacen,
      p_alm_dest:    null,
      p_observacion: d.observacion ?? null,
      p_concepto:    'COMPRA',
      p_cod_usuario: d.codigoUsuario,
      p_lineas:      JSON.stringify(lineasProc.map((l) => ({
        codigoArticulo: l.codigoArticulo,
        cantidad:       l.cantidad,
        precioUnitario: l.precioUnitario,
      }))),
    });

    if (rpcErr) throw new InternalServerErrorException(`Stock error: ${rpcErr.message}`);

    return this.toEntity(compra, []);
  }

  async anular(codigoEmpresa: string, compraId: string, codigoUsuario: string): Promise<Compra> {
    // Obtener compra con detalles
    const compra = await this.findById(compraId, codigoEmpresa);
    if (!compra) throw new InternalServerErrorException('Compra no encontrada');

    // Marcar como anulada
    const { data, error } = await this.supabase.db
      .from('compras')
      .update({ anulado: true })
      .eq('id', compraId)
      .eq('codigo_empresa', codigoEmpresa)
      .select()
      .single();
    if (error) throw new InternalServerErrorException(error.message);

    // Buscar el movimiento de almacén asociado y anularlo
    const { data: movRow } = await this.supabase.db
      .from('movimientos_almacen')
      .select('id')
      .eq('codigo_empresa', codigoEmpresa)
      .eq('codigo_documento', compra.codigoDocumento)
      .eq('numero_documento', compra.numeroDocumento)
      .maybeSingle();

    if (movRow) {
      await this.supabase.db.rpc('anular_movimiento', {
        p_empresa:     codigoEmpresa,
        p_mov_id:      movRow.id,
        p_cod_usuario: codigoUsuario,
      });
    }

    return this.toEntity(data, compra.detalles ?? []);
  }

  async list(f: CompraFilter): Promise<CompraListResult> {
    const page  = f.page ?? 1;
    const limit = Math.min(f.limit ?? 20, 100);
    const from  = (page - 1) * limit;

    let q = this.supabase.db
      .from('compras')
      .select('*', { count: 'exact' })
      .eq('codigo_empresa', f.codigoEmpresa)
      .order('fecha', { ascending: false })
      .order('created_at', { ascending: false })
      .range(from, from + limit - 1);

    if (f.codigoProveedor) q = q.eq('codigo_proveedor', f.codigoProveedor);
    if (f.codigoAlmacen)   q = q.eq('codigo_almacen',   f.codigoAlmacen);
    if (f.desde)           q = q.gte('fecha', f.desde);
    if (f.hasta)           q = q.lte('fecha', f.hasta);
    if (f.soloAnuladas !== undefined) q = q.eq('anulado', f.soloAnuladas);

    const { data, error, count } = await q;
    if (error) throw new InternalServerErrorException(error.message);

    const total = count ?? 0;
    return {
      data: (data ?? []).map((r) => this.toEntity(r, [])),
      total,
      page,
      lastPage: Math.ceil(total / limit) || 1,
    };
  }

  async findById(id: string, codigoEmpresa: string): Promise<Compra | null> {
    const { data, error } = await this.supabase.db
      .from('compras')
      .select('*, detalle_compras(*)')
      .eq('id', id)
      .eq('codigo_empresa', codigoEmpresa)
      .maybeSingle();
    if (error) throw new InternalServerErrorException(error.message);
    if (!data) return null;
    return this.toEntity(data, (data.detalle_compras ?? []).map(this.toDetalle));
  }

  private toEntity(r: Record<string, unknown>, detalles: DetalleCompra[]): Compra {
    return {
      id: r.id as string,
      codigoEmpresa: r.codigo_empresa as string,
      codigoDocumento: r.codigo_documento as string,
      serie: (r.serie as string) ?? '0001',
      numeroDocumento: r.numero_documento as string,
      fecha: r.fecha as string,
      formaPago: r.forma_pago as Compra['formaPago'],
      plazoDias: Number(r.plazo_dias),
      fechaVencimiento: r.fecha_vencimiento as string | undefined,
      observacion: r.observacion as string | undefined,
      codigoAlmacen: r.codigo_almacen as string,
      codigoProveedor: r.codigo_proveedor as string,
      codigoUsuario: r.codigo_usuario as string,
      subtotal: Number(r.subtotal),
      igv: Number(r.igv),
      total: Number(r.total),
      subtotalUsd: Number(r.subtotal_usd),
      igvUsd: Number(r.igv_usd),
      totalUsd: Number(r.total_usd),
      moneda: r.moneda as string,
      tipoCambio: Number(r.tipo_cambio),
      anulado: r.anulado as boolean,
      createdAt: r.created_at as string | undefined,
      detalles,
    };
  }

  private toDetalle(r: Record<string, unknown>): DetalleCompra {
    return {
      id: r.id as string,
      compraId: r.compra_id as string,
      codigoEmpresa: r.codigo_empresa as string,
      codigoArticulo: r.codigo_articulo as string,
      cantidad: Number(r.cantidad),
      precioUnitario: Number(r.precio_unitario),
      importe: Number(r.importe),
      fechaVencimiento: r.fecha_vencimiento as string | undefined,
      precioUnitarioUsd: Number(r.precio_unitario_usd),
      importeUsd: Number(r.importe_usd),
    };
  }
}
