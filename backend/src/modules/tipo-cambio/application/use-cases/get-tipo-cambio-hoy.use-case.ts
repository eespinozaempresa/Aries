import { Injectable } from '@nestjs/common';
import { ITipoCambioRepository } from '../../domain/ports/tipo-cambio.repository.port';
import { TipoCambio } from '../../domain/entities/tipo-cambio.entity';

@Injectable()
export class GetTipoCambioHoyUseCase {
  constructor(private readonly repo: ITipoCambioRepository) {}

  execute(codigoEmpresa: string): Promise<TipoCambio | null> {
    const hoy = new Date().toISOString().slice(0, 10); // YYYY-MM-DD
    return this.repo.findByFecha(codigoEmpresa, hoy);
  }
}
