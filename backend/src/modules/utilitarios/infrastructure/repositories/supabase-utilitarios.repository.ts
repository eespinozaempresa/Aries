import { Injectable, InternalServerErrorException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { SupabaseService } from '../../../../shared/infrastructure/supabase/supabase.service';
import { CreateUsuarioDto, UpdateUsuarioDto } from '../dto/utilitarios.dto';

@Injectable()
export class SupabaseUtilitariosRepository {
  constructor(private readonly supabase: SupabaseService) {}

  async getParametros(codigoEmpresa: string): Promise<{ igv: number; tiempoFinanciamiento: number }> {
    const { data, error } = await this.supabase.db
      .from('parametros')
      .select('igv, tiempo_financiamiento')
      .eq('codigo_empresa', codigoEmpresa)
      .maybeSingle();
    if (error) throw new InternalServerErrorException(error.message);
    return {
      igv: data?.igv ?? 0,
      tiempoFinanciamiento: data?.tiempo_financiamiento ?? 30,
    };
  }

  async updateParametros(
    codigoEmpresa: string,
    igv: number,
    tiempoFinanciamiento: number,
  ): Promise<{ igv: number; tiempoFinanciamiento: number }> {
    const { data, error } = await this.supabase.db
      .from('parametros')
      .upsert(
        { codigo_empresa: codigoEmpresa, igv, tiempo_financiamiento: tiempoFinanciamiento },
        { onConflict: 'codigo_empresa' },
      )
      .select('igv, tiempo_financiamiento')
      .single();
    if (error) throw new InternalServerErrorException(error.message);
    return {
      igv: data.igv,
      tiempoFinanciamiento: data.tiempo_financiamiento,
    };
  }

  async listUsuarios(codigoEmpresa: string): Promise<unknown[]> {
    const { data, error } = await this.supabase.db
      .from('usuarios')
      .select('id, codigo, nombre, nivel, email, activo')
      .eq('codigo_empresa', codigoEmpresa)
      .order('nombre', { ascending: true });
    if (error) throw new InternalServerErrorException(error.message);
    return data ?? [];
  }

  async createUsuario(codigoEmpresa: string, dto: CreateUsuarioDto): Promise<unknown> {
    const passwordHash = await bcrypt.hash(dto.clave, 10);
    const { data, error } = await this.supabase.db
      .from('usuarios')
      .insert({
        codigo_empresa: codigoEmpresa,
        codigo: dto.codigo,
        nombre: dto.nombre,
        password_hash: passwordHash,
        nivel: dto.nivel,
        email: dto.email ?? null,
        activo: true,
      })
      .select('id, codigo, nombre, nivel, email, activo')
      .single();
    if (error) throw new InternalServerErrorException(error.message);
    return data;
  }

  async updateUsuario(id: string, codigoEmpresa: string, dto: UpdateUsuarioDto): Promise<unknown> {
    const updates: Record<string, unknown> = {};
    if (dto.nombre !== undefined) updates['nombre'] = dto.nombre;
    if (dto.nivel !== undefined) updates['nivel'] = dto.nivel;
    if (dto.email !== undefined) updates['email'] = dto.email;

    const { data, error } = await this.supabase.db
      .from('usuarios')
      .update(updates)
      .eq('id', id)
      .eq('codigo_empresa', codigoEmpresa)
      .select('id, codigo, nombre, nivel, email, activo')
      .single();
    if (error) throw new InternalServerErrorException(error.message);
    return data;
  }

  async toggleUsuario(id: string, codigoEmpresa: string): Promise<unknown> {
    const { data: current, error: fetchError } = await this.supabase.db
      .from('usuarios')
      .select('activo')
      .eq('id', id)
      .eq('codigo_empresa', codigoEmpresa)
      .single();
    if (fetchError) throw new InternalServerErrorException(fetchError.message);

    const { data, error } = await this.supabase.db
      .from('usuarios')
      .update({ activo: !current.activo })
      .eq('id', id)
      .eq('codigo_empresa', codigoEmpresa)
      .select('id, codigo, nombre, nivel, email, activo')
      .single();
    if (error) throw new InternalServerErrorException(error.message);
    return data;
  }

  async getAuditoria(codigoEmpresa: string, limit = 50): Promise<unknown[]> {
    const { data, error } = await this.supabase.db
      .from('auditoria_sesiones')
      .select('*')
      .eq('codigo_empresa', codigoEmpresa)
      .order('fecha_hora', { ascending: false })
      .limit(limit);
    if (error) throw new InternalServerErrorException(error.message);
    return data ?? [];
  }
}
