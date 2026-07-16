import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { SupabaseService } from '../../../../shared/infrastructure/supabase/supabase.service';
import { ITipoCambioRepository, CreateTipoCambioData } from '../../domain/ports/tipo-cambio.repository.port';
import { TipoCambio } from '../../domain/entities/tipo-cambio.entity';

@Injectable()
export class SupabaseTipoCambioRepository implements ITipoCambioRepository {
  constructor(private readonly supabase: SupabaseService) {}

  async findByFecha(codigoEmpresa: string, fecha: string): Promise<TipoCambio | null> {
    const { data, error } = await this.supabase.db
      .from('tipo_cambio')
      .select('*')
      .eq('codigo_empresa', codigoEmpresa)
      .eq('fecha', fecha)
      .maybeSingle();

    if (error) throw new InternalServerErrorException(error.message);
    if (!data) return null;
    return this.toEntity(data);
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
      .select()
      .single();

    if (error) throw new InternalServerErrorException(error.message);
    return this.toEntity(data);
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
