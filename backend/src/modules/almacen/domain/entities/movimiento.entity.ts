import { DetalleMovimiento } from './detalle-movimiento.entity';

export type TipoMovimiento = 'INGRESO' | 'SALIDA' | 'TRASLADO';

export interface Movimiento {
  id: string;
  codigoEmpresa: string;
  codigoDocumento: string;
  serie: string;
  numeroDocumento: string;
  fecha: string;
  tipo: TipoMovimiento;
  codigoAlmacenOrigen: string;
  codigoAlmacenDest?: string;
  descripcionAlmacenOrigen?: string;
  descripcionAlmacenDest?: string;
  observacion?: string;
  concepto?: string;
  codigoUsuario: string;
  total: number;
  anulado: boolean;
  createdAt?: string;
  detalles?: DetalleMovimiento[];
}
