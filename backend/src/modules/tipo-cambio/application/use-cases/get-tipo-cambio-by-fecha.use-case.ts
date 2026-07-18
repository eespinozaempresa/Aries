import { Injectable } from '@nestjs/common';
import { ITipoCambioRepository } from '../../domain/ports/tipo-cambio.repository.port';
import { TipoCambio } from '../../domain/entities/tipo-cambio.entity';

@Injectable()
export class GetTipoCambioByFechaUseCase {
  constructor(private readonly repo: ITipoCambioRepository) {}

  execute(codigoEmpresa: string, fecha: string): Promise<TipoCambio | null> {
    return this.repo.findByFecha(codigoEmpresa, fecha);
  }
}
