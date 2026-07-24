import {
  Body,
  Controller,
  Get,
  HttpCode,
  Post,
  Req,
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import { Request } from 'express';
import * as bcrypt from 'bcrypt';
import { LoginUseCase } from '../../application/use-cases/login.use-case';
import { LogoutUseCase } from '../../application/use-cases/logout.use-case';
import { RefreshTokenUseCase } from '../../application/use-cases/refresh-token.use-case';
import { SeleccionarEmpresaUseCase } from '../../application/use-cases/seleccionar-empresa.use-case';
import { LoginDto } from '../dto/login.dto';
import { RefreshTokenDto } from '../dto/refresh-token.dto';
import { SeleccionarEmpresaDto } from '../dto/seleccionar-empresa.dto';
import { AuthGuard } from '../../../../shared/infrastructure/guards/auth.guard';
import { PreAuthGuard } from '../../../../shared/infrastructure/guards/pre-auth.guard';
import { JwtPayload, PreAuthPayload } from '../../../../shared/infrastructure/jwt/jwt.service';
import { SupabaseService } from '../../../../shared/infrastructure/supabase/supabase.service';
import { IUsuarioRepository } from '../../domain/ports/usuario.repository.port';
import { IBloqueoRepository } from '../../domain/ports/bloqueo.repository.port';

export class CambiarClaveDto {
  claveActual: string;
  claveNueva: string;
}

@Controller('auth')
export class AuthController {
  constructor(
    private readonly loginUseCase: LoginUseCase,
    private readonly logoutUseCase: LogoutUseCase,
    private readonly refreshUseCase: RefreshTokenUseCase,
    private readonly seleccionarEmpresaUseCase: SeleccionarEmpresaUseCase,
    private readonly usuarioRepo: IUsuarioRepository,
    private readonly bloqueoRepo: IBloqueoRepository,
    private readonly supabase: SupabaseService,
  ) {}

  @Get('empresas')
  async empresas() {
    const { data, error } = await this.supabase.db
      .from('empresas')
      .select('codigo, nombre')
      .eq('activo', true)
      .order('nombre');
    if (error) return [];
    return data;
  }

  @Post('login')
  @HttpCode(200)
  async login(@Body() dto: LoginDto, @Req() req: Request) {
    return this.loginUseCase.execute({
      ...dto,
      ip: req.ip,
      dispositivo: req.headers['user-agent'],
    });
  }

  @Post('seleccionar-empresa')
  @HttpCode(200)
  @UseGuards(PreAuthGuard)
  async seleccionarEmpresa(@Body() dto: SeleccionarEmpresaDto, @Req() req: Request) {
    const preAuth = req['user'] as PreAuthPayload;
    return this.seleccionarEmpresaUseCase.execute({
      codigo: preAuth.codigo,
      codigoEmpresa: dto.codigoEmpresa,
      ip: req.ip,
      dispositivo: req.headers['user-agent'],
    });
  }

  @Post('cambiar-empresa')
  @HttpCode(200)
  @UseGuards(AuthGuard)
  async cambiarEmpresa(@Body() dto: SeleccionarEmpresaDto, @Req() req: Request) {
    const user = req['user'] as JwtPayload;
    return this.seleccionarEmpresaUseCase.execute({
      codigo: user.codigo,
      codigoEmpresa: dto.codigoEmpresa,
      ip: req.ip,
      dispositivo: req.headers['user-agent'],
    });
  }

  @Get('mis-empresas')
  @UseGuards(AuthGuard)
  async misEmpresas(@Req() req: Request) {
    const user = req['user'] as JwtPayload;
    const filas = await this.usuarioRepo.findAllByCodigo(user.codigo);

    const disponibles = [];
    for (const fila of filas) {
      if (!fila.canLogin()) continue;
      const bloqueoActivo = await this.bloqueoRepo.getActivo(fila.id);
      if (bloqueoActivo) continue;
      disponibles.push({ codigo: fila.codigoEmpresa, nombre: fila.nombreEmpresa ?? fila.codigoEmpresa });
    }
    return disponibles;
  }

  @Post('refresh')
  @HttpCode(200)
  async refresh(@Body() dto: RefreshTokenDto) {
    return this.refreshUseCase.execute(dto.refreshToken);
  }

  @Post('logout')
  @HttpCode(204)
  @UseGuards(AuthGuard)
  async logout(@Body() dto: RefreshTokenDto, @Req() req: Request) {
    const user = req['user'] as JwtPayload;
    await this.logoutUseCase.execute({
      refreshToken: dto.refreshToken,
      codigoEmpresa: user.empresa,
      usuarioId: user.sub,
      usuarioCodigo: user.codigo,
      ip: req.ip,
      dispositivo: req.headers['user-agent'],
    });
  }

  @Get('me')
  @UseGuards(AuthGuard)
  me(@Req() req: Request) {
    return req['user'];
  }

  @Post('cambiar-clave')
  @HttpCode(200)
  @UseGuards(AuthGuard)
  async cambiarClave(@Body() dto: CambiarClaveDto, @Req() req: Request) {
    const user = req['user'] as JwtPayload;

    const { data, error } = await this.supabase.db
      .from('usuarios')
      .select('password_hash')
      .eq('id', user.sub)
      .single();

    if (error || !data) throw new UnauthorizedException('Usuario no encontrado');

    const match = await bcrypt.compare(dto.claveActual, data.password_hash as string);
    if (!match) throw new UnauthorizedException('Contraseña actual incorrecta');

    const newHash = await bcrypt.hash(dto.claveNueva, 10);

    const { error: updateError } = await this.supabase.db
      .from('usuarios')
      .update({ password_hash: newHash })
      .eq('id', user.sub);

    if (updateError) throw new UnauthorizedException(updateError.message);

    return { message: 'Contraseña actualizada correctamente' };
  }
}
