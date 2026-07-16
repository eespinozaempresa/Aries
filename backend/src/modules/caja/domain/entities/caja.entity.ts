export type TipoMovCaja = 'INGRESO' | 'EGRESO';
export type EstadoCaja = 'ABIERTA' | 'CERRADA';

export interface SesionCaja {
  id: string;
  codigoEmpresa: string;
  codigoCaja: string;
  codigoUsuario: string;
  fechaApertura: string;
  montoApertura: number;
  fechaCierre?: string;
  montosCierre?: number;
  diferencia?: number;
  estado: EstadoCaja;
  createdAt?: string;
}

export interface MovimientoCaja {
  id: string;
  codigoEmpresa: string;
  sesionCajaId: string;
  tipo: TipoMovCaja;
  concepto: string;
  referencia?: string;
  monto: number;
  fecha: string;
  codigoUsuario: string;
  createdAt?: string;
}
