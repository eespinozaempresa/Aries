import { DetalleVenta } from './detalle-venta.entity';

export type TipoVenta = 'CONTADO' | 'CREDITO';

export interface Venta {
  id: string;
  codigoEmpresa: string;
  codigoDocumento: string;
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
  tipoVenta: TipoVenta;
  plazoDias: number;
  fechaVencimiento?: string;
  anulado: boolean;
  createdAt?: string;
  detalles?: DetalleVenta[];
}
