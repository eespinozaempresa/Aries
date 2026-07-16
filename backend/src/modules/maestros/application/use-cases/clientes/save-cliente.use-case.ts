import { Injectable, NotFoundException } from '@nestjs/common';
import { IClienteRepository, SaveClienteData } from '../../../domain/ports/cliente.repository.port';
import { Cliente } from '../../../domain/entities/cliente.entity';

@Injectable()
export class SaveClienteUseCase {
  constructor(private readonly repo: IClienteRepository) {}

  async execute(
    codigoEmpresa: string,
    data: SaveClienteData,
    id?: string,
  ): Promise<Cliente> {
    if (id) {
      const existing = await this.repo.findById(id, codigoEmpresa);
      if (!existing) throw new NotFoundException('Cliente no encontrado');
      return this.repo.update(id, codigoEmpresa, data);
    }
    return this.repo.create(codigoEmpresa, data);
  }
}
