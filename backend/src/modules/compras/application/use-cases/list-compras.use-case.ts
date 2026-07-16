import { Injectable } from '@nestjs/common';
import { ICompraRepository, CompraFilter, CompraListResult } from '../../domain/ports/compra.repository.port';

@Injectable()
export class ListComprasUseCase {
  constructor(private readonly repo: ICompraRepository) {}

  execute(filter: CompraFilter): Promise<CompraListResult> {
    return this.repo.list(filter);
  }
}
