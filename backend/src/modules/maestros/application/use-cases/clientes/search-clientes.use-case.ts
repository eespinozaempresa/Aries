import { Injectable } from '@nestjs/common';
import { IClienteRepository, ClienteListResult } from '../../../domain/ports/cliente.repository.port';

@Injectable()
export class SearchClientesUseCase {
  constructor(private readonly repo: IClienteRepository) {}

  execute(
    codigoEmpresa: string,
    q?: string,
    activo?: boolean,
    page = 1,
    limit = 20,
  ): Promise<ClienteListResult> {
    return this.repo.search({ codigoEmpresa, q, activo, page, limit });
  }
}
