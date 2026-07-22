import { Injectable } from '@nestjs/common';
import { IFormulaRepository } from '../../../domain/ports/formula.repository.port';
import { Formula } from '../../../domain/entities/formula.entity';

@Injectable()
export class SearchFormulasUseCase {
  constructor(private readonly repo: IFormulaRepository) {}

  execute(codigoEmpresa: string, q?: string, activo?: boolean): Promise<Formula[]> {
    return this.repo.findAll({ codigoEmpresa, q, activo });
  }
}
