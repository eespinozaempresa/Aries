import { BadRequestException, Injectable, UnauthorizedException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { IUsuarioRepository } from '../../domain/ports/usuario.repository.port';
import { ISessionRepository } from '../../domain/ports/session.repository.port';
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
  };
}

@Injectable()
export class LoginUseCase {
  constructor(
    private readonly usuarioRepo: IUsuarioRepository,
    private readonly sessionRepo: ISessionRepository,
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
      throw new UnauthorizedException('Usuario o contraseña incorrectos');
    }

    const passwordValid = await bcrypt.compare(cmd.clave, usuario.passwordHash);
    if (!passwordValid) {
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
      tipo: 'LOGIN',
      ip: cmd.ip,
      dispositivo: cmd.dispositivo,
    });

    return {
      accessToken,
      refreshToken: refreshRaw,
      usuario: {
        id: usuario.id,
        codigo: usuario.codigo,
        nombre: usuario.nombre,
        nivel: usuario.nivel,
        empresa: usuario.codigoEmpresa,
      },
    };
  }
}
