import { Injectable } from '@nestjs/common';
import { IArticuloRepository, ArticuloListResult } from '../../../domain/ports/articulo.repository.port';

@Injectable()
export class SearchArticulosUseCase {
  constructor(private readonly repo: IArticuloRepository) {}

  execute(
    codigoEmpresa: string,
    q?: string,
    activo?: boolean,
    page = 1,
    limit = 20,
  ): Promise<ArticuloListResult> {
    return this.repo.search({ codigoEmpresa, q, activo, page, limit });
  }
}
