import {
  Controller, Post, Get, Patch, Delete, Body, Param, Query,
  UseGuards, Request, ParseIntPipe, DefaultValuePipe, BadRequestException, NotFoundException,
} from '@nestjs/common';
import { AuthGuard } from '../../../../shared/infrastructure/guards/auth.guard';
import { RegistrarMovimientoUseCase } from '../../application/use-cases/registrar-movimiento.use-case';
import { AnularMovimientoUseCase } from '../../application/use-cases/anular-movimiento.use-case';
import { ListMovimientosUseCase } from '../../application/use-cases/list-movimientos.use-case';
import { EliminarMovimientoUseCase } from '../../application/use-cases/eliminar-movimiento.use-case';
import { IMovimientoRepository } from '../../domain/ports/movimiento.repository.port';
import { RegistrarMovimientoDto } from '../dto/movimiento.dto';

@UseGuards(AuthGuard)
@Controller('almacen/movimientos')
export class MovimientosController {
  constructor(
    private readonly registrarUC: RegistrarMovimientoUseCase,
    private readonly anularUC: AnularMovimientoUseCase,
    private readonly listUC: ListMovimientosUseCase,
    private readonly eliminarUC: EliminarMovimientoUseCase,
    private readonly repo: IMovimientoRepository,
  ) {}

  @Post()
  async registrar(@Body() dto: RegistrarMovimientoDto, @Request() req: any) {
    const { empresa, codigo } = req.user;
    if (dto.tipo === 'TRASLADO' && !dto.codigoAlmacenDest) {
      throw new BadRequestException('TRASLADO requiere codigoAlmacenDest');
    }
    return this.registrarUC.execute(empresa, { ...dto, codigoUsuario: codigo });
  }

  @Get()
  list(
    @Request() req: any,
    @Query('tipo') tipo?: string,
    @Query('almacen') codigoAlmacen?: string,
    @Query('desde') desde?: string,
    @Query('hasta') hasta?: string,
    @Query('anulados') anulados?: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page?: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit?: number,
  ) {
    return this.listUC.execute(
      req.user.empresa,
      tipo as any,
      codigoAlmacen,
      desde,
      hasta,
      page,
      limit,
    );
  }

  @Get(':id')
  async findById(@Param('id') id: string, @Request() req: any) {
    const mov = await this.repo.findById(id, req.user.empresa);
    if (!mov) throw new NotFoundException();
    return mov;
  }

  @Patch(':id/anular')
  async anular(@Param('id') id: string, @Request() req: any) {
    await this.anularUC.execute(req.user.empresa, id, req.user.codigo);
    const mov = await this.repo.findById(id, req.user.empresa);
    return mov;
  }

  @Delete(':id')
  async eliminar(@Param('id') id: string, @Request() req: any) {
    await this.eliminarUC.execute(req.user.empresa, id);
    return { success: true };
  }
}
