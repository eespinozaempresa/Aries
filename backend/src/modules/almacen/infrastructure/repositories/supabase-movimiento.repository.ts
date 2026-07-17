import { Injectable, InternalServerErrorException, ConflictException } from '@nestjs/common';
import { SupabaseService } from '../../../../shared/infrastructure/supabase/supabase.service';
import { NumeroDocumentoService } from '../../../../shared/infrastructure/supabase/numero-documento.service';
import {
  IMovimientoRepository,
  RegistrarMovimientoData,
  MovimientoFilter,
  MovimientoListResult,
} from '../../domain/ports/movimiento.repository.port';
import { Movimiento } from '../../domain/entities/movimiento.entity';
import { DetalleMovimiento } from '../../domain/entities/detalle-movimiento.entity';

@Injectable()
export class SupabaseMovimientoRepository implements IMovimientoRepository {
  constructor(
    private readonly supabase: SupabaseService,
    private readonly numeracion: NumeroDocumentoService,
  ) {}

  async registrar(codigoEmpresa: string, data: RegistrarMovimientoData): Promise<string> {
    const numeroDocumento = await this.numeracion.siguiente(codigoEmpresa, data.codigoDocumento, data.serie);

    const { data: result, error } = await this.supabase.db.rpc('registrar_movimiento', {
      p_empresa:     codigoEmpresa,
      p_cod_doc:     data.codigoDocumento,
      p_num_doc:     numeroDocumento,
      p_fecha:       data.fecha,
      p_tipo:        data.tipo,
      p_alm_origen:  data.codigoAlmacenOrigen,
      p_alm_dest:    data.codigoAlmacenDest ?? null,
      p_observacion: data.observacion ?? null,
      p_concepto:    data.concepto ?? null,
      p_cod_usuario: data.codigoUsuario,
      p_lineas:      data.lineas,
    });
    if (error) {
      if (error.code === '23505') throw new ConflictException('Número de documento ya existe');
      throw new InternalServerErrorException(error.message);
    }
    return result as string;
  }

  async anular(codigoEmpresa: string, movimientoId: string, codigoUsuario: string): Promise<boolean> {
    const { data, error } = await this.supabase.db.rpc('anular_movimiento', {
      p_empresa:     codigoEmpresa,
      p_mov_id:      movimientoId,
      p_cod_usuario: codigoUsuario,
    });
    if (error) throw new InternalServerErrorException(error.message);
    return data as boolean;
  }

  async list(f: MovimientoFilter): Promise<MovimientoListResult> {
    const page  = f.page ?? 1;
    const limit = Math.min(f.limit ?? 20, 100);
    const from  = (page - 1) * limit;

    let q = this.supabase.db
      .from('movimientos_almacen')
      .select('*', { count: 'exact' })
      .eq('codigo_empresa', f.codigoEmpresa)
      .order('fecha', { ascending: false })
      .order('created_at', { ascending: false })
      .range(from, from + limit - 1);

    if (f.tipo) q = q.eq('tipo', f.tipo);
    if (f.codigoAlmacen) q = q.eq('codigo_almacen_origen', f.codigoAlmacen);
    if (f.desde) q = q.gte('fecha', f.desde);
    if (f.hasta) q = q.lte('fecha', f.hasta);
    if (f.soloAnulados !== undefined) q = q.eq('anulado', f.soloAnulados);

    const { data, error, count } = await q;
    if (error) throw new InternalServerErrorException(error.message);

    const total = count ?? 0;
    return {
      data: (data ?? []).map(this.toEntity),
      total,
      page,
      lastPage: Math.ceil(total / limit) || 1,
    };
  }

  async findById(id: string, codigoEmpresa: string): Promise<Movimiento | null> {
    const { data, error } = await this.supabase.db
      .from('movimientos_almacen')
      .select('*, detalle_movimientos(*, articulos(descripcion))')
      .eq('id', id)
      .eq('codigo_empresa', codigoEmpresa)
      .maybeSingle();
    if (error) throw new InternalServerErrorException(error.message);
    if (!data) return null;
    const mov = this.toEntity(data);
    mov.detalles = (data.detalle_movimientos ?? []).map(this.toDetalle);
    return mov;
  }

  private toEntity(row: Record<string, unknown>): Movimiento {
    return {
      id: row.id as string,
      codigoEmpresa: row.codigo_empresa as string,
      codigoDocumento: row.codigo_documento as string,
      serie: (row.serie as string) ?? '0001',
      numeroDocumento: row.numero_documento as string,
      fecha: row.fecha as string,
      tipo: row.tipo as Movimiento['tipo'],
      codigoAlmacenOrigen: row.codigo_almacen_origen as string,
      codigoAlmacenDest: row.codigo_almacen_dest as string | undefined,
      observacion: row.observacion as string | undefined,
      concepto: row.concepto as string | undefined,
      codigoUsuario: row.codigo_usuario as string,
      total: Number(row.total),
      anulado: row.anulado as boolean,
      createdAt: row.created_at as string | undefined,
    };
  }

  private toDetalle(row: Record<string, unknown>): DetalleMovimiento {
    const art = row.articulos as Record<string, unknown> | null | undefined;
    return {
      id: row.id as string,
      movimientoId: row.movimiento_id as string,
      codigoEmpresa: row.codigo_empresa as string,
      codigoArticulo: row.codigo_articulo as string,
      descripcionArticulo: art?.descripcion as string | undefined,
      cantidad: Number(row.cantidad),
      precioUnitario: Number(row.precio_unitario),
      importe: Number(row.importe),
    };
  }
}
