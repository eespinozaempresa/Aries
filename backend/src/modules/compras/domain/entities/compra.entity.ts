import { DetalleCompra } from './detalle-compra.entity';

export type FormaPago = 'CONTADO' | 'CREDITO';

export interface Compra {
  id: string;
  codigoEmpresa: string;
  codigoDocumento: string;
  abreviaturaDocumento?: string;
  serie: string;
  numeroDocumento: string;
  fecha: string;
  formaPago: FormaPago;
  plazoDias: number;
  fechaVencimiento?: string;
  observacion?: string;
  codigoAlmacen: string;
  codigoProveedor: string;
  codigoUsuario: string;
  subtotal: number;
  igv: number;
  total: number;
  subtotalUsd: number;
  igvUsd: number;
  totalUsd: number;
  moneda: string;
  tipoCambio: number;
  anulado: boolean;
  createdAt?: string;
  detalles?: DetalleCompra[];
  razonSocialProveedor?: string;
  descripcionAlmacen?: string;
}
