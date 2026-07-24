import { Injectable } from '@nestjs/common';
import { SupabaseService } from '../../../../shared/infrastructure/supabase/supabase.service';
import { IUsuarioRepository } from '../../domain/ports/usuario.repository.port';
import { Usuario } from '../../domain/entities/usuario.entity';

@Injectable()
export class SupabaseUsuarioRepository implements IUsuarioRepository {
  constructor(private readonly supabase: SupabaseService) {}

  async findByCodigoEmpresaAndCodigo(
    codigoEmpresa: string,
    codigo: string,
  ): Promise<Usuario | null> {
    const { data, error } = await this.supabase.db
      .from('usuarios')
      .select('id, codigo_empresa, codigo, nombre, password_hash, nivel, activo, dni, email, perfil_id')
      .ilike('codigo_empresa', codigoEmpresa)
      .ilike('codigo', codigo)
      .single();

    if (error) {
      console.error('[Auth] Supabase error buscando usuario:', error.message, error.code);
      return null;
    }
    if (!data) return null;

    let menus: string[] = [];
    if (data.perfil_id) {
      const { data: perfil } = await this.supabase.db
        .from('perfiles')
        .select('menus')
        .eq('id', data.perfil_id)
        .maybeSingle();
      menus = (perfil?.menus as string[] | null) ?? [];
    }

    return new Usuario(
      data.id,
      data.codigo_empresa,
      data.codigo,
      data.nombre,
      data.password_hash,
      data.nivel,
      data.activo,
      data.dni,
      data.email,
      menus,
    );
  }

  async findAllByCodigo(codigo: string): Promise<Usuario[]> {
    const { data, error } = await this.supabase.db
      .from('usuarios')
      .select('id, codigo_empresa, codigo, nombre, password_hash, nivel, activo, dni, email, perfil_id')
      .ilike('codigo', codigo);

    if (error) {
      console.error('[Auth] Supabase error buscando usuarios por código:', error.message, error.code);
      return [];
    }
    if (!data || data.length === 0) return [];

    const perfilIds = [...new Set(data.map((u) => u.perfil_id).filter(Boolean))];
    const menusPorPerfil = new Map<string, string[]>();
    if (perfilIds.length > 0) {
      const { data: perfiles } = await this.supabase.db
        .from('perfiles')
        .select('id, menus')
        .in('id', perfilIds);
      for (const p of perfiles ?? []) {
        menusPorPerfil.set(p.id as string, (p.menus as string[] | null) ?? []);
      }
    }

    const codigosEmpresa = [...new Set(data.map((u) => u.codigo_empresa))];
    const { data: empresas } = await this.supabase.db
      .from('empresas')
      .select('codigo, nombre')
      .in('codigo', codigosEmpresa);
    const nombresPorEmpresa = new Map<string, string>();
    for (const e of empresas ?? []) {
      nombresPorEmpresa.set(e.codigo as string, e.nombre as string);
    }

    return data.map(
      (u) =>
        new Usuario(
          u.id,
          u.codigo_empresa,
          u.codigo,
          u.nombre,
          u.password_hash,
          u.nivel,
          u.activo,
          u.dni,
          u.email,
          u.perfil_id ? menusPorPerfil.get(u.perfil_id) ?? [] : [],
          nombresPorEmpresa.get(u.codigo_empresa),
        ),
    );
  }
}
