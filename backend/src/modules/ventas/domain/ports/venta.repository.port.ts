import { Venta, TipoVenta } from '../entities/venta.entity';

export interface RegistrarVentaData {
  codigoDocumento: string;
  serie: string;
  fecha: string;
  observacion?: string;
  codigoAlmacen: string;
  codigoCliente: string;
  codigoUsuario: string;
  tipoVenta: TipoVenta;
  plazoDias?: number;
  fechaVencimiento?: string;
  moneda?: string;
  tipoCambio?: number;
  lineas: Array<{
    codigoArticulo: string;
    cantidad: number;
    precioUnitario: number;
    descuentoPct?: number;
  }>;
}

export interface VentaFilter {
  codigoEmpresa: string;
  codigoCliente?: string;
  codigoAlmacen?: string;
  desde?: string;
  hasta?: string;
  soloAnuladas?: boolean;
  page?: number;
  limit?: number;
}

export interface VentaListResult {
  data: Venta[];
  total: number;
  page: number;
  lastPage: number;
}

export interface ReporteVentasFilter {
  tipo: 'general' | 'detallado';
  desde?: string;
  hasta?: string;
  almacen?: string;
  tipoVenta?: string;
}

export interface ReporteGeneralFilter {
  desde?: string;
  hasta?: string;
  almacen?: string;
  cliente?: string;
  articulo?: string;
  usuario?: string;
}

export abstract class IVentaRepository {
  abstract registrar(codigoEmpresa: string, data: RegistrarVentaData): Promise<Venta>;
  abstract anular(codigoEmpresa: string, ventaId: string, codigoUsuario: string): Promise<Venta>;
  abstract eliminar(codigoEmpresa: string, id: string): Promise<void>;
  abstract list(filter: VentaFilter): Promise<VentaListResult>;
  abstract findById(id: string, codigoEmpresa: string): Promise<Venta | null>;
  abstract reporteVentas(codigoEmpresa: string, params: ReporteVentasFilter): Promise<unknown[]>;
  abstract reporteGeneral(codigoEmpresa: string, params: ReporteGeneralFilter): Promise<unknown[]>;
}
