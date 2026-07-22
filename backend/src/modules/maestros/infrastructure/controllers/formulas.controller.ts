import {
  Controller, Get, Post, Put, Patch, Body, Param, Query,
  Req, UseGuards, HttpCode, HttpStatus, NotFoundException,
} from '@nestjs/common';
import { Request } from 'express';
import { AuthGuard } from '../../../../shared/infrastructure/guards/auth.guard';
import { JwtPayload } from '../../../../shared/infrastructure/jwt/jwt.service';
import { SearchFormulasUseCase } from '../../application/use-cases/formulas/search-formulas.use-case';
import { SaveFormulaUseCase } from '../../application/use-cases/formulas/save-formula.use-case';
import { IFormulaRepository } from '../../domain/ports/formula.repository.port';
import { CreateFormulaDto, UpdateFormulaDto } from '../dto/formula.dto';

@Controller('maestros/formulas')
@UseGuards(AuthGuard)
export class FormulasController {
  constructor(
    private readonly search: SearchFormulasUseCase,
    private readonly save: SaveFormulaUseCase,
    private readonly repo: IFormulaRepository,
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
    if (!found) throw new NotFoundException('Fórmula no encontrada');
    return { data: found };
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(@Body() dto: CreateFormulaDto, @Req() req: Request) {
    const user = req['user'] as JwtPayload;
    return { data: await this.save.execute(user.empresa, dto) };
  }

  @Put(':id')
  async update(
    @Param('id') id: string,
    @Body() dto: UpdateFormulaDto,
    @Req() req: Request,
  ) {
    const user = req['user'] as JwtPayload;
    return { data: await this.save.execute(user.empresa, dto, id) };
  }

  @Patch(':id/toggle')
  async toggle(@Param('id') id: string, @Req() req: Request) {
    const user = req['user'] as JwtPayload;
    return { data: await this.repo.toggleActivo(user.empresa, id) };
  }
}
