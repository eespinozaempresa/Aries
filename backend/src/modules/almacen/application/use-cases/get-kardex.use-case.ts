import { Injectable } from '@nestjs/common';
import { IKardexRepository } from '../../domain/ports/kardex.repository.port';
import { KardexItem } from '../../domain/entities/kardex-item.entity';

@Injectable()
export class GetKardexUseCase {
  constructor(private readonly repo: IKardexRepository) {}

  execute(
    codigoEmpresa: string,
    codigoAlmacen: string,
    codigoArticulo: string,
    desde?: string,
    hasta?: string,
  ): Promise<KardexItem[]> {
    return this.repo.query({ codigoEmpresa, codigoAlmacen, codigoArticulo, desde, hasta });
  }
}
