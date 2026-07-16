import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { IMovimientoRepository } from '../../domain/ports/movimiento.repository.port';

@Injectable()
export class AnularMovimientoUseCase {
  constructor(private readonly repo: IMovimientoRepository) {}

  async execute(
    codigoEmpresa: string,
    movimientoId: string,
    codigoUsuario: string,
  ): Promise<void> {
    const existing = await this.repo.findById(movimientoId, codigoEmpresa);
    if (!existing) throw new NotFoundException('Movimiento no encontrado');
    if (existing.anulado) throw new BadRequestException('El movimiento ya fue anulado');

    await this.repo.anular(codigoEmpresa, movimientoId, codigoUsuario);
  }
}
