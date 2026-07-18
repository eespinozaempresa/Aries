import { Injectable } from '@nestjs/common';
import { IMovimientoRepository } from '../../domain/ports/movimiento.repository.port';
import { IKardexRepository } from '../../domain/ports/kardex.repository.port';
import { IStockRepository } from '../../domain/ports/stock.repository.port';
import { SupabaseService } from '../../../../shared/infrastructure/supabase/supabase.service';

/**
 * Recalcula todo el kardex y stock de la empresa desde cero.
 * 1. Elimina kardex existente
 * 2. Resetea contadores de stock (mantiene stock_inicial y costo_promedio inicial)
 * 3. Reprocesa cada movimiento no-anulado en orden cronológico via RPC
 */
@Injectable()
export class RecalcularKardexUseCase {
  constructor(
    private readonly movimientoRepo: IMovimientoRepository,
    private readonly kardexRepo: IKardexRepository,
    private readonly stockRepo: IStockRepository,
    private readonly supabase: SupabaseService,
  ) {}

  async execute(codigoEmpresa: string): Promise<{ procesados: number }> {
    // 1. Borrar kardex
    await this.kardexRepo.deleteByEmpresa(codigoEmpresa);

    // 2. Resetear contadores de stock
    await this.stockRepo.resetForEmpresa(codigoEmpresa);

    // 3. Cargar todos los movimientos no-anulados con detalles, ordenados cronológicamente
    const { data: movimientos } = await this.supabase.db
      .from('movimientos_almacen')
      .select(`*, detalle_movimientos(*)`)
      .eq('codigo_empresa', codigoEmpresa)
      .eq('anulado', false)
      .order('fecha', { ascending: true })
      .order('created_at', { ascending: true });

    if (!movimientos) return { procesados: 0 };

    // 4. Reprocesar cada movimiento via RPC (la función SQL maneja kardex + stock)
    for (const mov of movimientos) {
      const lineas = (mov.detalle_movimientos ?? []).map((d: Record<string, unknown>) => ({
        codigoArticulo: d.codigo_articulo,
        cantidad: Number(d.cantidad),
        precioUnitario: Number(d.precio_unitario),
      }));

      if (lineas.length === 0) continue;

      await this.supabase.db.rpc('registrar_movimiento', {
        p_empresa:     codigoEmpresa,
        p_cod_doc:     mov.codigo_documento,
        p_num_doc:     mov.numero_documento,
        p_fecha:       mov.fecha,
        p_tipo:        mov.tipo,
        p_alm_origen:  mov.codigo_almacen_origen,
        p_alm_dest:    mov.codigo_almacen_dest ?? null,
        p_observacion: mov.observacion ?? null,
        p_concepto:    mov.concepto ?? null,
        p_cod_usuario: mov.codigo_usuario,
        p_lineas:      lineas,
      });
    }

    return { procesados: movimientos.length };
  }
}
