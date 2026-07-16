import { Injectable, ConflictException } from '@nestjs/common';
import { ITipoCambioRepository } from '../../domain/ports/tipo-cambio.repository.port';
import { TipoCambio } from '../../domain/entities/tipo-cambio.entity';

@Injectable()
export class RegistrarTipoCambioUseCase {
  constructor(private readonly repo: ITipoCambioRepository) {}

  async execute(
    codigoEmpresa: string,
    tipoCambio: number,
    usuarioRegistro: string,
  ): Promise<TipoCambio> {
    const hoy = new Date().toISOString().slice(0, 10);
    const existing = await this.repo.findByFecha(codigoEmpresa, hoy);
    if (existing) {
      throw new ConflictException('El tipo de cambio de hoy ya fue registrado');
    }
    return this.repo.create({
      codigoEmpresa,
      fecha: hoy,
      tipoCambio,
      usuarioRegistro,
    });
  }
}
