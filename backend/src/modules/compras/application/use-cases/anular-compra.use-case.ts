import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { ICompraRepository } from '../../domain/ports/compra.repository.port';
import { Compra } from '../../domain/entities/compra.entity';
import { RecalcularKardexUseCase } from '../../../almacen/application/use-cases/recalcular-kardex.use-case';

@Injectable()
export class AnularCompraUseCase {
  constructor(
    private readonly repo: ICompraRepository,
    private readonly recalcularKardex: RecalcularKardexUseCase,
  ) {}

  async execute(codigoEmpresa: string, compraId: string, codigoUsuario: string): Promise<Compra> {
    const existing = await this.repo.findById(compraId, codigoEmpresa);
    if (!existing) throw new NotFoundException('Compra no encontrada');
    if (existing.anulado) throw new BadRequestException('La compra ya fue anulada');
    const result = await this.repo.anular(codigoEmpresa, compraId, codigoUsuario);
    await this.recalcularKardex.execute(codigoEmpresa);
    return result;
  }
}
