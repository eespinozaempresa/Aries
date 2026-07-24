import { Injectable } from '@nestjs/common';
import { SupabaseService } from '../../../../shared/infrastructure/supabase/supabase.service';
import {
  ISessionRepository,
  LogAuditParams,
  StoreRefreshTokenParams,
} from '../../domain/ports/session.repository.port';

@Injectable()
export class SupabaseSessionRepository implements ISessionRepository {
  constructor(private readonly supabase: SupabaseService) {}

  async storeRefreshToken(params: StoreRefreshTokenParams): Promise<void> {
    await this.supabase.db.from('refresh_tokens').insert({
      usuario_id: params.usuarioId,
      token_hash: params.tokenHash,
      expires_at: params.expiresAt.toISOString(),
    });
  }

  async findValidRefreshToken(
    tokenHash: string,
  ): Promise<{ usuarioId: string; expiresAt: Date } | null> {
    const { data } = await this.supabase.db
      .from('refresh_tokens')
      .select('usuario_id, expires_at')
      .eq('token_hash', tokenHash)
      .eq('revocado', false)
      .single();

    if (!data) return null;
    return { usuarioId: data.usuario_id, expiresAt: new Date(data.expires_at) };
  }

  async revokeRefreshToken(tokenHash: string): Promise<void> {
    await this.supabase.db
      .from('refresh_tokens')
      .update({ revocado: true })
      .eq('token_hash', tokenHash);
  }

  async revokeAllUserTokens(usuarioId: string): Promise<void> {
    await this.supabase.db
      .from('refresh_tokens')
      .update({ revocado: true })
      .eq('usuario_id', usuarioId);
  }

  async logAudit(params: LogAuditParams): Promise<void> {
    const { error } = await this.supabase.db.from('auditoria_sesiones').insert({
      codigo_empresa: params.codigoEmpresa,
      usuario_id: params.usuarioId ?? null,
      usuario_codigo: params.usuarioCodigo ?? null,
      tipo: params.tipo,
      ip: params.ip ?? null,
      dispositivo: params.dispositivo ? params.dispositivo.substring(0, 200) : null,
    });
    if (error) {
      console.error('[Audit] Error al insertar registro de auditoría:', error.message, '| code:', error.code);
    }
  }

  async countLoginFailSince(usuarioId: string, desde: Date): Promise<number> {
    const { count } = await this.supabase.db
      .from('auditoria_sesiones')
      .select('id', { count: 'exact', head: true })
      .eq('usuario_id', usuarioId)
      .eq('tipo', 'LOGIN_FAIL')
      .gte('fecha_hora', desde.toISOString());
    return count ?? 0;
  }
}
