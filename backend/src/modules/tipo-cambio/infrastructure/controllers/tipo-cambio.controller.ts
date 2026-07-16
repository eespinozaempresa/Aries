import {
  Controller,
  Get,
  Post,
  Body,
  Req,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { Request } from 'express';
import { AuthGuard } from '../../../../shared/infrastructure/guards/auth.guard';
import { JwtPayload } from '../../../../shared/infrastructure/jwt/jwt.service';
import { GetTipoCambioHoyUseCase } from '../../application/use-cases/get-tipo-cambio-hoy.use-case';
import { RegistrarTipoCambioUseCase } from '../../application/use-cases/registrar-tipo-cambio.use-case';
import { RegistrarTipoCambioDto } from '../dto/registrar-tipo-cambio.dto';

@Controller('tipo-cambio')
@UseGuards(AuthGuard)
export class TipoCambioController {
  constructor(
    private readonly getHoy: GetTipoCambioHoyUseCase,
    private readonly registrar: RegistrarTipoCambioUseCase,
  ) {}

  @Get('hoy')
  async getHoyHandler(@Req() req: Request) {
    const user = req['user'] as JwtPayload;
    const result = await this.getHoy.execute(user.empresa);
    return { data: result };
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async registrarHandler(
    @Body() dto: RegistrarTipoCambioDto,
    @Req() req: Request,
  ) {
    const user = req['user'] as JwtPayload;
    const result = await this.registrar.execute(
      user.empresa,
      dto.tipoCambio,
      user.codigo,
    );
    return { data: result };
  }
}
