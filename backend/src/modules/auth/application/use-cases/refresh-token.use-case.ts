import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ISessionRepository } from '../../domain/ports/session.repository.port';
import { JwtTokenService } from '../../../../shared/infrastructure/jwt/jwt.service';
import { SupabaseService } from '../../../../shared/infrastructure/supabase/supabase.service';
import { ConfigService } from '@nestjs/config';

export interface RefreshTokenResult {
  accessToken: string;
  refreshToken: string;
}

@Injectable()
export class RefreshTokenUseCase {
  constructor(
    private readonly sessionRepo: ISessionRepository,
    private readonly jwtService: JwtTokenService,
    private readonly supabase: SupabaseService,
    private readonly config: ConfigService,
  ) {}

  async execute(rawRefreshToken: string): Promise<RefreshTokenResult> {
    const hash = this.jwtService.hashToken(rawRefreshToken);
    const stored = await this.sessionRepo.findValidRefreshToken(hash);

    if (!stored || stored.expiresAt < new Date()) {
      throw new UnauthorizedException('Refresh token inválido o expirado');
    }

    await this.sessionRepo.revokeRefreshToken(hash);

    const { raw: newRaw, hash: newHash } = this.jwtService.generateRefreshToken();
    const refreshDays = this.config.get<number>('jwt.refreshDays', 7);
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + refreshDays);

    await this.sessionRepo.storeRefreshToken({
      usuarioId: stored.usuarioId,
      tokenHash: newHash,
      expiresAt,
    });

    const { data } = await this.supabase.db
      .from('usuarios')
      .select('id, codigo, codigo_empresa, nivel')
      .eq('id', stored.usuarioId)
      .single();

    if (!data) throw new UnauthorizedException('Usuario no encontrado');

    const accessToken = this.jwtService.signAccessToken({
      sub: data.id,
      empresa: data.codigo_empresa,
      codigo: data.codigo,
      nivel: data.nivel,
    });

    return { accessToken, refreshToken: newRaw };
  }
}
