import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { SupabaseService } from '../../../../shared/infrastructure/supabase/supabase.service';
import {
  IAlmacenRepository,
  AlmacenSearchParams,
  SaveAlmacenData,
} from '../../domain/ports/almacen.repository.port';
import { Almacen } from '../../domain/entities/almacen.entity';

@Injectable()
export class SupabaseAlmacenRepository implements IAlmacenRepository {
  constructor(private readonly supabase: SupabaseService) {}

  async findAll(p: AlmacenSearchParams): Promise<Almacen[]> {
    let query = this.supabase.db
      .from('almacenes')
      .select('*')
      .eq('codigo_empresa', p.codigoEmpresa)
      .order('descripcion', { ascending: true });

    if (p.q) query = query.or(`descripcion.ilike.%${p.q}%,codigo.ilike.%${p.q}%`);
    if (p.activo !== undefined) query = query.eq('activo', p.activo);

    const { data, error } = await query;
    if (error) throw new InternalServerErrorException(error.message);
    return (data ?? []).map(this.toEntity);
  }

  async findById(id: string, codigoEmpresa: string): Promise<Almacen | null> {
    const { data, error } = await this.supabase.db
      .from('almacenes')
      .select('*')
      .eq('id', id)
      .eq('codigo_empresa', codigoEmpresa)
      .maybeSingle();
    if (error) throw new InternalServerErrorException(error.message);
    return data ? this.toEntity(data) : null;
  }

  async create(codigoEmpresa: string, d: SaveAlmacenData): Promise<Almacen> {
    const { data, error } = await this.supabase.db
      .from('almacenes')
      .insert({
        codigo_empresa: codigoEmpresa,
        codigo: d.codigo.toUpperCase(),
        descripcion: d.descripcion,
        abreviatura: d.abreviatura,
        ubicacion: d.ubicacion,
        tipo: d.tipo ?? 'ALMACEN',
        activo: d.activo ?? true,
      })
      .select()
      .single();
    if (error) throw new InternalServerErrorException(error.message);
    return this.toEntity(data);
  }

  async update(id: string, codigoEmpresa: string, d: Partial<SaveAlmacenData>): Promise<Almacen> {
    const row: Record<string, unknown> = {};
    if (d.descripcion !== undefined) row.descripcion = d.descripcion;
    if (d.abreviatura !== undefined) row.abreviatura = d.abreviatura;
    if (d.ubicacion !== undefined) row.ubicacion = d.ubicacion;
    if (d.tipo !== undefined) row.tipo = d.tipo;
    if (d.activo !== undefined) row.activo = d.activo;

    const { data, error } = await this.supabase.db
      .from('almacenes')
      .update(row)
      .eq('id', id)
      .eq('codigo_empresa', codigoEmpresa)
      .select()
      .single();
    if (error) throw new InternalServerErrorException(error.message);
    return this.toEntity(data);
  }

  private toEntity(row: Record<string, unknown>): Almacen {
    return {
      id: row.id as string,
      codigoEmpresa: row.codigo_empresa as string,
      codigo: row.codigo as string,
      descripcion: row.descripcion as string,
      abreviatura: row.abreviatura as string | undefined,
      ubicacion: row.ubicacion as string | undefined,
      tipo: (row.tipo as string) ?? 'ALMACEN',
      activo: row.activo as boolean,
    };
  }
}
