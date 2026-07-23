import {
  Controller, Get, Post, Delete, Param, Body, Query, UseGuards, Request,
} from '@nestjs/common';
import { AuthGuard } from '../../../../shared/infrastructure/guards/auth.guard';
import {
  ListCxPUseCase, FindCxPUseCase,
  RegistrarPagoUseCase, GetPagosUseCase, EliminarPagoUseCase, RenovarCxPUseCase,
} from '../../application/use-cases/cxp.use-cases';
import { RegistrarPagoDto, RenovarCxPDto } from '../dto/cxp.dto';

@UseGuards(AuthGuard)
@Controller('cxp')
export class CxPController {
  constructor(
    private readonly listUC: ListCxPUseCase,
    private readonly findUC: FindCxPUseCase,
    private readonly registrarPagoUC: RegistrarPagoUseCase,
    private readonly getPagosUC: GetPagosUseCase,
    private readonly eliminarPagoUC: EliminarPagoUseCase,
    private readonly renovarUC: RenovarCxPUseCase,
  ) {}

  @Get()
  list(
    @Request() req: any,
    @Query('codigoProveedor') codigoProveedor?: string,
    @Query('pendiente') pendienteStr?: string,
    @Query('desde') desde?: string,
    @Query('hasta') hasta?: string,
    @Query('page') pageStr?: string,
    @Query('limit') limitStr?: string,
  ) {
    const pendiente = pendienteStr !== undefined ? pendienteStr === 'true' : undefined;
    return this.listUC.execute({
      codigoEmpresa: req.user.empresa,
      codigoProveedor,
      pendiente,
      desde,
      hasta,
      page:  pageStr  ? parseInt(pageStr, 10)  : undefined,
      limit: limitStr ? parseInt(limitStr, 10) : undefined,
    });
  }

  @Get(':id')
  findOne(@Param('id') id: string, @Request() req: any) {
    return this.findUC.execute(id, req.user.empresa);
  }

  @Get(':id/pagos')
  pagos(@Param('id') id: string, @Request() req: any) {
    return this.getPagosUC.execute(req.user.empresa, id);
  }

  @Post('pagos')
  registrarPago(@Body() dto: RegistrarPagoDto, @Request() req: any) {
    return this.registrarPagoUC.execute(req.user.empresa, {
      ...dto,
      codigoUsuario: req.user.codigo,
    });
  }

  @Delete('pagos/:id')
  eliminarPago(@Param('id') id: string, @Request() req: any) {
    return this.eliminarPagoUC.execute(req.user.empresa, id);
  }

  @Post(':id/renovar')
  renovar(@Param('id') id: string, @Body() dto: RenovarCxPDto, @Request() req: any) {
    return this.renovarUC.execute(req.user.empresa, {
      cuentaPagarId: id,
      ...dto,
      codigoUsuario: req.user.codigo,
    });
  }
}
