export type TipoCxP = 'COMPRA' | 'RENOVACION';

export interface CuentaPagar {
  id: string;
  codigoEmpresa: string;
  numeroProvision: number;
  numeroProvisionOrigen?: number;
  tipo: TipoCxP;
  codigoDocumento: string;
  numeroDocumento: string;
  numeroCuota: number;
  totalCuotas: number;
  montoTotal: number;
  montoPagado: number;
  saldo: number;
  interes: number;
  fechaEmision: string;
  fechaVencimiento?: string;
  codigoProveedor: string;
  razonSocialProveedor?: string;
  abreviaturaDocumento?: string;
  serieDocumento?: string;
  descripcion?: string;
  pendiente: boolean;
  referencia?: string;
  createdAt?: string;
}

export interface Pago {
  id: string;
  codigoEmpresa: string;
  cuentaPagarId: string;
  numeroVoucher: string;
  fecha: string;
  tipoPago: string;
  numeroOperacion?: string;
  codigoBanco?: string;
  monto: number;
  estado: 'ACTIVO' | 'ANULADO';
  codigoUsuario: string;
  createdAt?: string;
}
