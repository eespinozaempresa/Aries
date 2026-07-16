import {
  Controller, Get, Post, Param, Body, Query, UseGuards, Request,
} from '@nestjs/common';
import { AuthGuard } from '../../../../shared/infrastructure/guards/auth.guard';
import {
  ListCajaUseCase, FindSesionUseCase, AbrirCajaUseCase,
  CerrarCajaUseCase, RegistrarMovCajaUseCase, ReporteCajaUseCase,
} from '../../application/use-cases/caja.use-cases';
import { AbrirCajaDto, CerrarCajaDto, RegistrarMovCajaDto } from '../dto/caja.dto';

@UseGuards(AuthGuard)
@Controller('caja')
export class CajaController {
  constructor(
    private readonly listUC: ListCajaUseCase,
    private readonly findUC: FindSesionUseCase,
    private readonly abrirUC: AbrirCajaUseCase,
    private readonly cerrarUC: CerrarCajaUseCase,
    private readonly movUC: RegistrarMovCajaUseCase,
    private readonly reporteUC: ReporteCajaUseCase,
  ) {}

  @Get()
  list(
    @Request() req: any,
    @Query('codigoCaja') codigoCaja?: string,
    @Query('estado') estado?: 'ABIERTA' | 'CERRADA',
    @Query('page') pageStr?: string,
    @Query('limit') limitStr?: string,
  ) {
    return this.listUC.execute({
      codigoEmpresa: req.user.empresa,
      codigoCaja,
      estado,
      page:  pageStr  ? parseInt(pageStr, 10)  : undefined,
      limit: limitStr ? parseInt(limitStr, 10) : undefined,
    });
  }

  @Get(':id')
  findOne(@Param('id') id: string, @Request() req: any) {
    return this.findUC.execute(id, req.user.empresa);
  }

  @Get(':id/reporte')
  reporte(@Param('id') id: string, @Request() req: any) {
    return this.reporteUC.execute(req.user.empresa, id);
  }

  @Post('abrir')
  abrir(@Body() dto: AbrirCajaDto, @Request() req: any) {
    return this.abrirUC.execute(req.user.empresa, {
      ...dto,
      codigoUsuario: req.user.codigo,
    });
  }

  @Post(':id/cerrar')
  cerrar(@Param('id') id: string, @Body() dto: CerrarCajaDto, @Request() req: any) {
    return this.cerrarUC.execute(req.user.empresa, {
      sesionCajaId: id,
      montosCierre: dto.montosCierre,
    });
  }

  @Post('movimientos')
  registrarMovimiento(@Body() dto: RegistrarMovCajaDto, @Request() req: any) {
    return this.movUC.execute(req.user.empresa, {
      ...dto,
      codigoUsuario: req.user.codigo,
    });
  }
}
