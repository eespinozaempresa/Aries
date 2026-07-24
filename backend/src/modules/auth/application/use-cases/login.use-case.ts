import { BadRequestException, Injectable, UnauthorizedException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { IUsuarioRepository } from '../../domain/ports/usuario.repository.port';
import { ISessionRepository } from '../../domain/ports/session.repository.port';
import { IBloqueoRepository } from '../../domain/ports/bloqueo.repository.port';
import { ITiemposConfigRepository } from '../../domain/ports/tiempos-config.repository.port';
import { Usuario } from '../../domain/entities/usuario.entity';
import { JwtTokenService } from '../../../../shared/infrastructure/jwt/jwt.service';

export interface LoginCommand {
  usuario: string;
  clave: string;
  captchaA: number;
  captchaB: number;
  captchaAnswer: number;
  ip?: string;
  dispositivo?: string;
}

export interface EmpresaCandidata {
  codigo: string;
  nombre: string;
}

export interface LoginResult {
  preAuthToken: string;
  usuario: { codigo: string; nombre: string };
  empresas: EmpresaCandidata[];
}

@Injectable()
export class LoginUseCase {
  constructor(
    private readonly usuarioRepo: IUsuarioRepository,
    private readonly sessionRepo: ISessionRepository,
    private readonly bloqueoRepo: IBloqueoRepository,
    private readonly tiemposConfigRepo: ITiemposConfigRepository,
    private readonly jwtService: JwtTokenService,
  ) {}

  async execute(cmd: LoginCommand): Promise<LoginResult> {
    if (cmd.captchaA + cmd.captchaB !== cmd.captchaAnswer) {
      throw new BadRequestException('Captcha incorrecto');
    }

    const codigo = cmd.usuario.toUpperCase();
    const filas = await this.usuarioRepo.findAllByCodigo(codigo);

    if (filas.length === 0) {
      await this.sessionRepo.logAudit({
        codigoEmpresa: 'N/A',
        usuarioCodigo: codigo,
        tipo: 'LOGIN_FAIL',
        ip: cmd.ip,
        dispositivo: cmd.dispositivo,
      }).catch(() => {});
      throw new UnauthorizedException('Usuario o contraseña incorrectos');
    }

    const coincidencias: Usuario[] = [];
    for (const fila of filas) {
      const passwordValida = await bcrypt.compare(cmd.clave, fila.passwordHash);
      if (passwordValida) {
        coincidencias.push(fila);
        continue;
      }
      await this.sessionRepo.logAudit({
        codigoEmpresa: fila.codigoEmpresa,
        usuarioId: fila.id,
        usuarioCodigo: fila.codigo,
        tipo: 'LOGIN_FAIL',
        ip: cmd.ip,
        dispositivo: cmd.dispositivo,
      }).catch(() => {});
      await this.evaluarBloqueoPorIntentos(fila.id);
    }

    if (coincidencias.length === 0) {
      throw new UnauthorizedException('Usuario o contraseña incorrectos');
    }

    const disponibles: Usuario[] = [];
    for (const fila of coincidencias) {
      if (!fila.canLogin()) continue;
      const bloqueoActivo = await this.bloqueoRepo.getActivo(fila.id);
      if (bloqueoActivo) continue;
      disponibles.push(fila);
    }

    if (disponibles.length === 0) {
      throw new UnauthorizedException(
        'Usuario inactivo o bloqueado en todas sus empresas. Contacte al administrador.',
      );
    }

    const preAuthToken = this.jwtService.signPreAuthToken({
      purpose: 'SELECT_EMPRESA',
      codigo,
      empresas: disponibles.map((u) => u.codigoEmpresa),
    });

    return {
      preAuthToken,
      usuario: { codigo, nombre: disponibles[0].nombre },
      empresas: disponibles.map((u) => ({
        codigo: u.codigoEmpresa,
        nombre: u.nombreEmpresa ?? u.codigoEmpresa,
      })),
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
}
