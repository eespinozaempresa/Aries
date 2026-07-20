import {
  Controller, Post, Get, Patch, Delete, Body, Param, Query,
  UseGuards, Request, ParseIntPipe, DefaultValuePipe, NotFoundException, HttpCode,
} from '@nestjs/common';
import { AuthGuard } from '../../../../shared/infrastructure/guards/auth.guard';
import { RegistrarVentaUseCase } from '../../application/use-cases/registrar-venta.use-case';
import { AnularVentaUseCase } from '../../application/use-cases/anular-venta.use-case';
import { EliminarVentaUseCase } from '../../application/use-cases/eliminar-venta.use-case';
import { ListVentasUseCase } from '../../application/use-cases/list-ventas.use-case';
import { ReporteUtilidadUseCase } from '../../application/use-cases/reporte-utilidad.use-case';
import { IVentaRepository } from '../../domain/ports/venta.repository.port';
import { RegistrarVentaDto } from '../dto/venta.dto';

@UseGuards(AuthGuard)
@Controller('ventas')
export class VentasController {
  constructor(
    private readonly registrarUC: RegistrarVentaUseCase,
    private readonly anularUC: AnularVentaUseCase,
    private readonly eliminarUC: EliminarVentaUseCase,
    private readonly listUC: ListVentasUseCase,
    private readonly utilidadUC: ReporteUtilidadUseCase,
    private readonly repo: IVentaRepository,
  ) {}

  @Post()
  registrar(@Body() dto: RegistrarVentaDto, @Request() req: any) {
    return this.registrarUC.execute(req.user.empresa, { ...dto, codigoUsuario: req.user.codigo });
  }

  @Get()
  list(
    @Request() req: any,
    @Query('cliente') codigoCliente?: string,
    @Query('almacen') codigoAlmacen?: string,
    @Query('desde') desde?: string,
    @Query('hasta') hasta?: string,
    @Query('anuladas') anuladas?: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page?: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit?: number,
  ) {
    return this.listUC.execute({
      codigoEmpresa: req.user.empresa,
      codigoCliente, codigoAlmacen, desde, hasta,
      soloAnuladas: anuladas === 'true' ? true : anuladas === 'false' ? false : undefined,
      page, limit,
    });
  }

  @Get('reporte/utilidad')
  utilidad(
    @Request() req: any,
    @Query('almacen') almacen?: string,
    @Query('desde') desde?: string,
    @Query('hasta') hasta?: string,
  ) {
    return this.utilidadUC.execute(req.user.empresa, almacen, desde, hasta);
  }

  @Get('reporte/ventas')
  reporteVentas(
    @Request() req: any,
    @Query('tipo') tipo: 'general' | 'detallado' = 'general',
    @Query('desde') desde?: string,
    @Query('hasta') hasta?: string,
    @Query('almacen') almacen?: string,
    @Query('tipoVenta') tipoVenta?: string,
  ) {
    return this.repo.reporteVentas(req.user.empresa, { tipo, desde, hasta, almacen, tipoVenta });
  }

  @Get('reporte/general')
  reporteGeneral(
    @Request() req: any,
    @Query('desde') desde?: string,
    @Query('hasta') hasta?: string,
    @Query('almacen') almacen?: string,
    @Query('cliente') cliente?: string,
    @Query('articulo') articulo?: string,
    @Query('usuario') usuario?: string,
  ) {
    return this.repo.reporteGeneral(req.user.empresa, { desde, hasta, almacen, cliente, articulo, usuario });
  }

  @Get(':id')
  async findById(@Param('id') id: string, @Request() req: any) {
    const v = await this.repo.findById(id, req.user.empresa);
    if (!v) throw new NotFoundException();
    return v;
  }

  @Patch(':id/anular')
  anular(@Param('id') id: string, @Request() req: any) {
    return this.anularUC.execute(req.user.empresa, id, req.user.codigo);
  }

  @Delete(':id')
  @HttpCode(204)
  eliminar(@Param('id') id: string, @Request() req: any) {
    return this.eliminarUC.execute(req.user.empresa, id);
  }
}
