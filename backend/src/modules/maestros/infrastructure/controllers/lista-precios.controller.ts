import {
  Controller, Get, Post, Put, Delete, Patch,
  Body, Param, Query, Request, UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '../../../../shared/infrastructure/guards/auth.guard';
import { IListaPrecioRepository } from '../../domain/ports/lista-precio.repository.port';
import { CreateListaPrecioDto, UpdateListaPrecioDto } from '../dto/lista-precio.dto';

@UseGuards(AuthGuard)
@Controller('maestros/lista-precios')
export class ListaPreciosController {
  constructor(private readonly repo: IListaPrecioRepository) {}

  @Get()
  async list(
    @Request() req: any,
    @Query('articuloId') articuloId?: string,
    @Query('tipoListaId') tipoListaId?: string,
  ) {
    const emp = req.user.empresa;
    if (articuloId && tipoListaId) {
      return this.repo.findByTipoLista(emp, articuloId, tipoListaId);
    }
    if (articuloId) {
      return this.repo.findByArticulo(emp, articuloId);
    }
    return [];
  }

  @Post()
  create(@Body() dto: CreateListaPrecioDto, @Request() req: any) {
    return this.repo.save(req.user.empresa, dto);
  }

  @Put(':id')
  update(
    @Param('id') id: string,
    @Body() dto: UpdateListaPrecioDto,
    @Request() req: any,
  ) {
    return this.repo.save(req.user.empresa, dto as any, id);
  }

  @Delete(':id')
  remove(@Param('id') id: string, @Request() req: any) {
    return this.repo.remove(req.user.empresa, id);
  }

  @Patch(':id/toggle')
  toggle(@Param('id') id: string, @Request() req: any) {
    return this.repo.toggleActivo(req.user.empresa, id);
  }
}
