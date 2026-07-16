import { Injectable } from '@nestjs/common';
import { IVentaRepository, VentaFilter, VentaListResult } from '../../domain/ports/venta.repository.port';

@Injectable()
export class ListVentasUseCase {
  constructor(private readonly repo: IVentaRepository) {}

  execute(filter: VentaFilter): Promise<VentaListResult> {
    return this.repo.list(filter);
  }
}
