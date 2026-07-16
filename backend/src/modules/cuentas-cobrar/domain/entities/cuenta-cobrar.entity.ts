export type TipoCxC = 'VENTA' | 'RENOVACION';

export interface CuentaCobrar {
  id: string;
  codigoEmpresa: string;
  numeroProvision: number;
  numeroProvisionOrigen?: number;
  tipo: TipoCxC;
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
  codigoCliente: string;
  descripcion?: string;
  pendiente: boolean;
  referencia?: string;
  createdAt?: string;
}

export interface Cobro {
  id: string;
  codigoEmpresa: string;
  cuentaCobrarId: string;
  numeroRecibo: string;
  fecha: string;
  tipoPago: 'EFECTIVO' | 'TRANSFERENCIA' | 'CHEQUE';
  numeroOperacion?: string;
  codigoBanco?: string;
  monto: number;
  estado: 'ACTIVO' | 'ANULADO';
  codigoUsuario: string;
  createdAt?: string;
}
