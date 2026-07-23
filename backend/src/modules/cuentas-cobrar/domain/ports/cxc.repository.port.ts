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
  tipoPago: string;
  numeroOperacion?: string;
  codigoBanco?: string;
  monto: number;
  codigoUsuario: string;
}

export interface CuotaRenovacion {
  numeroCuota: number;
  numeroLetra: string;
  fechaVencimiento: string;
  monto: number;
}

export interface RenovarCxCData {
  cuentaCobrarId: string;
  cuotas: CuotaRenovacion[];
  codigoUsuario: string;
}

export abstract class ICxCRepository {
  abstract list(filter: CxCFilter): Promise<CxCListResult>;
  abstract findById(id: string, codigoEmpresa: string): Promise<CuentaCobrar | null>;
  abstract registrarCobro(codigoEmpresa: string, data: RegistrarCobroData): Promise<Cobro>;
  abstract getCobros(codigoEmpresa: string, cuentaCobrarId: string): Promise<Cobro[]>;
  abstract eliminarCobro(codigoEmpresa: string, cobroId: string): Promise<CuentaCobrar>;
  abstract renovar(codigoEmpresa: string, data: RenovarCxCData): Promise<CuentaCobrar[]>;
}
