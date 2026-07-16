import { CuentaPagar, Pago } from '../entities/cuenta-pagar.entity';

export interface CxPFilter {
  codigoEmpresa: string;
  codigoProveedor?: string;
  pendiente?: boolean;
  desde?: string;
  hasta?: string;
  page?: number;
  limit?: number;
}

export interface CxPListResult {
  data: CuentaPagar[];
  total: number;
  page: number;
  lastPage: number;
}

export interface RegistrarPagoData {
  cuentaPagarId: string;
  numeroVoucher: string;
  fecha: string;
  tipoPago: 'EFECTIVO' | 'TRANSFERENCIA' | 'CHEQUE';
  numeroOperacion?: string;
  codigoBanco?: string;
  monto: number;
  codigoUsuario: string;
}

export interface RenovarCxPData {
  cuentaPagarId: string;
  nuevaFechaVencimiento: string;
  interes?: number;
  codigoDocumento: string;
  numeroDocumento: string;
  codigoUsuario: string;
}

export abstract class ICxPRepository {
  abstract list(filter: CxPFilter): Promise<CxPListResult>;
  abstract findById(id: string, codigoEmpresa: string): Promise<CuentaPagar | null>;
  abstract registrarPago(codigoEmpresa: string, data: RegistrarPagoData): Promise<Pago>;
  abstract getPagos(codigoEmpresa: string, cuentaPagarId: string): Promise<Pago[]>;
  abstract renovar(codigoEmpresa: string, data: RenovarCxPData): Promise<CuentaPagar>;
}
