import {
  Controller, Get, Post, Patch, Delete,
  Body, Param, Query, Req, UseGuards,
  HttpCode, HttpStatus, NotFoundException,
  DefaultValuePipe, ParseIntPipe,
} from '@nestjs/common';
import { Request } from 'express';
import { AuthGuard } from '../../../../shared/infrastructure/guards/auth.guard';
import { JwtPayload } from '../../../../shared/infrastructure/jwt/jwt.service';
import { GetTipoCambioHoyUseCase } from '../../application/use-cases/get-tipo-cambio-hoy.use-case';
import { GetTipoCambioByFechaUseCase } from '../../application/use-cases/get-tipo-cambio-by-fecha.use-case';
import { RegistrarTipoCambioUseCase } from '../../application/use-cases/registrar-tipo-cambio.use-case';
import { ListTipoCambioUseCase } from '../../application/use-cases/list-tipo-cambio.use-case';
import { UpdateTipoCambioUseCase } from '../../application/use-cases/update-tipo-cambio.use-case';
import { DeleteTipoCambioUseCase } from '../../application/use-cases/delete-tipo-cambio.use-case';
import { RegistrarTipoCambioDto } from '../dto/registrar-tipo-cambio.dto';

@Controller('tipo-cambio')
@UseGuards(AuthGuard)
export class TipoCambioController {
  constructor(
    private readonly getHoyUC: GetTipoCambioHoyUseCase,
    private readonly getByFechaUC: GetTipoCambioByFechaUseCase,
    private readonly registrarUC: RegistrarTipoCambioUseCase,
    private readonly listUC: ListTipoCambioUseCase,
    private readonly updateUC: UpdateTipoCambioUseCase,
    private readonly deleteUC: DeleteTipoCambioUseCase,
  ) {}

  @Get('hoy')
  async getHoy(@Req() req: Request) {
    const user = req['user'] as JwtPayload;
    return { data: await this.getHoyUC.execute(user.empresa) };
  }

  @Get('fecha/:fecha')
  async getByFecha(@Param('fecha') fecha: string, @Req() req: Request) {
    const user = req['user'] as JwtPayload;
    return { data: await this.getByFechaUC.execute(user.empresa, fecha) };
  }

  @Get()
  list(
    @Req() req: Request,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    const user = req['user'] as JwtPayload;
    return this.listUC.execute(user.empresa, page, limit);
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async registrar(@Body() dto: RegistrarTipoCambioDto, @Req() req: Request) {
    const user = req['user'] as JwtPayload;
    return { data: await this.registrarUC.execute(user.empresa, dto.tipoCambio, user.codigo) };
  }

  @Patch(':id')
  async update(
    @Param('id') id: string,
    @Body() dto: RegistrarTipoCambioDto,
    @Req() req: Request,
  ) {
    const user = req['user'] as JwtPayload;
    return { data: await this.updateUC.execute(user.empresa, id, dto.tipoCambio) };
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async delete(@Param('id') id: string, @Req() req: Request) {
    const user = req['user'] as JwtPayload;
    await this.deleteUC.execute(user.empresa, id);
  }
}
