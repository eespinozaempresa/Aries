import { TipoCambio } from '../entities/tipo-cambio.entity';

export interface CreateTipoCambioData {
  codigoEmpresa: string;
  fecha: string;
  tipoCambio: number;
  usuarioRegistro: string;
}

export interface TipoCambioListResult {
  data: TipoCambio[];
  total: number;
  page: number;
  lastPage: number;
}

export abstract class ITipoCambioRepository {
  abstract findByFecha(codigoEmpresa: string, fecha: string): Promise<TipoCambio | null>;
  abstract findById(codigoEmpresa: string, id: string): Promise<TipoCambio | null>;
  abstract create(data: CreateTipoCambioData): Promise<TipoCambio>;
  abstract list(codigoEmpresa: string, page: number, limit: number): Promise<TipoCambioListResult>;
  abstract update(codigoEmpresa: string, id: string, tipoCambio: number): Promise<TipoCambio>;
  abstract delete(codigoEmpresa: string, id: string): Promise<void>;
}
