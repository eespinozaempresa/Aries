import { Injectable } from '@nestjs/common';
import { IAlmacenRepository } from '../../../domain/ports/almacen.repository.port';
import { Almacen } from '../../../domain/entities/almacen.entity';

@Injectable()
export class SearchAlmacenesUseCase {
  constructor(private readonly repo: IAlmacenRepository) {}

  execute(codigoEmpresa: string, q?: string, activo?: boolean): Promise<Almacen[]> {
    return this.repo.findAll({ codigoEmpresa, q, activo });
  }
}
