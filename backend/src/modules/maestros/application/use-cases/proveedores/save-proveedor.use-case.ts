import { Injectable, NotFoundException } from '@nestjs/common';
import { IProveedorRepository, SaveProveedorData } from '../../../domain/ports/proveedor.repository.port';
import { Proveedor } from '../../../domain/entities/proveedor.entity';

@Injectable()
export class SaveProveedorUseCase {
  constructor(private readonly repo: IProveedorRepository) {}

  async execute(
    codigoEmpresa: string,
    data: SaveProveedorData,
    id?: string,
  ): Promise<Proveedor> {
    if (id) {
      const existing = await this.repo.findById(id, codigoEmpresa);
      if (!existing) throw new NotFoundException('Proveedor no encontrado');
      return this.repo.update(id, codigoEmpresa, data);
    }
    return this.repo.create(codigoEmpresa, data);
  }
}
