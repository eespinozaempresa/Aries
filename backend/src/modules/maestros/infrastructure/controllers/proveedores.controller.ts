import {
  Controller, Get, Post, Put, Body, Param, Query,
  Req, UseGuards, HttpCode, HttpStatus, NotFoundException,
  ParseIntPipe, DefaultValuePipe,
} from '@nestjs/common';
import { Request } from 'express';
import { AuthGuard } from '../../../../shared/infrastructure/guards/auth.guard';
import { JwtPayload } from '../../../../shared/infrastructure/jwt/jwt.service';
import { SearchProveedoresUseCase } from '../../application/use-cases/proveedores/search-proveedores.use-case';
import { SaveProveedorUseCase } from '../../application/use-cases/proveedores/save-proveedor.use-case';
import { IProveedorRepository } from '../../domain/ports/proveedor.repository.port';
import { CreatePersonaDto, UpdatePersonaDto } from '../dto/persona.dto';

@Controller('maestros/proveedores')
@UseGuards(AuthGuard)
export class ProveedoresController {
  constructor(
    private readonly search: SearchProveedoresUseCase,
    private readonly save: SaveProveedorUseCase,
    private readonly repo: IProveedorRepository,
  ) {}

  @Get(':id')
  async findOne(@Param('id') id: string, @Req() req: Request) {
    const user = req['user'] as JwtPayload;
    const proveedor = await this.repo.findById(id, user.empresa);
    if (!proveedor) throw new NotFoundException('Proveedor no encontrado');
    return { data: proveedor };
  }

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
    return this.search.execute(user.empresa, q, activoFilter, page, limit);
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(@Body() dto: CreatePersonaDto, @Req() req: Request) {
    const user = req['user'] as JwtPayload;
    return { data: await this.save.execute(user.empresa, dto) };
  }

  @Put(':id')
  async update(
    @Param('id') id: string,
    @Body() dto: UpdatePersonaDto,
    @Req() req: Request,
  ) {
    const user = req['user'] as JwtPayload;
    return { data: await this.save.execute(user.empresa, dto as any, id) };
  }
}
