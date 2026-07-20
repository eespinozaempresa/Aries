import { DetalleVenta } from './detalle-venta.entity';

export type TipoVenta = 'CONTADO' | 'CREDITO';

export interface Venta {
  id: string;
  codigoEmpresa: string;
  codigoDocumento: string;
  abreviaturaDocumento?: string;
  serie: string;
  numeroDocumento: string;
  fecha: string;
  observacion?: string;
  codigoAlmacen: string;
  codigoCliente: string;
  codigoUsuario: string;
  subtotal: number;
  igv: number;
  total: number;
  subtotalUsd: number;
  igvUsd: number;
  totalUsd: number;
  moneda: string;
  tipoCambio: number;
  tipoVenta: TipoVenta;
  plazoDias: number;
  fechaVencimiento?: string;
  anulado: boolean;
  createdAt?: string;
  detalles?: DetalleVenta[];
  razonSocialCliente?: string;
  descripcionAlmacen?: string;
}
