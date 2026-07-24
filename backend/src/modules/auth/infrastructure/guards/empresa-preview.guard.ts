import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Request } from 'express';
import { JwtPayload, JwtTokenService, PreAuthPayload } from '../../../../shared/infrastructure/jwt/jwt.service';
import { IUsuarioRepository } from '../../domain/ports/usuario.repository.port';
import { IBloqueoRepository } from '../../domain/ports/bloqueo.repository.port';

/**
 * Permite consultar datos de una empresa candidata (ej. tipo de cambio del día)
 * antes de que exista un accessToken de sesión para esa empresa: acepta un
 * pre-auth token (login recién validado, empresa aún sin elegir) o un
 * accessToken de sesión completa (flujo "Cambiar Empresa").
 */
@Injectable()
export class EmpresaPreviewGuard implements CanActivate {
  constructor(
    private readonly jwtService: JwtTokenService,
    private readonly usuarioRepo: IUsuarioRepository,
    private readonly bloqueoRepo: IBloqueoRepository,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<Request>();
    const token = this.extractBearerToken(request);
    if (!token) throw new UnauthorizedException('Token no proporcionado');

    const codigoEmpresa = (request.params.codigoEmpresa ?? '').toUpperCase();
    if (!codigoEmpresa) throw new UnauthorizedException('Empresa no especificada');

    let payload: JwtPayload | PreAuthPayload;
    try {
      payload = this.jwtService.verifyAccessToken(token) as JwtPayload | PreAuthPayload;
    } catch {
      throw new UnauthorizedException('Token inválido o expirado');
    }

    if ((payload as PreAuthPayload).purpose === 'SELECT_EMPRESA') {
      const preAuth = payload as PreAuthPayload;
      if (!preAuth.empresas.includes(codigoEmpresa)) {
        throw new UnauthorizedException('No tiene acceso a esa empresa');
      }
      request['user'] = preAuth;
      return true;
    }

    const sessionPayload = payload as JwtPayload;
    const filas = await this.usuarioRepo.findAllByCodigo(sessionPayload.codigo);
    const candidata = filas.find((u) => u.codigoEmpresa.toUpperCase() === codigoEmpresa);
    if (!candidata || !candidata.canLogin()) {
      throw new UnauthorizedException('No tiene acceso a esa empresa');
    }
    const bloqueo = await this.bloqueoRepo.getActivo(candidata.id);
    if (bloqueo) throw new UnauthorizedException('No tiene acceso a esa empresa');

    request['user'] = sessionPayload;
    return true;
  }

  private extractBearerToken(request: Request): string | null {
    const [type, token] = request.headers.authorization?.split(' ') ?? [];
    return type === 'Bearer' ? token : null;
  }
}
