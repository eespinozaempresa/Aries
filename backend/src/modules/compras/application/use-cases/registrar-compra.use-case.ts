import { Injectable, BadRequestException } from '@nestjs/common';
import { ICompraRepository, RegistrarCompraData } from '../../domain/ports/compra.repository.port';
import { Compra } from '../../domain/entities/compra.entity';

@Injectable()
export class RegistrarCompraUseCase {
  constructor(private readonly repo: ICompraRepository) {}

  async execute(codigoEmpresa: string, data: RegistrarCompraData): Promise<Compra> {
    if (!data.lineas.length) throw new BadRequestException('La compra debe tener al menos una línea');
    for (const l of data.lineas) {
      if (l.cantidad <= 0) throw new BadRequestException(`Cantidad inválida: ${l.codigoArticulo}`);
      if (l.precioUnitario < 0) throw new BadRequestException(`Precio inválido: ${l.codigoArticulo}`);
    }
    if (data.formaPago === 'CREDITO' && !data.plazoDias) {
      throw new BadRequestException('Crédito requiere plazo en días');
    }
    return this.repo.registrar(codigoEmpresa, data);
  }
}
