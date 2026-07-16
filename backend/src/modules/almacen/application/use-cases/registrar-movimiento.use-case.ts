import { Injectable, BadRequestException } from '@nestjs/common';
import { IMovimientoRepository, RegistrarMovimientoData } from '../../domain/ports/movimiento.repository.port';
import { Movimiento } from '../../domain/entities/movimiento.entity';

@Injectable()
export class RegistrarMovimientoUseCase {
  constructor(private readonly repo: IMovimientoRepository) {}

  async execute(
    codigoEmpresa: string,
    data: RegistrarMovimientoData,
  ): Promise<Movimiento> {
    if (data.lineas.length === 0) {
      throw new BadRequestException('El movimiento debe tener al menos una línea');
    }
    if (data.tipo === 'TRASLADO' && !data.codigoAlmacenDest) {
      throw new BadRequestException('TRASLADO requiere almacén destino');
    }
    if (data.tipo === 'TRASLADO' && data.codigoAlmacenDest === data.codigoAlmacenOrigen) {
      throw new BadRequestException('El almacén destino debe ser diferente al origen');
    }
    for (const l of data.lineas) {
      if (l.cantidad <= 0) {
        throw new BadRequestException(`Cantidad inválida para artículo ${l.codigoArticulo}`);
      }
    }

    const id = await this.repo.registrar(codigoEmpresa, data);
    const movimiento = await this.repo.findById(id, codigoEmpresa);
    return movimiento!;
  }
}
