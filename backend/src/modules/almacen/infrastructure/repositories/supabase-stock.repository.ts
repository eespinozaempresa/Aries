import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { SupabaseService } from '../../../../shared/infrastructure/supabase/supabase.service';
import { IStockRepository, StockFilter } from '../../domain/ports/stock.repository.port';
import { StockItem } from '../../domain/entities/stock-item.entity';

@Injectable()
export class SupabaseStockRepository implements IStockRepository {
  constructor(private readonly supabase: SupabaseService) {}

  async query(f: StockFilter): Promise<StockItem[]> {
    let q = this.supabase.db
      .from('stock')
      .select('*')
      .eq('codigo_empresa', f.codigoEmpresa)
      .order('codigo_articulo', { ascending: true });

    if (f.codigoAlmacen) q = q.eq('codigo_almacen', f.codigoAlmacen);
    if (f.codigoArticulo) q = q.eq('codigo_articulo', f.codigoArticulo);

    const { data, error } = await q;
    if (error) throw new InternalServerErrorException(error.message);

    let items = (data ?? []).map(this.toEntity);

    if (f.soloConStock) {
      items = items.filter((s) => (s.stockActual ?? 0) > 0);
    }

    return items;
  }

  async resetForEmpresa(codigoEmpresa: string): Promise<void> {
    const { error } = await this.supabase.db
      .from('stock')
      .update({
        stock_compras: 0,
        stock_ventas: 0,
        stock_entradas: 0,
        stock_salidas: 0,
        stock_traslados_in: 0,
        stock_traslados_out: 0,
        costo_promedio: 0,
        importe_total: 0,
        fecha_actualizacion: null,
      })
      .eq('codigo_empresa', codigoEmpresa);
    if (error) throw new InternalServerErrorException(error.message);
  }

  private toEntity(row: Record<string, unknown>): StockItem {
    const si  = Number(row.stock_inicial);
    const sc  = Number(row.stock_compras);
    const sv  = Number(row.stock_ventas);
    const se  = Number(row.stock_entradas);
    const ss  = Number(row.stock_salidas);
    const sti = Number(row.stock_traslados_in);
    const sto = Number(row.stock_traslados_out);
    return {
      id: row.id as string,
      codigoEmpresa: row.codigo_empresa as string,
      codigoAlmacen: row.codigo_almacen as string,
      codigoArticulo: row.codigo_articulo as string,
      stockInicial: si,
      stockCompras: sc,
      stockVentas: sv,
      stockEntradas: se,
      stockSalidas: ss,
      stockTrasladosIn: sti,
      stockTrasladosOut: sto,
      costoPromedio: Number(row.costo_promedio),
      importeTotal: Number(row.importe_total),
      fechaActualizacion: row.fecha_actualizacion as string | undefined,
      stockActual: si + sc + se + sti - sv - ss - sto,
    };
  }
}
