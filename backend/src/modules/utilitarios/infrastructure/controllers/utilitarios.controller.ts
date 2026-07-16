import {
  Controller, Get, Post, Put, Patch, Body, Param, Query,
  UseGuards, Request, HttpCode,
} from '@nestjs/common';
import { AuthGuard } from '../../../../shared/infrastructure/guards/auth.guard';
import { SupabaseUtilitariosRepository } from '../repositories/supabase-utilitarios.repository';
import { UpdateParametrosDto, CreateUsuarioDto, UpdateUsuarioDto } from '../dto/utilitarios.dto';

@UseGuards(AuthGuard)
@Controller('utilitarios')
export class UtilitariosController {
  constructor(private readonly repo: SupabaseUtilitariosRepository) {}

  @Get('parametros')
  getParametros(@Request() req: any) {
    return this.repo.getParametros(req.user.empresa);
  }

  @Put('parametros')
  updateParametros(@Body() dto: UpdateParametrosDto, @Request() req: any) {
    return this.repo.updateParametros(req.user.empresa, dto.igv, dto.tiempoFinanciamiento);
  }

  @Get('usuarios')
  listUsuarios(@Request() req: any) {
    return this.repo.listUsuarios(req.user.empresa);
  }

  @Post('usuarios')
  createUsuario(@Body() dto: CreateUsuarioDto, @Request() req: any) {
    return this.repo.createUsuario(req.user.empresa, dto);
  }

  @Put('usuarios/:id')
  updateUsuario(
    @Param('id') id: string,
    @Body() dto: UpdateUsuarioDto,
    @Request() req: any,
  ) {
    return this.repo.updateUsuario(id, req.user.empresa, dto);
  }

  @Patch('usuarios/:id/toggle')
  @HttpCode(200)
  toggleUsuario(@Param('id') id: string, @Request() req: any) {
    return this.repo.toggleUsuario(id, req.user.empresa);
  }

  @Get('auditoria')
  getAuditoria(@Query('limit') limit: string | undefined, @Request() req: any) {
    const parsedLimit = limit ? parseInt(limit, 10) : 50;
    return this.repo.getAuditoria(req.user.empresa, parsedLimit);
  }
}
