import { Injectable } from '@nestjs/common';
import { ITipoCambioRepository, TipoCambioListResult } from '../../domain/ports/tipo-cambio.repository.port';

@Injectable()
export class ListTipoCambioUseCase {
  constructor(private readonly repo: ITipoCambioRepository) {}

  execute(codigoEmpresa: string, page = 1, limit = 20): Promise<TipoCambioListResult> {
    return this.repo.list(codigoEmpresa, page, Math.min(limit, 100));
  }
}
