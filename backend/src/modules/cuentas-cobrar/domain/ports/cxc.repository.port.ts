import { CuentaCobrar, Cobro } from '../entities/cuenta-cobrar.entity';

export interface CxCFilter {
  codigoEmpresa: string;
  codigoCliente?: string;
  pendiente?: boolean;
  desde?: string;
  hasta?: string;
  page?: number;
  limit?: number;
}

export interface CxCListResult {
  data: CuentaCobrar[];
  total: number;
  page: number;
  lastPage: number;
}

export interface RegistrarCobroData {
  cuentaCobrarId: string;
  numeroRecibo: string;
  fecha: string;
  tipoPago: 'EFECTIVO' | 'TRANSFERENCIA' | 'CHEQUE';
  numeroOperacion?: string;
  codigoBanco?: string;
  monto: number;
  codigoUsuario: string;
}

export interface RenovarCxCData {
  cuentaCobrarId: string;
  nuevaFechaVencimiento: string;
  interes?: number;
  codigoDocumento: string;
  numeroDocumento: string;
  codigoUsuario: string;
}

export abstract class ICxCRepository {
  abstract list(filter: CxCFilter): Promise<CxCListResult>;
  abstract findById(id: string, codigoEmpresa: string): Promise<CuentaCobrar | null>;
  abstract registrarCobro(codigoEmpresa: string, data: RegistrarCobroData): Promise<Cobro>;
  abstract getCobros(codigoEmpresa: string, cuentaCobrarId: string): Promise<Cobro[]>;
  abstract renovar(codigoEmpresa: string, data: RenovarCxCData): Promise<CuentaCobrar>;
}
