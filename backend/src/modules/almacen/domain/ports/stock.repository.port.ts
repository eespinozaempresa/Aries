import { StockItem } from '../entities/stock-item.entity';

export interface StockFilter {
  codigoEmpresa: string;
  codigosAlmacen?: string[];
  codigosArticulo?: string[];
  q?: string;           // search by articulo description
  soloConStock?: boolean;
}

export abstract class IStockRepository {
  abstract query(filter: StockFilter): Promise<StockItem[]>;
  abstract resetForEmpresa(codigoEmpresa: string): Promise<void>;
}
