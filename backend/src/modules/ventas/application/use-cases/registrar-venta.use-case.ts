import { Injectable, BadRequestException } from '@nestjs/common';
import { IVentaRepository, RegistrarVentaData } from '../../domain/ports/venta.repository.port';
import { Venta } from '../../domain/entities/venta.entity';

@Injectable()
export class RegistrarVentaUseCase {
  constructor(private readonly repo: IVentaRepository) {}

  async execute(codigoEmpresa: string, data: RegistrarVentaData): Promise<Venta> {
    if (!data.lineas.length) throw new BadRequestException('La venta debe tener al menos una línea');
    for (const l of data.lineas) {
      if (l.cantidad <= 0) throw new BadRequestException(`Cantidad inválida: ${l.codigoArticulo}`);
      if (l.precioUnitario < 0) throw new BadRequestException(`Precio inválido: ${l.codigoArticulo}`);
    }
    if (data.tipoVenta === 'CREDITO' && !data.plazoDias) {
      throw new BadRequestException('Crédito requiere plazo en días');
    }
    return this.repo.registrar(codigoEmpresa, data);
  }
}
