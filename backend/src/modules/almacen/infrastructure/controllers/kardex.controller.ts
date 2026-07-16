import {
  Controller, Get, Post, Query, UseGuards, Request, NotFoundException,
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
  async get(
    @Request() req: any,
    @Query('almacen') codigoAlmacen: string,
    @Query('articulo') codigoArticulo: string,
    @Query('desde') desde?: string,
    @Query('hasta') hasta?: string,
  ) {
    if (!codigoAlmacen || !codigoArticulo) {
      throw new NotFoundException('Se requiere almacen y articulo');
    }
    return this.getKardexUC.execute(
      req.user.empresa,
      codigoAlmacen,
      codigoArticulo,
      desde,
      hasta,
    );
  }

  @Post('recalcular')
  recalcular(@Request() req: any) {
    return this.recalcularUC.execute(req.user.empresa);
  }
}
