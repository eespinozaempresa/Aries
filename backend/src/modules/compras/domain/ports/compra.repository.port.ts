import { Compra, FormaPago } from '../entities/compra.entity';

export interface RegistrarCompraData {
  codigoDocumento: string;
  serie: string;
  fecha: string;
  formaPago: FormaPago;
  plazoDias?: number;
  fechaVencimiento?: string;
  observacion?: string;
  codigoAlmacen: string;
  codigoProveedor: string;
  codigoUsuario: string;
  moneda?: string;
  tipoCambio?: number;
  lineas: Array<{
    codigoArticulo: string;
    cantidad: number;
    precioUnitario: number;
    fechaVencimiento?: string;
  }>;
}

export interface CompraFilter {
  codigoEmpresa: string;
  codigoProveedor?: string;
  codigoAlmacen?: string;
  desde?: string;
  hasta?: string;
  soloAnuladas?: boolean;
  page?: number;
  limit?: number;
}

export interface CompraListResult {
  data: Compra[];
  total: number;
  page: number;
  lastPage: number;
}

export abstract class ICompraRepository {
  abstract registrar(codigoEmpresa: string, data: RegistrarCompraData): Promise<Compra>;
  abstract anular(codigoEmpresa: string, compraId: string, codigoUsuario: string): Promise<Compra>;
  abstract eliminar(codigoEmpresa: string, id: string): Promise<void>;
  abstract list(filter: CompraFilter): Promise<CompraListResult>;
  abstract findById(id: string, codigoEmpresa: string): Promise<Compra | null>;
}
