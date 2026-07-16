import { SesionCaja, MovimientoCaja } from '../entities/caja.entity';

export interface AbrirCajaData {
  codigoCaja: string;
  montoApertura: number;
  codigoUsuario: string;
}

export interface CerrarCajaData {
  sesionCajaId: string;
  montosCierre: number;
}

export interface RegistrarMovCajaData {
  sesionCajaId: string;
  tipo: 'INGRESO' | 'EGRESO';
  concepto: string;
  referencia?: string;
  monto: number;
  fecha: string;
  codigoUsuario: string;
}

export interface CajaFilter {
  codigoEmpresa: string;
  codigoCaja?: string;
  estado?: 'ABIERTA' | 'CERRADA';
  page?: number;
  limit?: number;
}

export interface CajaListResult {
  data: SesionCaja[];
  total: number;
  page: number;
  lastPage: number;
}

export interface ReporteCaja {
  sesion: SesionCaja;
  movimientos: MovimientoCaja[];
  totalIngresos: number;
  totalEgresos: number;
  saldoFinal: number;
}

export abstract class ICajaRepository {
  abstract list(filter: CajaFilter): Promise<CajaListResult>;
  abstract findById(id: string, codigoEmpresa: string): Promise<SesionCaja | null>;
  abstract abrir(codigoEmpresa: string, data: AbrirCajaData): Promise<SesionCaja>;
  abstract cerrar(codigoEmpresa: string, data: CerrarCajaData): Promise<SesionCaja>;
  abstract registrarMovimiento(codigoEmpresa: string, data: RegistrarMovCajaData): Promise<MovimientoCaja>;
  abstract getMovimientos(codigoEmpresa: string, sesionCajaId: string): Promise<MovimientoCaja[]>;
  abstract reporte(codigoEmpresa: string, sesionCajaId: string): Promise<ReporteCaja>;
}
