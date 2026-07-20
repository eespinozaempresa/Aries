import { Injectable } from '@nestjs/common';
import { ISessionRepository } from '../../domain/ports/session.repository.port';
import { JwtTokenService } from '../../../../shared/infrastructure/jwt/jwt.service';

export interface LogoutCommand {
  refreshToken: string;
  codigoEmpresa: string;
  usuarioId: string;
  usuarioCodigo?: string;
  ip?: string;
  dispositivo?: string;
}

@Injectable()
export class LogoutUseCase {
  constructor(
    private readonly sessionRepo: ISessionRepository,
    private readonly jwtService: JwtTokenService,
  ) {}

  async execute(cmd: LogoutCommand): Promise<void> {
    const hash = this.jwtService.hashToken(cmd.refreshToken);
    await this.sessionRepo.revokeRefreshToken(hash);
    await this.sessionRepo.logAudit({
      codigoEmpresa: cmd.codigoEmpresa,
      usuarioId: cmd.usuarioId,
      usuarioCodigo: cmd.usuarioCodigo,
      tipo: 'LOGOUT',
      ip: cmd.ip,
      dispositivo: cmd.dispositivo,
    });
  }
}
