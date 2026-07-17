import { Injectable, InternalServerErrorException, NotFoundException } from '@nestjs/common';
import { SupabaseService } from '../../../../shared/infrastructure/supabase/supabase.service';
import {
  IListaPrecioRepository,
  SaveListaPrecioData,
} from '../../domain/ports/lista-precio.repository.port';
import { ListaPrecio } from '../../domain/entities/lista-precio.entity';

@Injectable()
export class SupabaseListaPrecioRepository implements IListaPrecioRepository {
  constructor(private readonly supabase: SupabaseService) {}

  async findByArticulo(codigoEmpresa: string, idArticulo: string): Promise<ListaPrecio[]> {
    const { data, error } = await this.supabase.db
      .from('lista_precios')
      .select('*')
      .eq('codigo_empresa', codigoEmpresa)
      .eq('id_articulo', idArticulo)
      .order('created_at', { ascending: true });
    if (error) throw new InternalServerErrorException(error.message);
    return (data ?? []).map(this.toEntity);
  }

  async findByTipoLista(
    codigoEmpresa: string,
    idArticulo: string,
    idTipoLista: string,
  ): Promise<ListaPrecio | null> {
    const { data, error } = await this.supabase.db
      .from('lista_precios')
      .select('*')
      .eq('codigo_empresa', codigoEmpresa)
      .eq('id_articulo', idArticulo)
      .eq('id_tipo_lista', idTipoLista)
      .eq('activo', true)
      .maybeSingle();
    if (error) throw new InternalServerErrorException(error.message);
    return data ? this.toEntity(data) : null;
  }

  async save(codigoEmpresa: string, d: SaveListaPrecioData, id?: string): Promise<ListaPrecio> {
    const row = {
      id_articulo:       d.idArticulo,
      id_tipo_lista:     d.idTipoLista,
      precio_venta_base: d.precioVentaBase,
      descuento_pct:     d.descuentoPct,
      descuento_monto:   d.descuentoMonto,
      precio_venta:      d.precioVenta,
      activo:            d.activo ?? true,
    };

    if (id) {
      const { data, error } = await this.supabase.db
        .from('lista_precios')
        .update(row)
        .eq('id', id)
        .eq('codigo_empresa', codigoEmpresa)
        .select()
        .single();
      if (error) throw new InternalServerErrorException(error.message);
      return this.toEntity(data);
    }

    const { data, error } = await this.supabase.db
      .from('lista_precios')
      .insert({ ...row, codigo_empresa: codigoEmpresa })
      .select()
      .single();
    if (error) throw new InternalServerErrorException(error.message);
    return this.toEntity(data);
  }

  async toggleActivo(codigoEmpresa: string, id: string): Promise<ListaPrecio> {
    const { data: current, error: findErr } = await this.supabase.db
      .from('lista_precios')
      .select('activo')
      .eq('id', id)
      .eq('codigo_empresa', codigoEmpresa)
      .maybeSingle();
    if (findErr) throw new InternalServerErrorException(findErr.message);
    if (!current) throw new NotFoundException('Lista de precio no encontrada');

    const { data, error } = await this.supabase.db
      .from('lista_precios')
      .update({ activo: !current.activo })
      .eq('id', id)
      .eq('codigo_empresa', codigoEmpresa)
      .select()
      .single();
    if (error) throw new InternalServerErrorException(error.message);
    return this.toEntity(data);
  }

  async remove(codigoEmpresa: string, id: string): Promise<void> {
    const { error } = await this.supabase.db
      .from('lista_precios')
      .delete()
      .eq('id', id)
      .eq('codigo_empresa', codigoEmpresa);
    if (error) throw new InternalServerErrorException(error.message);
  }

  private toEntity(r: Record<string, unknown>): ListaPrecio {
    return {
      id:               r.id as string,
      codigoEmpresa:    r.codigo_empresa as string,
      idArticulo:       r.id_articulo as string,
      idTipoLista:      r.id_tipo_lista as string,
      precioVentaBase:  Number(r.precio_venta_base),
      descuentoPct:     Number(r.descuento_pct),
      descuentoMonto:   Number(r.descuento_monto),
      precioVenta:      Number(r.precio_venta),
      activo:           r.activo as boolean,
      createdAt:        r.created_at as string | undefined,
    };
  }
}
