import {
  Controller, Get, Post, Put, Patch, Body, Param, Query,
  Req, UseGuards, HttpCode, HttpStatus,
  ParseIntPipe, DefaultValuePipe, NotFoundException,
} from '@nestjs/common';
import { Request } from 'express';
import { AuthGuard } from '../../../../shared/infrastructure/guards/auth.guard';
import { JwtPayload } from '../../../../shared/infrastructure/jwt/jwt.service';
import { SearchArticulosUseCase } from '../../application/use-cases/articulos/search-articulos.use-case';
import { SaveArticuloUseCase } from '../../application/use-cases/articulos/save-articulo.use-case';
import { IArticuloRepository } from '../../domain/ports/articulo.repository.port';
import { CreateArticuloDto, UpdateArticuloDto } from '../dto/articulo.dto';

@Controller('maestros/articulos')
@UseGuards(AuthGuard)
export class ArticulosController {
  constructor(
    private readonly searchUC: SearchArticulosUseCase,
    private readonly saveUC: SaveArticuloUseCase,
    private readonly repo: IArticuloRepository,
  ) {}

  @Get()
  async list(
    @Req() req: Request,
    @Query('q') q?: string,
    @Query('activo') activo?: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page = 1,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit = 20,
  ) {
    const user = req['user'] as JwtPayload;
    const activoFilter = activo === undefined ? undefined : activo === 'true';
    return this.searchUC.execute(user.empresa, q, activoFilter, page, limit);
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(@Body() dto: CreateArticuloDto, @Req() req: Request) {
    const user = req['user'] as JwtPayload;
    return { data: await this.saveUC.execute(user.empresa, dto) };
  }

  @Put(':id')
  async update(
    @Param('id') id: string,
    @Body() dto: UpdateArticuloDto,
    @Req() req: Request,
  ) {
    const user = req['user'] as JwtPayload;
    return { data: await this.saveUC.execute(user.empresa, dto as any, id) };
  }

  @Patch(':id/toggle')
  async toggle(@Param('id') id: string, @Req() req: Request) {
    const user = req['user'] as JwtPayload;
    const current = await this.repo.findById(id, user.empresa);
    if (!current) throw new NotFoundException('Artículo no encontrado');
    return { data: await this.repo.update(id, user.empresa, { activo: !current.activo }) };
  }
}
