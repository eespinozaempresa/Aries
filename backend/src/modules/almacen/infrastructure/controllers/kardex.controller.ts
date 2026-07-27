import {
  Controller, Get, Post, Query, UseGuards, Request,
} from '@nestjs/common';
import { AuthGuard } from '../../../../shared/infrastructure/guards/auth.guard';
import { GetKardexUseCase } from '../../application/use-cases/get-kardex.use-case';
import { RecalcularKardexUseCase } from '../../application/use-cases/recalcular-kardex.use-case';

@UseGuards(AuthGuard)
@Controller('almacen/kardex')
export class KardexController {
  constructor(
    private readonly getKardexUC: GetKardexUseCase,
    private readonly recalcularUC: RecalcularKardexUseCase,
  ) {}

  @Get()
  get(
    @Request() req: any,
    @Query('almacen') almacen?: string,
    @Query('articulo') articulo?: string,
    @Query('desde') desde?: string,
    @Query('hasta') hasta?: string,
  ) {
    return this.getKardexUC.execute(
      req.user.empresa,
      almacen ? almacen.split(',') : undefined,
      articulo ? articulo.split(',') : undefined,
      desde,
      hasta,
    );
  }

  @Post('recalcular')
  recalcular(@Request() req: any) {
    return this.recalcularUC.execute(req.user.empresa);
  }
}
