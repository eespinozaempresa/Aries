import {
  Controller, Get, Post, Delete, Param, Body, Query,
  UseGuards, Request, ParseBoolPipe, ParseIntPipe,
  Optional,
} from '@nestjs/common';
import { AuthGuard } from '../../../../shared/infrastructure/guards/auth.guard';
import {
  ListCxCUseCase, FindCxCUseCase,
  RegistrarCobroUseCase, GetCobrosUseCase, EliminarCobroUseCase, RenovarCxCUseCase,
} from '../../application/use-cases/cxc.use-cases';
import { RegistrarCobroDto, RenovarCxCDto } from '../dto/cxc.dto';

@UseGuards(AuthGuard)
@Controller('cxc')
export class CxCController {
  constructor(
    private readonly listUC: ListCxCUseCase,
    private readonly findUC: FindCxCUseCase,
    private readonly registrarCobroUC: RegistrarCobroUseCase,
    private readonly getCobrosUC: GetCobrosUseCase,
    private readonly eliminarCobroUC: EliminarCobroUseCase,
    private readonly renovarUC: RenovarCxCUseCase,
  ) {}

  @Get()
  list(
    @Request() req: any,
    @Query('codigoCliente') codigoCliente?: string,
    @Query('pendiente') pendienteStr?: string,
    @Query('desde') desde?: string,
    @Query('hasta') hasta?: string,
    @Query('page') pageStr?: string,
    @Query('limit') limitStr?: string,
  ) {
    const pendiente = pendienteStr !== undefined ? pendienteStr === 'true' : undefined;
    return this.listUC.execute({
      codigoEmpresa: req.user.empresa,
      codigoCliente,
      pendiente,
      desde,
      hasta,
      page:  pageStr  ? parseInt(pageStr, 10)  : undefined,
      limit: limitStr ? parseInt(limitStr, 10) : undefined,
    });
  }

  @Get(':id')
  findOne(@Param('id') id: string, @Request() req: any) {
    return this.findUC.execute(id, req.user.empresa);
  }

  @Get(':id/cobros')
  cobros(@Param('id') id: string, @Request() req: any) {
    return this.getCobrosUC.execute(req.user.empresa, id);
  }

  @Post('cobros')
  registrarCobro(@Body() dto: RegistrarCobroDto, @Request() req: any) {
    return this.registrarCobroUC.execute(req.user.empresa, {
      ...dto,
      codigoUsuario: req.user.codigo,
    });
  }

  @Delete('cobros/:id')
  eliminarCobro(@Param('id') id: string, @Request() req: any) {
    return this.eliminarCobroUC.execute(req.user.empresa, id);
  }

  @Post(':id/renovar')
  renovar(@Param('id') id: string, @Body() dto: RenovarCxCDto, @Request() req: any) {
    return this.renovarUC.execute(req.user.empresa, {
      cuentaCobrarId: id,
      ...dto,
      codigoUsuario: req.user.codigo,
    });
  }
}
