import { Injectable, InternalServerErrorException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { SupabaseService } from '../../../../shared/infrastructure/supabase/supabase.service';
import { CreateUsuarioDto, UpdateUsuarioDto, CreatePerfilDto, UpdatePerfilDto } from '../dto/utilitarios.dto';

@Injectable()
export class SupabaseUtilitariosRepository {
  constructor(private readonly supabase: SupabaseService) {}

  async getParametros(codigoEmpresa: string): Promise<{ igv: number; tiempoFinanciamiento: number; almacenPartes: string | null }> {
    const { data, error } = await this.supabase.db
      .from('parametros')
      .select('igv, tiempo_financiamiento, almacen_partes')
      .eq('codigo_empresa', codigoEmpresa)
      .maybeSingle();
    if (error) throw new InternalServerErrorException(error.message);
    return {
      igv: data?.igv ?? 0,
      tiempoFinanciamiento: data?.tiempo_financiamiento ?? 30,
      almacenPartes: data?.almacen_partes ?? null,
    };
  }

  async updateParametros(
    codigoEmpresa: string,
    igv: number,
    tiempoFinanciamiento: number,
    almacenPartes?: string | null,
  ): Promise<{ igv: number; tiempoFinanciamiento: number; almacenPartes: string | null }> {
    const { data, error } = await this.supabase.db
      .from('parametros')
      .upsert(
        {
          codigo_empresa: codigoEmpresa,
          igv,
          tiempo_financiamiento: tiempoFinanciamiento,
          almacen_partes: almacenPartes || null,
        },
        { onConflict: 'codigo_empresa' },
      )
      .select('igv, tiempo_financiamiento, almacen_partes')
      .single();
    if (error) throw new InternalServerErrorException(error.message);
    return {
      igv: data.igv,
      tiempoFinanciamiento: data.tiempo_financiamiento,
      almacenPartes: data.almacen_partes ?? null,
    };
  }

  async listUsuarios(codigoEmpresa: string, requestingNivel = 'OPERADOR'): Promise<unknown[]> {
    const isAdmin = requestingNivel.toUpperCase() === 'ADMIN';
    let query = this.supabase.db
      .from('usuarios')
      .select('id, codigo, nombre, nivel, email, activo, perfil_id, perfiles!perfil_id(id, codigo, descripcion)')
      .eq('codigo_empresa', codigoEmpresa)
      .order('nombre', { ascending: true });
    if (!isAdmin) {
      query = query.not('nivel', 'ilike', 'ADMIN');
    }
    const { data, error } = await query;
    if (error) throw new InternalServerErrorException(error.message);
    return (data ?? []).map((u: any) => ({
      id: u.id,
      codigo: u.codigo,
      nombre: u.nombre,
      nivel: u.nivel,
      email: u.email,
      activo: u.activo,
      perfilId: u.perfil_id ?? null,
      perfilCodigo: u.perfiles?.codigo ?? null,
      perfilDescripcion: u.perfiles?.descripcion ?? null,
    }));
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
        perfil_id: dto.perfilId || null,
        activo: true,
      })
      .select('id, codigo, nombre, nivel, email, activo, perfil_id')
      .single();
    if (error) throw new InternalServerErrorException(error.message);
    return data;
  }

  async getUsuarioNivel(id: string, codigoEmpresa: string): Promise<string | null> {
    const { data } = await this.supabase.db
      .from('usuarios')
      .select('nivel')
      .eq('id', id)
      .eq('codigo_empresa', codigoEmpresa)
      .maybeSingle();
    return (data?.nivel as string | null) ?? null;
  }

  async updateUsuario(id: string, codigoEmpresa: string, dto: UpdateUsuarioDto): Promise<unknown> {
    const updates: Record<string, unknown> = {};
    if (dto.nombre !== undefined) updates['nombre'] = dto.nombre;
    if (dto.nivel !== undefined) updates['nivel'] = dto.nivel;
    if (dto.email !== undefined) updates['email'] = dto.email;
    if (dto.perfilId !== undefined) updates['perfil_id'] = dto.perfilId || null;

    const { data, error } = await this.supabase.db
      .from('usuarios')
      .update(updates)
      .eq('id', id)
      .eq('codigo_empresa', codigoEmpresa)
      .select('id, codigo, nombre, nivel, email, activo, perfil_id')
      .single();
    if (error) throw new InternalServerErrorException(error.message);
    return data;
  }

  async resetPasswordUsuario(id: string, codigoEmpresa: string, nuevaClave: string): Promise<void> {
    const passwordHash = await bcrypt.hash(nuevaClave, 10);
    const { error } = await this.supabase.db
      .from('usuarios')
      .update({ password_hash: passwordHash })
      .eq('id', id)
      .eq('codigo_empresa', codigoEmpresa);
    if (error) throw new InternalServerErrorException(error.message);
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

  async listPerfiles(codigoEmpresa: string): Promise<unknown[]> {
    const { data, error } = await this.supabase.db
      .from('perfiles')
      .select('id, codigo, descripcion, activo, menus')
      .eq('codigo_empresa', codigoEmpresa)
      .order('descripcion', { ascending: true });
    if (error) throw new InternalServerErrorException(error.message);
    return data ?? [];
  }

  async createPerfil(codigoEmpresa: string, dto: CreatePerfilDto): Promise<unknown> {
    const { data, error } = await this.supabase.db
      .from('perfiles')
      .insert({
        codigo_empresa: codigoEmpresa,
        codigo: dto.codigo,
        descripcion: dto.descripcion,
        menus: dto.menus ?? [],
        activo: true,
      })
      .select('id, codigo, descripcion, activo, menus')
      .single();
    if (error) throw new InternalServerErrorException(error.message);
    return data;
  }

  async updatePerfil(id: string, codigoEmpresa: string, dto: UpdatePerfilDto): Promise<unknown> {
    const updates: Record<string, unknown> = {};
    if (dto.descripcion !== undefined) updates['descripcion'] = dto.descripcion;
    if (dto.menus !== undefined) updates['menus'] = dto.menus;
    if (dto.activo !== undefined) updates['activo'] = dto.activo;

    const { data, error } = await this.supabase.db
      .from('perfiles')
      .update(updates)
      .eq('id', id)
      .eq('codigo_empresa', codigoEmpresa)
      .select('id, codigo, descripcion, activo, menus')
      .single();
    if (error) throw new InternalServerErrorException(error.message);
    return data;
  }

  async togglePerfil(id: string, codigoEmpresa: string): Promise<unknown> {
    const { data: current, error: fetchError } = await this.supabase.db
      .from('perfiles')
      .select('activo')
      .eq('id', id)
      .eq('codigo_empresa', codigoEmpresa)
      .single();
    if (fetchError) throw new InternalServerErrorException(fetchError.message);

    const { data, error } = await this.supabase.db
      .from('perfiles')
      .update({ activo: !current.activo })
      .eq('id', id)
      .eq('codigo_empresa', codigoEmpresa)
      .select('id, codigo, descripcion, activo, menus')
      .single();
    if (error) throw new InternalServerErrorException(error.message);
    return data;
  }

  async getAuditoria(codigoEmpresa: string, limit = 50, requestingNivel = 'OPERADOR'): Promise<unknown[]> {
    const isAdmin = requestingNivel.toUpperCase() === 'ADMIN';

    let adminIds: string[] = [];
    if (!isAdmin) {
      const { data: admins } = await this.supabase.db
        .from('usuarios')
        .select('id')
        .eq('codigo_empresa', codigoEmpresa)
        .ilike('nivel', 'ADMIN');
      adminIds = (admins ?? []).map((u: any) => u.id as string);
    }

    const { data, error } = await this.supabase.db
      .from('auditoria_sesiones')
      .select('*')
      .eq('codigo_empresa', codigoEmpresa)
      .order('fecha_hora', { ascending: false })
      .limit(limit);
    if (error) throw new InternalServerErrorException(error.message);

    const results = data ?? [];
    if (!isAdmin && adminIds.length > 0) {
      return results.filter((e: any) => !e.usuario_id || !adminIds.includes(e.usuario_id));
    }
    return results;
  }
}
