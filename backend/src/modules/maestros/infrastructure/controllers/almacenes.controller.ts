import {
  Controller, Get, Post, Put, Body, Param, Query,
  Req, UseGuards, HttpCode, HttpStatus, NotFoundException,
} from '@nestjs/common';
import { Request } from 'express';
import { AuthGuard } from '../../../../shared/infrastructure/guards/auth.guard';
import { JwtPayload } from '../../../../shared/infrastructure/jwt/jwt.service';
import { SearchAlmacenesUseCase } from '../../application/use-cases/almacenes/search-almacenes.use-case';
import { SaveAlmacenUseCase } from '../../application/use-cases/almacenes/save-almacen.use-case';
import { IAlmacenRepository } from '../../domain/ports/almacen.repository.port';
import { CreateAlmacenDto, UpdateAlmacenDto } from '../dto/almacen.dto';

@Controller('maestros/almacenes')
@UseGuards(AuthGuard)
export class AlmacenesController {
  constructor(
    private readonly search: SearchAlmacenesUseCase,
    private readonly save: SaveAlmacenUseCase,
    private readonly repo: IAlmacenRepository,
  ) {}

  @Get()
  async list(
    @Req() req: Request,
    @Query('q') q?: string,
    @Query('activo') activo?: string,
  ) {
    const user = req['user'] as JwtPayload;
    const activoFilter = activo === undefined ? undefined : activo === 'true';
    return { data: await this.search.execute(user.empresa, q, activoFilter) };
  }

  @Get(':id')
  async findOne(@Param('id') id: string, @Req() req: Request) {
    const user = req['user'] as JwtPayload;
    const found = await this.repo.findById(id, user.empresa);
    if (!found) throw new NotFoundException('Almacén no encontrado');
    return { data: found };
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(@Body() dto: CreateAlmacenDto, @Req() req: Request) {
    const user = req['user'] as JwtPayload;
    return { data: await this.save.execute(user.empresa, dto) };
  }

  @Put(':id')
  async update(
    @Param('id') id: string,
    @Body() dto: UpdateAlmacenDto,
    @Req() req: Request,
  ) {
    const user = req['user'] as JwtPayload;
    return { data: await this.save.execute(user.empresa, dto as any, id) };
  }
}
