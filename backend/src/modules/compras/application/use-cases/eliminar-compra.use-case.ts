import { Injectable } from '@nestjs/common';
import { ICompraRepository } from '../../domain/ports/compra.repository.port';

@Injectable()
export class EliminarCompraUseCase {
  constructor(private readonly repo: ICompraRepository) {}

  execute(codigoEmpresa: string, id: string): Promise<void> {
    return this.repo.eliminar(codigoEmpresa, id);
  }
}
