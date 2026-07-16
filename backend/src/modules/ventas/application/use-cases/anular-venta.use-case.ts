import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { IVentaRepository } from '../../domain/ports/venta.repository.port';
import { Venta } from '../../domain/entities/venta.entity';

@Injectable()
export class AnularVentaUseCase {
  constructor(private readonly repo: IVentaRepository) {}

  async execute(codigoEmpresa: string, ventaId: string, codigoUsuario: string): Promise<Venta> {
    const existing = await this.repo.findById(ventaId, codigoEmpresa);
    if (!existing) throw new NotFoundException('Venta no encontrada');
    if (existing.anulado) throw new BadRequestException('La venta ya fue anulada');
    return this.repo.anular(codigoEmpresa, ventaId, codigoUsuario);
  }
}
