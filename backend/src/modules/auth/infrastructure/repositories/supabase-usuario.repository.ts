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
      .select('id, codigo_empresa, codigo, nombre, password_hash, nivel, activo, dni, email')
      .eq('codigo_empresa', codigoEmpresa)
      .eq('codigo', codigo)
      .single();

    if (error) {
      console.error('[Auth] Supabase error buscando usuario:', error.message, error.code);
      return null;
    }
    if (!data) return null;

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
    );
  }
}
