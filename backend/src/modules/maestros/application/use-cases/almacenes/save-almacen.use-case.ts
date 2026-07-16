import { Injectable, NotFoundException } from '@nestjs/common';
import { IAlmacenRepository, SaveAlmacenData } from '../../../domain/ports/almacen.repository.port';
import { Almacen } from '../../../domain/entities/almacen.entity';

@Injectable()
export class SaveAlmacenUseCase {
  constructor(private readonly repo: IAlmacenRepository) {}

  async execute(
    codigoEmpresa: string,
    data: SaveAlmacenData,
    id?: string,
  ): Promise<Almacen> {
    if (id) {
      const existing = await this.repo.findById(id, codigoEmpresa);
      if (!existing) throw new NotFoundException('Almacén no encontrado');
      return this.repo.update(id, codigoEmpresa, data);
    }
    return this.repo.create(codigoEmpresa, data);
  }
}
