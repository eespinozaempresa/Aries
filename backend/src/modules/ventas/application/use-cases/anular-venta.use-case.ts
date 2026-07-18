import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { IVentaRepository } from '../../domain/ports/venta.repository.port';
import { Venta } from '../../domain/entities/venta.entity';
import { RecalcularKardexUseCase } from '../../../almacen/application/use-cases/recalcular-kardex.use-case';

@Injectable()
export class AnularVentaUseCase {
  constructor(
    private readonly repo: IVentaRepository,
    private readonly recalcularKardex: RecalcularKardexUseCase,
  ) {}

  async execute(codigoEmpresa: string, ventaId: string, codigoUsuario: string): Promise<Venta> {
    const existing = await this.repo.findById(ventaId, codigoEmpresa);
    if (!existing) throw new NotFoundException('Venta no encontrada');
    if (existing.anulado) throw new BadRequestException('La venta ya fue anulada');
    const result = await this.repo.anular(codigoEmpresa, ventaId, codigoUsuario);
    await this.recalcularKardex.execute(codigoEmpresa);
    return result;
  }
}
