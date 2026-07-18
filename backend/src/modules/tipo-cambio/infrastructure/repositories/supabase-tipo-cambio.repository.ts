import { Injectable, InternalServerErrorException, NotFoundException } from '@nestjs/common';
import { SupabaseService } from '../../../../shared/infrastructure/supabase/supabase.service';
import { ITipoCambioRepository, CreateTipoCambioData, TipoCambioListResult } from '../../domain/ports/tipo-cambio.repository.port';
import { TipoCambio } from '../../domain/entities/tipo-cambio.entity';

@Injectable()
export class SupabaseTipoCambioRepository implements ITipoCambioRepository {
  constructor(private readonly supabase: SupabaseService) {}

  async findByFecha(codigoEmpresa: string, fecha: string): Promise<TipoCambio | null> {
    const { data, error } = await this.supabase.db
      .from('tipo_cambio').select('*')
      .eq('codigo_empresa', codigoEmpresa).eq('fecha', fecha).maybeSingle();
    if (error) throw new InternalServerErrorException(error.message);
    return data ? this.toEntity(data) : null;
  }

  async findById(codigoEmpresa: string, id: string): Promise<TipoCambio | null> {
    const { data, error } = await this.supabase.db
      .from('tipo_cambio').select('*')
      .eq('codigo_empresa', codigoEmpresa).eq('id', id).maybeSingle();
    if (error) throw new InternalServerErrorException(error.message);
    return data ? this.toEntity(data) : null;
  }

  async create(input: CreateTipoCambioData): Promise<TipoCambio> {
    const { data, error } = await this.supabase.db
      .from('tipo_cambio')
      .insert({
        codigo_empresa: input.codigoEmpresa,
        fecha: input.fecha,
        tipo_cambio: input.tipoCambio,
        codigo_usuario: input.usuarioRegistro,
      })
      .select().single();
    if (error) throw new InternalServerErrorException(error.message);
    return this.toEntity(data);
  }

  async list(codigoEmpresa: string, page: number, limit: number): Promise<TipoCambioListResult> {
    const from = (page - 1) * limit;
    const { data, error, count } = await this.supabase.db
      .from('tipo_cambio').select('*', { count: 'exact' })
      .eq('codigo_empresa', codigoEmpresa)
      .order('fecha', { ascending: false })
      .range(from, from + limit - 1);
    if (error) throw new InternalServerErrorException(error.message);
    const total = count ?? 0;
    return {
      data: (data ?? []).map(this.toEntity),
      total,
      page,
      lastPage: Math.ceil(total / limit) || 1,
    };
  }

  async update(codigoEmpresa: string, id: string, tipoCambio: number): Promise<TipoCambio> {
    const { data, error } = await this.supabase.db
      .from('tipo_cambio')
      .update({ tipo_cambio: tipoCambio })
      .eq('codigo_empresa', codigoEmpresa).eq('id', id)
      .select().single();
    if (error) throw new InternalServerErrorException(error.message);
    if (!data) throw new NotFoundException('Tipo de cambio no encontrado');
    return this.toEntity(data);
  }

  async delete(codigoEmpresa: string, id: string): Promise<void> {
    const { error } = await this.supabase.db
      .from('tipo_cambio')
      .delete()
      .eq('codigo_empresa', codigoEmpresa).eq('id', id);
    if (error) throw new InternalServerErrorException(error.message);
  }

  private toEntity(row: Record<string, unknown>): TipoCambio {
    return {
      id: row.id as string,
      codigoEmpresa: row.codigo_empresa as string,
      fecha: row.fecha as string,
      tipoCambio: Number(row.tipo_cambio),
      usuarioRegistro: row.codigo_usuario as string | undefined,
      createdAt: row.created_at as string | undefined,
    };
  }
}
