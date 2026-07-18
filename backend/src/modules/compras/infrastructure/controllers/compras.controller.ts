import {
  Controller, Post, Get, Patch, Delete, Body, Param, Query,
  UseGuards, Request, ParseIntPipe, DefaultValuePipe, NotFoundException, HttpCode,
} from '@nestjs/common';
import { AuthGuard } from '../../../../shared/infrastructure/guards/auth.guard';
import { RegistrarCompraUseCase } from '../../application/use-cases/registrar-compra.use-case';
import { AnularCompraUseCase } from '../../application/use-cases/anular-compra.use-case';
import { EliminarCompraUseCase } from '../../application/use-cases/eliminar-compra.use-case';
import { ListComprasUseCase } from '../../application/use-cases/list-compras.use-case';
import { ICompraRepository } from '../../domain/ports/compra.repository.port';
import { RegistrarCompraDto } from '../dto/compra.dto';

@UseGuards(AuthGuard)
@Controller('compras')
export class ComprasController {
  constructor(
    private readonly registrarUC: RegistrarCompraUseCase,
    private readonly anularUC: AnularCompraUseCase,
    private readonly eliminarUC: EliminarCompraUseCase,
    private readonly listUC: ListComprasUseCase,
    private readonly repo: ICompraRepository,
  ) {}

  @Post()
  registrar(@Body() dto: RegistrarCompraDto, @Request() req: any) {
    return this.registrarUC.execute(req.user.empresa, { ...dto, codigoUsuario: req.user.codigo });
  }

  @Get()
  list(
    @Request() req: any,
    @Query('proveedor') codigoProveedor?: string,
    @Query('almacen') codigoAlmacen?: string,
    @Query('desde') desde?: string,
    @Query('hasta') hasta?: string,
    @Query('anuladas') anuladas?: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page?: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit?: number,
  ) {
    return this.listUC.execute({
      codigoEmpresa: req.user.empresa,
      codigoProveedor, codigoAlmacen, desde, hasta,
      soloAnuladas: anuladas === 'true' ? true : anuladas === 'false' ? false : undefined,
      page, limit,
    });
  }

  @Get(':id')
  async findById(@Param('id') id: string, @Request() req: any) {
    const c = await this.repo.findById(id, req.user.empresa);
    if (!c) throw new NotFoundException();
    return c;
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
