import { Injectable } from '@nestjs/common';
import { IProveedorRepository, ProveedorListResult } from '../../../domain/ports/proveedor.repository.port';

@Injectable()
export class SearchProveedoresUseCase {
  constructor(private readonly repo: IProveedorRepository) {}

  execute(
    codigoEmpresa: string,
    q?: string,
    activo?: boolean,
    page = 1,
    limit = 20,
  ): Promise<ProveedorListResult> {
    return this.repo.search({ codigoEmpresa, q, activo, page, limit });
  }
}
