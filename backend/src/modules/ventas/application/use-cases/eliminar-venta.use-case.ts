import { Injectable } from '@nestjs/common';
import { IVentaRepository } from '../../domain/ports/venta.repository.port';

@Injectable()
export class EliminarVentaUseCase {
  constructor(private readonly repo: IVentaRepository) {}

  execute(codigoEmpresa: string, id: string): Promise<void> {
    return this.repo.eliminar(codigoEmpresa, id);
  }
}
