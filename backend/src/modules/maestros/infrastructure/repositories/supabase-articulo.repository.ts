import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { SupabaseService } from '../../../../shared/infrastructure/supabase/supabase.service';
import {
  IArticuloRepository,
  ArticuloSearchParams,
  ArticuloListResult,
  SaveArticuloData,
} from '../../domain/ports/articulo.repository.port';
import { Articulo } from '../../domain/entities/articulo.entity';

@Injectable()
export class SupabaseArticuloRepository implements IArticuloRepository {
  constructor(private readonly supabase: SupabaseService) {}

  async search(p: ArticuloSearchParams): Promise<ArticuloListResult> {
    const page = p.page ?? 1;
    const limit = Math.min(p.limit ?? 20, 100);
    const from = (page - 1) * limit;

    let query = this.supabase.db
      .from('articulos')
      .select('*', { count: 'exact' })
      .eq('codigo_empresa', p.codigoEmpresa)
      .order('descripcion', { ascending: true })
      .range(from, from + limit - 1);

    if (p.q) {
      query = query.or(
        `descripcion.ilike.%${p.q}%,codigo.ilike.%${p.q}%,codigo_barras.ilike.%${p.q}%`,
      );
    }
    if (p.activo !== undefined) query = query.eq('activo', p.activo);

    const { data, error, count } = await query;
    if (error) throw new InternalServerErrorException(error.message);

    const total = count ?? 0;
    return {
      data: (data ?? []).map(this.toEntity),
      total,
      page,
      lastPage: Math.ceil(total / limit) || 1,
    };
  }

  async findById(id: string, codigoEmpresa: string): Promise<Articulo | null> {
    const { data, error } = await this.supabase.db
      .from('articulos')
      .select('*')
      .eq('id', id)
      .eq('codigo_empresa', codigoEmpresa)
      .maybeSingle();
    if (error) throw new InternalServerErrorException(error.message);
    return data ? this.toEntity(data) : null;
  }

  async findByCodigo(codigo: string, codigoEmpresa: string): Promise<Articulo | null> {
    const { data, error } = await this.supabase.db
      .from('articulos')
      .select('*')
      .eq('codigo_empresa', codigoEmpresa)
      .eq('codigo', codigo.toUpperCase())
      .maybeSingle();
    if (error) throw new InternalServerErrorException(error.message);
    return data ? this.toEntity(data) : null;
  }

  async create(codigoEmpresa: string, d: SaveArticuloData): Promise<Articulo> {
    const { data, error } = await this.supabase.db
      .from('articulos')
      .insert(this.toRow(codigoEmpresa, d))
      .select()
      .single();
    if (error) throw new InternalServerErrorException(error.message);
    return this.toEntity(data);
  }

  async update(id: string, codigoEmpresa: string, d: Partial<SaveArticuloData>): Promise<Articulo> {
    const { data, error } = await this.supabase.db
      .from('articulos')
      .update(this.toPartialRow(d))
      .eq('id', id)
      .eq('codigo_empresa', codigoEmpresa)
      .select()
      .single();
    if (error) throw new InternalServerErrorException(error.message);
    return this.toEntity(data);
  }

  private toRow(empresa: string, d: SaveArticuloData) {
    return {
      codigo_empresa: empresa,
      codigo: d.codigo.toUpperCase(),
      descripcion: d.descripcion,
      codigo_linea: d.codigoLinea,
      codigo_medida: d.codigoMedida,
      codigo_marca: d.codigoMarca,
      precio_compra_base: d.precioCompraBase ?? 0,
      igv_compra: d.igvCompra ?? 0,
      precio_compra: d.precioCompra ?? 0,
      utilidad_pct: d.utilidadPct ?? 0,
      precio_venta_base: d.precioVentaBase ?? 0,
      igv_venta: d.igvVenta ?? 0,
      precio_venta: d.precioVenta ?? 0,
      fecha_registro: d.fechaRegistro,
      fecha_vencimiento: d.fechaVencimiento,
      stock_minimo: d.stockMinimo ?? 0,
      stock_maximo: d.stockMaximo ?? 0,
      codigo_barras: d.codigoBarras,
      activo: d.activo ?? true,
    };
  }

  private toPartialRow(d: Partial<SaveArticuloData>) {
    const row: Record<string, unknown> = {};
    if (d.descripcion !== undefined) row.descripcion = d.descripcion;
    if (d.codigoLinea !== undefined) row.codigo_linea = d.codigoLinea;
    if (d.codigoMedida !== undefined) row.codigo_medida = d.codigoMedida;
    if (d.codigoMarca !== undefined) row.codigo_marca = d.codigoMarca;
    if (d.precioCompraBase !== undefined) row.precio_compra_base = d.precioCompraBase;
    if (d.igvCompra !== undefined) row.igv_compra = d.igvCompra;
    if (d.precioCompra !== undefined) row.precio_compra = d.precioCompra;
    if (d.utilidadPct !== undefined) row.utilidad_pct = d.utilidadPct;
    if (d.precioVentaBase !== undefined) row.precio_venta_base = d.precioVentaBase;
    if (d.igvVenta !== undefined) row.igv_venta = d.igvVenta;
    if (d.precioVenta !== undefined) row.precio_venta = d.precioVenta;
    if (d.fechaRegistro !== undefined) row.fecha_registro = d.fechaRegistro;
    if (d.fechaVencimiento !== undefined) row.fecha_vencimiento = d.fechaVencimiento;
    if (d.stockMinimo !== undefined) row.stock_minimo = d.stockMinimo;
    if (d.stockMaximo !== undefined) row.stock_maximo = d.stockMaximo;
    if (d.codigoBarras !== undefined) row.codigo_barras = d.codigoBarras;
    if (d.activo !== undefined) row.activo = d.activo;
    return row;
  }

  private toEntity(row: Record<string, unknown>): Articulo {
    return {
      id: row.id as string,
      codigoEmpresa: row.codigo_empresa as string,
      codigo: row.codigo as string,
      descripcion: row.descripcion as string,
      codigoLinea: row.codigo_linea as string | undefined,
      codigoMedida: row.codigo_medida as string | undefined,
      codigoMarca: row.codigo_marca as string | undefined,
      precioCompraBase: Number(row.precio_compra_base),
      igvCompra: Number(row.igv_compra),
      precioCompra: Number(row.precio_compra),
      utilidadPct: Number(row.utilidad_pct),
      precioVentaBase: Number(row.precio_venta_base),
      igvVenta: Number(row.igv_venta),
      precioVenta: Number(row.precio_venta),
      fechaRegistro: row.fecha_registro as string | undefined,
      fechaVencimiento: row.fecha_vencimiento as string | undefined,
      stockMinimo: Number(row.stock_minimo),
      stockMaximo: Number(row.stock_maximo),
      codigoBarras: row.codigo_barras as string | undefined,
      pendiente: row.pendiente as boolean,
      activo: row.activo as boolean,
      createdAt: row.created_at as string | undefined,
      updatedAt: row.updated_at as string | undefined,
    };
  }
}
