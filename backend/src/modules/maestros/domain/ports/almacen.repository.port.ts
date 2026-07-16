import { Almacen } from '../entities/almacen.entity';

export interface AlmacenSearchParams {
  codigoEmpresa: string;
  q?: string;
  activo?: boolean;
}

export interface SaveAlmacenData {
  codigo: string;
  descripcion: string;
  abreviatura?: string;
  ubicacion?: string;
  tipo?: string;
  activo?: boolean;
}

export abstract class IAlmacenRepository {
  abstract findAll(params: AlmacenSearchParams): Promise<Almacen[]>;
  abstract findById(id: string, codigoEmpresa: string): Promise<Almacen | null>;
  abstract create(codigoEmpresa: string, data: SaveAlmacenData): Promise<Almacen>;
  abstract update(id: string, codigoEmpresa: string, data: Partial<SaveAlmacenData>): Promise<Almacen>;
}
