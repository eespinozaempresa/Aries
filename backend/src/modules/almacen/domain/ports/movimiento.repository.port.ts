import { Movimiento, TipoMovimiento } from '../entities/movimiento.entity';

export interface RegistrarMovimientoData {
  codigoDocumento: string;
  serie: string;
  fecha: string;
  tipo: TipoMovimiento;
  codigoAlmacenOrigen: string;
  codigoAlmacenDest?: string;
  observacion?: string;
  concepto?: string;
  codigoUsuario: string;
  lineas: Array<{
    codigoArticulo: string;
    cantidad: number;
    precioUnitario: number;
  }>;
}

export interface MovimientoFilter {
  codigoEmpresa: string;
  tipo?: TipoMovimiento;
  codigoAlmacen?: string;
  desde?: string;
  hasta?: string;
  soloAnulados?: boolean;
  page?: number;
  limit?: number;
}

export interface MovimientoListResult {
  data: Movimiento[];
  total: number;
  page: number;
  lastPage: number;
}

export abstract class IMovimientoRepository {
  abstract registrar(codigoEmpresa: string, data: RegistrarMovimientoData): Promise<string>;
  abstract anular(codigoEmpresa: string, movimientoId: string, codigoUsuario: string): Promise<boolean>;
  abstract list(filter: MovimientoFilter): Promise<MovimientoListResult>;
  abstract findById(id: string, codigoEmpresa: string): Promise<Movimiento | null>;
}
