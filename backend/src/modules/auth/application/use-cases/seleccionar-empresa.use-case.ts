import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { IUsuarioRepository } from '../../domain/ports/usuario.repository.port';
import { ISessionRepository } from '../../domain/ports/session.repository.port';
import { BloqueoActivo, IBloqueoRepository } from '../../domain/ports/bloqueo.repository.port';
import { JwtTokenService } from '../../../../shared/infrastructure/jwt/jwt.service';

export interface SeleccionarEmpresaCommand {
  codigo: string;
  codigoEmpresa: string;
  ip?: string;
  dispositivo?: string;
}

export interface SeleccionarEmpresaResult {
  accessToken: string;
  refreshToken: string;
  usuario: {
    id: string;
    codigo: string;
    nombre: string;
    nivel: string;
    empresa: string;
    menus: string[];
    multiEmpresa: boolean;
  };
}

/**
 * Emite la sesión completa (accessToken + refreshToken con `empresa` embebida)
 * para una empresa ya elegida. La reusan tanto POST /auth/seleccionar-empresa
 * (recién logueado, clave ya validada en fase 1) como POST /auth/cambiar-empresa
 * (sesión activa, sin volver a pedir clave).
 */
@Injectable()
export class SeleccionarEmpresaUseCase {
  constructor(
    private readonly usuarioRepo: IUsuarioRepository,
    private readonly sessionRepo: ISessionRepository,
    private readonly bloqueoRepo: IBloqueoRepository,
    private readonly jwtService: JwtTokenService,
    private readonly config: ConfigService,
  ) {}

  async execute(cmd: SeleccionarEmpresaCommand): Promise<SeleccionarEmpresaResult> {
    const codigoEmpresa = cmd.codigoEmpresa.toUpperCase();
    const usuario = await this.usuarioRepo.findByCodigoEmpresaAndCodigo(codigoEmpresa, cmd.codigo);

    if (!usuario || !usuario.canLogin()) {
      throw new UnauthorizedException('No tiene acceso a esa empresa');
    }

    const bloqueoActivo = await this.bloqueoRepo.getActivo(usuario.id);
    if (bloqueoActivo) {
      throw new UnauthorizedException(this.mensajeBloqueo(bloqueoActivo));
    }

    const { raw: refreshRaw, hash: refreshHash } = this.jwtService.generateRefreshToken();
    const accessToken = this.jwtService.signAccessToken({
      sub: usuario.id,
      empresa: usuario.codigoEmpresa,
      codigo: usuario.codigo,
      nivel: usuario.nivel,
    });

    const refreshDays = this.config.get<number>('jwt.refreshDays', 7);
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + refreshDays);

    await this.sessionRepo.storeRefreshToken({
      usuarioId: usuario.id,
      tokenHash: refreshHash,
      expiresAt,
    });

    await this.sessionRepo.logAudit({
      codigoEmpresa: usuario.codigoEmpresa,
      usuarioId: usuario.id,
      usuarioCodigo: usuario.codigo,
      tipo: 'LOGIN',
      ip: cmd.ip,
      dispositivo: cmd.dispositivo,
    });

    const menus = usuario.nivel?.toUpperCase() === 'ADMIN' ? ['*'] : (usuario.menus ?? []);
    const multiEmpresa = await this.tieneMultiplesEmpresas(cmd.codigo);

    return {
      accessToken,
      refreshToken: refreshRaw,
      usuario: {
        id: usuario.id,
        codigo: usuario.codigo,
        nombre: usuario.nombre,
        nivel: usuario.nivel,
        empresa: usuario.codigoEmpresa,
        menus,
        multiEmpresa,
      },
    };
  }

  private async tieneMultiplesEmpresas(codigo: string): Promise<boolean> {
    const filas = await this.usuarioRepo.findAllByCodigo(codigo);
    let disponibles = 0;
    for (const fila of filas) {
      if (!fila.canLogin()) continue;
      const bloqueoActivo = await this.bloqueoRepo.getActivo(fila.id);
      if (bloqueoActivo) continue;
      disponibles += 1;
      if (disponibles > 1) return true;
    }
    return false;
  }

  private mensajeBloqueo(bloqueo: BloqueoActivo): string {
    if (bloqueo.tipo === 'INDEFINIDO') {
      return 'Usuario bloqueado. Contacte al administrador para desbloquearlo.';
    }
    const minutosRestantes = Math.max(1, Math.ceil((bloqueo.fechaFin!.getTime() - Date.now()) / 60_000));
    return `Usuario bloqueado temporalmente. Intente nuevamente en ${minutosRestantes} minuto(s).`;
  }
}
