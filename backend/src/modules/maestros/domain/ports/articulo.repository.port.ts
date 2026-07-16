import { Articulo } from '../entities/articulo.entity';

export interface ArticuloSearchParams {
  codigoEmpresa: string;
  q?: string;
  activo?: boolean;
  page?: number;
  limit?: number;
}

export interface ArticuloListResult {
  data: Articulo[];
  total: number;
  page: number;
  lastPage: number;
}

export interface SaveArticuloData {
  codigo: string;
  descripcion: string;
  codigoLinea?: string;
  codigoMedida?: string;
  codigoMarca?: string;
  precioCompraBase?: number;
  igvCompra?: number;
  precioCompra?: number;
  utilidadPct?: number;
  precioVentaBase?: number;
  igvVenta?: number;
  precioVenta?: number;
  fechaRegistro?: string;
  fechaVencimiento?: string;
  stockMinimo?: number;
  stockMaximo?: number;
  codigoBarras?: string;
  activo?: boolean;
}

export abstract class IArticuloRepository {
  abstract search(params: ArticuloSearchParams): Promise<ArticuloListResult>;
  abstract findById(id: string, codigoEmpresa: string): Promise<Articulo | null>;
  abstract findByCodigo(codigo: string, codigoEmpresa: string): Promise<Articulo | null>;
  abstract create(codigoEmpresa: string, data: SaveArticuloData): Promise<Articulo>;
  abstract update(id: string, codigoEmpresa: string, data: Partial<SaveArticuloData>): Promise<Articulo>;
}
