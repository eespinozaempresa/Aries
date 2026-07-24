import { BadRequestException, Injectable, UnauthorizedException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { IUsuarioRepository } from '../../domain/ports/usuario.repository.port';
import { ISessionRepository } from '../../domain/ports/session.repository.port';
import { BloqueoActivo, IBloqueoRepository } from '../../domain/ports/bloqueo.repository.port';
import { ITiemposConfigRepository } from '../../domain/ports/tiempos-config.repository.port';
import { JwtTokenService } from '../../../../shared/infrastructure/jwt/jwt.service';
import { ConfigService } from '@nestjs/config';

export interface LoginCommand {
  empresa: string;
  usuario: string;
  clave: string;
  captchaA: number;
  captchaB: number;
  captchaAnswer: number;
  ip?: string;
  dispositivo?: string;
}

export interface LoginResult {
  accessToken: string;
  refreshToken: string;
  usuario: {
    id: string;
    codigo: string;
    nombre: string;
    nivel: string;
    empresa: string;
    menus: string[];
  };
}

@Injectable()
export class LoginUseCase {
  constructor(
    private readonly usuarioRepo: IUsuarioRepository,
    private readonly sessionRepo: ISessionRepository,
    private readonly bloqueoRepo: IBloqueoRepository,
    private readonly tiemposConfigRepo: ITiemposConfigRepository,
    private readonly jwtService: JwtTokenService,
    private readonly config: ConfigService,
  ) {}

  async execute(cmd: LoginCommand): Promise<LoginResult> {
    if (cmd.captchaA + cmd.captchaB !== cmd.captchaAnswer) {
      throw new BadRequestException('Captcha incorrecto');
    }

    const usuario = await this.usuarioRepo.findByCodigoEmpresaAndCodigo(
      cmd.empresa.toUpperCase(),
      cmd.usuario.toUpperCase(),
    );

    if (!usuario || !usuario.canLogin()) {
      await this.sessionRepo.logAudit({
        codigoEmpresa: cmd.empresa.toUpperCase(),
        usuarioId: usuario?.id,
        usuarioCodigo: cmd.usuario.toUpperCase(),
        tipo: 'LOGIN_FAIL',
        ip: cmd.ip,
        dispositivo: cmd.dispositivo,
      }).catch(() => {});
      throw new UnauthorizedException('Usuario o contraseña incorrectos');
    }

    const bloqueoActivo = await this.bloqueoRepo.getActivo(usuario.id);
    if (bloqueoActivo) {
      throw new UnauthorizedException(this.mensajeBloqueo(bloqueoActivo));
    }

    const passwordValid = await bcrypt.compare(cmd.clave, usuario.passwordHash);
    if (!passwordValid) {
      await this.sessionRepo.logAudit({
        codigoEmpresa: cmd.empresa.toUpperCase(),
        usuarioId: usuario.id,
        usuarioCodigo: usuario.codigo,
        tipo: 'LOGIN_FAIL',
        ip: cmd.ip,
        dispositivo: cmd.dispositivo,
      }).catch(() => {});
      await this.evaluarBloqueoPorIntentos(usuario.id);
      throw new UnauthorizedException('Usuario o contraseña incorrectos');
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
      },
    };
  }

  private async evaluarBloqueoPorIntentos(usuarioId: string): Promise<void> {
    const config = await this.tiemposConfigRepo.getConfig();

    const desdeIntentos = new Date(Date.now() - config.ventanaIntentosMinutos * 60_000);
    const intentosFallidos = await this.sessionRepo.countLoginFailSince(usuarioId, desdeIntentos);
    if (intentosFallidos < config.maxIntentosFallidos) return;

    const fechaFinTemporal = new Date(Date.now() + config.bloqueoTemporalMinutos * 60_000);
    await this.bloqueoRepo.crear(
      usuarioId,
      'TEMPORAL',
      fechaFinTemporal,
      `Bloqueo automático tras ${config.maxIntentosFallidos} intentos fallidos en ${config.ventanaIntentosMinutos} minutos`,
    );

    const desdeBloqueos = new Date(Date.now() - config.ventanaBloqueosMinutos * 60_000);
    const bloqueosRecientes = await this.bloqueoRepo.contarTemporalesDesde(usuarioId, desdeBloqueos);
    if (bloqueosRecientes >= config.maxBloqueosTemporales) {
      await this.bloqueoRepo.crear(
        usuarioId,
        'INDEFINIDO',
        null,
        `Bloqueo indefinido tras ${config.maxBloqueosTemporales} bloqueos temporales en ${config.ventanaBloqueosMinutos} minutos`,
      );
    }
  }

  private mensajeBloqueo(bloqueo: BloqueoActivo): string {
    if (bloqueo.tipo === 'INDEFINIDO') {
      return 'Usuario bloqueado. Contacte al administrador para desbloquearlo.';
    }
    const minutosRestantes = Math.max(1, Math.ceil((bloqueo.fechaFin!.getTime() - Date.now()) / 60_000));
    return `Usuario bloqueado temporalmente. Intente nuevamente en ${minutosRestantes} minuto(s).`;
  }
}
