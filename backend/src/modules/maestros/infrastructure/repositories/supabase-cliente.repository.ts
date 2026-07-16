import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { SupabaseService } from '../../../../shared/infrastructure/supabase/supabase.service';
import {
  IClienteRepository,
  ClienteSearchParams,
  ClienteListResult,
  SaveClienteData,
} from '../../domain/ports/cliente.repository.port';
import { Cliente } from '../../domain/entities/cliente.entity';

@Injectable()
export class SupabaseClienteRepository implements IClienteRepository {
  constructor(private readonly supabase: SupabaseService) {}

  async search(p: ClienteSearchParams): Promise<ClienteListResult> {
    const page = p.page ?? 1;
    const limit = Math.min(p.limit ?? 20, 100);
    const from = (page - 1) * limit;

    let query = this.supabase.db
      .from('clientes')
      .select('*', { count: 'exact' })
      .eq('codigo_empresa', p.codigoEmpresa)
      .order('razon_social', { ascending: true })
      .range(from, from + limit - 1);

    if (p.q) {
      query = query.or(`razon_social.ilike.%${p.q}%,codigo.ilike.%${p.q}%,ruc_dni.ilike.%${p.q}%`);
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

  async findById(id: string, codigoEmpresa: string): Promise<Cliente | null> {
    const { data, error } = await this.supabase.db
      .from('clientes')
      .select('*')
      .eq('id', id)
      .eq('codigo_empresa', codigoEmpresa)
      .maybeSingle();
    if (error) throw new InternalServerErrorException(error.message);
    return data ? this.toEntity(data) : null;
  }

  async create(codigoEmpresa: string, d: SaveClienteData): Promise<Cliente> {
    const { data, error } = await this.supabase.db
      .from('clientes')
      .insert({
        codigo_empresa: codigoEmpresa,
        codigo: d.codigo.toUpperCase(),
        razon_social: d.razonSocial,
        direccion: d.direccion,
        ruc_dni: d.rucDni,
        telefono: d.telefono,
        celular: d.celular,
        email: d.email,
        activo: d.activo ?? true,
      })
      .select()
      .single();
    if (error) throw new InternalServerErrorException(error.message);
    return this.toEntity(data);
  }

  async update(id: string, codigoEmpresa: string, d: Partial<SaveClienteData>): Promise<Cliente> {
    const row: Record<string, unknown> = {};
    if (d.razonSocial !== undefined) row.razon_social = d.razonSocial;
    if (d.direccion !== undefined) row.direccion = d.direccion;
    if (d.rucDni !== undefined) row.ruc_dni = d.rucDni;
    if (d.telefono !== undefined) row.telefono = d.telefono;
    if (d.celular !== undefined) row.celular = d.celular;
    if (d.email !== undefined) row.email = d.email;
    if (d.activo !== undefined) row.activo = d.activo;

    const { data, error } = await this.supabase.db
      .from('clientes')
      .update(row)
      .eq('id', id)
      .eq('codigo_empresa', codigoEmpresa)
      .select()
      .single();
    if (error) throw new InternalServerErrorException(error.message);
    return this.toEntity(data);
  }

  private toEntity(row: Record<string, unknown>): Cliente {
    return {
      id: row.id as string,
      codigoEmpresa: row.codigo_empresa as string,
      codigo: row.codigo as string,
      razonSocial: row.razon_social as string,
      direccion: row.direccion as string | undefined,
      rucDni: row.ruc_dni as string | undefined,
      telefono: row.telefono as string | undefined,
      celular: row.celular as string | undefined,
      email: row.email as string | undefined,
      activo: row.activo as boolean,
      createdAt: row.created_at as string | undefined,
      updatedAt: row.updated_at as string | undefined,
    };
  }
}
