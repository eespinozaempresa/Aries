import { Injectable } from '@nestjs/common';
import { IStockRepository } from '../../domain/ports/stock.repository.port';
import { StockItem } from '../../domain/entities/stock-item.entity';

@Injectable()
export class GetStockUseCase {
  constructor(private readonly repo: IStockRepository) {}

  execute(
    codigoEmpresa: string,
    codigosAlmacen?: string[],
    codigosArticulo?: string[],
    q?: string,
    soloConStock?: boolean,
  ): Promise<StockItem[]> {
    return this.repo.query({ codigoEmpresa, codigosAlmacen, codigosArticulo, q, soloConStock });
  }
}
