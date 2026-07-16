import { Injectable } from '@nestjs/common';
import { IStockRepository } from '../../domain/ports/stock.repository.port';
import { StockItem } from '../../domain/entities/stock-item.entity';

@Injectable()
export class GetStockUseCase {
  constructor(private readonly repo: IStockRepository) {}

  execute(
    codigoEmpresa: string,
    codigoAlmacen?: string,
    codigoArticulo?: string,
    q?: string,
    soloConStock?: boolean,
  ): Promise<StockItem[]> {
    return this.repo.query({ codigoEmpresa, codigoAlmacen, codigoArticulo, q, soloConStock });
  }
}
