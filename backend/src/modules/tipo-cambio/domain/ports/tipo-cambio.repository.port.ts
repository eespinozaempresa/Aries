import { TipoCambio } from '../entities/tipo-cambio.entity';

export interface CreateTipoCambioData {
  codigoEmpresa: string;
  fecha: string;
  tipoCambio: number;
  usuarioRegistro: string;
}

export abstract class ITipoCambioRepository {
  abstract findByFecha(
    codigoEmpresa: string,
    fecha: string,
  ): Promise<TipoCambio | null>;
  abstract create(data: CreateTipoCambioData): Promise<TipoCambio>;
}
