import { Proveedor } from '../entities/proveedor.entity';

export interface ProveedorSearchParams {
  codigoEmpresa: string;
  q?: string;
  activo?: boolean;
  page?: number;
  limit?: number;
}

export interface ProveedorListResult {
  data: Proveedor[];
  total: number;
  page: number;
  lastPage: number;
}

export interface SaveProveedorData {
  codigo: string;
  razonSocial: string;
  direccion?: string;
  rucDni?: string;
  telefono?: string;
  celular?: string;
  email?: string;
  activo?: boolean;
}

export abstract class IProveedorRepository {
  abstract search(params: ProveedorSearchParams): Promise<ProveedorListResult>;
  abstract findById(id: string, codigoEmpresa: string): Promise<Proveedor | null>;
  abstract create(codigoEmpresa: string, data: SaveProveedorData): Promise<Proveedor>;
  abstract update(id: string, codigoEmpresa: string, data: Partial<SaveProveedorData>): Promise<Proveedor>;
}
