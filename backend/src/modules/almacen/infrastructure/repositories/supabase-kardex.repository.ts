import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { SupabaseService } from '../../../../shared/infrastructure/supabase/supabase.service';
import { IKardexRepository, KardexFilter } from '../../domain/ports/kardex.repository.port';
import { KardexItem } from '../../domain/entities/kardex-item.entity';

@Injectable()
export class SupabaseKardexRepository implements IKardexRepository {
  constructor(private readonly supabase: SupabaseService) {}

  async query(f: KardexFilter): Promise<KardexItem[]> {
    let q = this.supabase.db
      .from('kardex')
      .select('*')
      .eq('codigo_empresa', f.codigoEmpresa)
      .order('fecha', { ascending: true })
      .order('id', { ascending: true });

    if (f.codigoAlmacen)  q = q.eq('codigo_almacen',  f.codigoAlmacen);
    if (f.codigoArticulo) q = q.eq('codigo_articulo', f.codigoArticulo);
    if (f.desde) q = q.gte('fecha', f.desde);
    if (f.hasta) q = q.lte('fecha', f.hasta);

    const { data, error } = await q;
    if (error) throw new InternalServerErrorException(error.message);
    return (data ?? []).map(this.toEntity);
  }

  async deleteByEmpresa(codigoEmpresa: string): Promise<void> {
    const { error } = await this.supabase.db
      .from('kardex')
      .delete()
      .eq('codigo_empresa', codigoEmpresa);
    if (error) throw new InternalServerErrorException(error.message);
  }

  private toEntity(row: Record<string, unknown>): KardexItem {
    return {
      id: row.id as number,
      codigoEmpresa: row.codigo_empresa as string,
      codigoAlmacen: row.codigo_almacen as string,
      codigoArticulo: row.codigo_articulo as string,
      fecha: row.fecha as string,
      codigoDocumento: row.codigo_documento as string,
      numeroDocumento: row.numero_documento as string,
      tipo: row.tipo as string,
      cantEntrada: Number(row.cant_entrada),
      precioEntrada: Number(row.precio_entrada),
      importeEntrada: Number(row.importe_entrada),
      cantSalida: Number(row.cant_salida),
      precioSalida: Number(row.precio_salida),
      importeSalida: Number(row.importe_salida),
      stock: Number(row.stock),
      precioStock: Number(row.precio_stock),
      importeStock: Number(row.importe_stock),
    };
  }
}
