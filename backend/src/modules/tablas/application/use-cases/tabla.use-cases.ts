import { Injectable } from '@nestjs/common';
import { TablaBase } from '../../domain/entities/tabla-base.entity';
import { ITablaRepository, TablaFilter } from '../../domain/ports/tabla.repository.port';

@Injectable()
export class ListTablaUseCase<T extends TablaBase> {
  constructor(private readonly repo: ITablaRepository<T>) {}

  execute(filter: TablaFilter): Promise<T[]> {
    return this.repo.findAll(filter);
  }
}

@Injectable()
export class SaveTablaUseCase<T extends TablaBase> {
  constructor(private readonly repo: ITablaRepository<T>) {}

  execute(codigoEmpresa: string, data: Partial<T>, id?: string): Promise<T> {
    return this.repo.save(codigoEmpresa, data, id);
  }
}
