import { Injectable } from '@nestjs/common';
import { IMovimientoRepository, MovimientoFilter, MovimientoListResult } from '../../domain/ports/movimiento.repository.port';
import { TipoMovimiento } from '../../domain/entities/movimiento.entity';

@Injectable()
export class ListMovimientosUseCase {
  constructor(private readonly repo: IMovimientoRepository) {}

  execute(
    codigoEmpresa: string,
    tipo?: TipoMovimiento,
    codigoAlmacen?: string,
    desde?: string,
    hasta?: string,
    page = 1,
    limit = 20,
  ): Promise<MovimientoListResult> {
    return this.repo.list({ codigoEmpresa, tipo, codigoAlmacen, desde, hasta, page, limit });
  }
}
