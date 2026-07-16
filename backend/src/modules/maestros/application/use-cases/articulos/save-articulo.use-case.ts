import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { IArticuloRepository, SaveArticuloData } from '../../../domain/ports/articulo.repository.port';
import { Articulo } from '../../../domain/entities/articulo.entity';

@Injectable()
export class SaveArticuloUseCase {
  constructor(private readonly repo: IArticuloRepository) {}

  async execute(
    codigoEmpresa: string,
    data: SaveArticuloData,
    id?: string,
  ): Promise<Articulo> {
    if (id) {
      const existing = await this.repo.findById(id, codigoEmpresa);
      if (!existing) throw new NotFoundException('Artículo no encontrado');
      return this.repo.update(id, codigoEmpresa, data);
    }

    const duplicate = await this.repo.findByCodigo(data.codigo, codigoEmpresa);
    if (duplicate) throw new ConflictException(`Código ${data.codigo} ya existe`);
    return this.repo.create(codigoEmpresa, data);
  }
}
