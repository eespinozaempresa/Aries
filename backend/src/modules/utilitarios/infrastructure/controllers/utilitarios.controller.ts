import {
  Controller, Get, Post, Put, Patch, Body, Param, Query,
  UseGuards, Request, HttpCode, ForbiddenException,
} from '@nestjs/common';
import { AuthGuard } from '../../../../shared/infrastructure/guards/auth.guard';
import { SupabaseUtilitariosRepository } from '../repositories/supabase-utilitarios.repository';
import { UpdateParametrosDto, CreateUsuarioDto, UpdateUsuarioDto, ResetPasswordDto, CreatePerfilDto, UpdatePerfilDto } from '../dto/utilitarios.dto';

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
    return this.repo.updateParametros(req.user.empresa, dto.igv, dto.tiempoFinanciamiento, dto.almacenPartes);
  }

  @Get('usuarios')
  listUsuarios(@Request() req: any) {
    return this.repo.listUsuarios(req.user.empresa, req.user.nivel);
  }

  @Post('usuarios')
  createUsuario(@Body() dto: CreateUsuarioDto, @Request() req: any) {
    return this.repo.createUsuario(req.user.empresa, dto);
  }

  @Put('usuarios/:id')
  async updateUsuario(
    @Param('id') id: string,
    @Body() dto: UpdateUsuarioDto,
    @Request() req: any,
  ) {
    await this.assertNotAdmin(id, req.user.empresa, req.user.nivel);
    return this.repo.updateUsuario(id, req.user.empresa, dto);
  }

  @Patch('usuarios/:id/toggle')
  @HttpCode(200)
  async toggleUsuario(@Param('id') id: string, @Request() req: any) {
    await this.assertNotAdmin(id, req.user.empresa, req.user.nivel);
    return this.repo.toggleUsuario(id, req.user.empresa);
  }

  @Patch('usuarios/:id/reset-password')
  @HttpCode(200)
  async resetPasswordUsuario(
    @Param('id') id: string,
    @Body() dto: ResetPasswordDto,
    @Request() req: any,
  ) {
    await this.assertNotAdmin(id, req.user.empresa, req.user.nivel);
    return this.repo.resetPasswordUsuario(id, req.user.empresa, dto.nuevaClave);
  }

  private async assertNotAdmin(id: string, empresa: string, requestingNivel: string): Promise<void> {
    const targetNivel = await this.repo.getUsuarioNivel(id, empresa);
    if (targetNivel?.toUpperCase() === 'ADMIN' && requestingNivel?.toUpperCase() !== 'ADMIN') {
      throw new ForbiddenException('No tiene permisos para modificar un usuario administrador');
    }
  }

  @Get('auditoria')
  getAuditoria(@Query('limit') limit: string | undefined, @Request() req: any) {
    const parsedLimit = limit ? parseInt(limit, 10) : 50;
    return this.repo.getAuditoria(req.user.empresa, parsedLimit, req.user.nivel);
  }

  @Get('perfiles')
  listPerfiles(@Request() req: any) {
    return this.repo.listPerfiles(req.user.empresa);
  }

  @Post('perfiles')
  createPerfil(@Body() dto: CreatePerfilDto, @Request() req: any) {
    return this.repo.createPerfil(req.user.empresa, dto);
  }

  @Put('perfiles/:id')
  updatePerfil(
    @Param('id') id: string,
    @Body() dto: UpdatePerfilDto,
    @Request() req: any,
  ) {
    return this.repo.updatePerfil(id, req.user.empresa, dto);
  }

  @Patch('perfiles/:id/toggle')
  @HttpCode(200)
  togglePerfil(@Param('id') id: string, @Request() req: any) {
    return this.repo.togglePerfil(id, req.user.empresa);
  }
}
