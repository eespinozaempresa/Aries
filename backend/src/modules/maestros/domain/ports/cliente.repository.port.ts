import { Cliente } from '../entities/cliente.entity';

export interface ClienteSearchParams {
  codigoEmpresa: string;
  q?: string;
  activo?: boolean;
  page?: number;
  limit?: number;
}

export interface ClienteListResult {
  data: Cliente[];
  total: number;
  page: number;
  lastPage: number;
}

export interface SaveClienteData {
  codigo: string;
  razonSocial: string;
  direccion?: string;
  rucDni?: string;
  telefono?: string;
  celular?: string;
  email?: string;
  activo?: boolean;
  idTipoLista?: string;
}

export abstract class IClienteRepository {
  abstract search(params: ClienteSearchParams): Promise<ClienteListResult>;
  abstract findById(id: string, codigoEmpresa: string): Promise<Cliente | null>;
  abstract create(codigoEmpresa: string, data: SaveClienteData): Promise<Cliente>;
  abstract update(id: string, codigoEmpresa: string, data: Partial<SaveClienteData>): Promise<Cliente>;
}
