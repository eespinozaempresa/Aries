import { Injectable } from '@nestjs/common';
import { ITipoCambioRepository } from '../../domain/ports/tipo-cambio.repository.port';

@Injectable()
export class DeleteTipoCambioUseCase {
  constructor(private readonly repo: ITipoCambioRepository) {}

  execute(codigoEmpresa: string, id: string): Promise<void> {
    return this.repo.delete(codigoEmpresa, id);
  }
}
