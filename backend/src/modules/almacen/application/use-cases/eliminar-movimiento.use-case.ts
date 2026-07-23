import { Injectable } from '@nestjs/common';
import { IMovimientoRepository } from '../../domain/ports/movimiento.repository.port';

@Injectable()
export class EliminarMovimientoUseCase {
  constructor(private readonly repo: IMovimientoRepository) {}

  execute(codigoEmpresa: string, id: string): Promise<void> {
    return this.repo.eliminar(codigoEmpresa, id);
  }
}
