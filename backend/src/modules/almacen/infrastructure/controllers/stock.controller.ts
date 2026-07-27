import { Controller, Get, Query, UseGuards, Request } from '@nestjs/common';
import { AuthGuard } from '../../../../shared/infrastructure/guards/auth.guard';
import { GetStockUseCase } from '../../application/use-cases/get-stock.use-case';

@UseGuards(AuthGuard)
@Controller('almacen/stock')
export class StockController {
  constructor(private readonly getStockUC: GetStockUseCase) {}

  @Get()
  get(
    @Request() req: any,
    @Query('almacen') almacen?: string,
    @Query('articulo') articulo?: string,
    @Query('q') q?: string,
    @Query('soloConStock') soloConStock?: string,
  ) {
    return this.getStockUC.execute(
      req.user.empresa,
      almacen ? almacen.split(',') : undefined,
      articulo ? articulo.split(',') : undefined,
      q,
      soloConStock === 'true',
    );
  }
}
