import { KardexItem } from '../entities/kardex-item.entity';

export interface KardexFilter {
  codigoEmpresa: string;
  codigoAlmacen: string;
  codigoArticulo: string;
  desde?: string;
  hasta?: string;
}

export abstract class IKardexRepository {
  abstract query(filter: KardexFilter): Promise<KardexItem[]>;
  abstract deleteByEmpresa(codigoEmpresa: string): Promise<void>;
}
