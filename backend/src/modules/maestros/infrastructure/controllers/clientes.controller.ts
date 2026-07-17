import {
  Controller, Get, Post, Put, Body, Param, Query,
  Req, UseGuards, HttpCode, HttpStatus,
  ParseIntPipe, DefaultValuePipe, NotFoundException,
} from '@nestjs/common';
import { Request } from 'express';
import { AuthGuard } from '../../../../shared/infrastructure/guards/auth.guard';
import { JwtPayload } from '../../../../shared/infrastructure/jwt/jwt.service';
import { SearchClientesUseCase } from '../../application/use-cases/clientes/search-clientes.use-case';
import { SaveClienteUseCase } from '../../application/use-cases/clientes/save-cliente.use-case';
import { IClienteRepository } from '../../domain/ports/cliente.repository.port';
import { CreatePersonaDto, UpdatePersonaDto } from '../dto/persona.dto';

@Controller('maestros/clientes')
@UseGuards(AuthGuard)
export class ClientesController {
  constructor(
    private readonly search: SearchClientesUseCase,
    private readonly save: SaveClienteUseCase,
    private readonly repo: IClienteRepository,
  ) {}

  @Get(':id')
  async findOne(@Param('id') id: string, @Req() req: Request) {
    const user = req['user'] as JwtPayload;
    const cliente = await this.repo.findById(id, user.empresa);
    if (!cliente) throw new NotFoundException('Cliente no encontrado');
    return { data: cliente };
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
