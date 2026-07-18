import { Injectable } from '@nestjs/common';
import { ITipoCambioRepository } from '../../domain/ports/tipo-cambio.repository.port';
import { TipoCambio } from '../../domain/entities/tipo-cambio.entity';

@Injectable()
export class UpdateTipoCambioUseCase {
  constructor(private readonly repo: ITipoCambioRepository) {}

  execute(codigoEmpresa: string, id: string, tipoCambio: number): Promise<TipoCambio> {
    return this.repo.update(codigoEmpresa, id, tipoCambio);
  }
}
