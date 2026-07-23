import { Inject } from '@nestjs/common';
import { ICxCRepository, CxCFilter, RegistrarCobroData, RenovarCxCData } from '../../domain/ports/cxc.repository.port';

export class ListCxCUseCase {
  constructor(@Inject(ICxCRepository) private readonly repo: ICxCRepository) {}
  execute(filter: CxCFilter) { return this.repo.list(filter); }
}

export class FindCxCUseCase {
  constructor(@Inject(ICxCRepository) private readonly repo: ICxCRepository) {}
  execute(id: string, codigoEmpresa: string) { return this.repo.findById(id, codigoEmpresa); }
}

export class RegistrarCobroUseCase {
  constructor(@Inject(ICxCRepository) private readonly repo: ICxCRepository) {}
  execute(codigoEmpresa: string, data: RegistrarCobroData) { return this.repo.registrarCobro(codigoEmpresa, data); }
}

export class GetCobrosUseCase {
  constructor(@Inject(ICxCRepository) private readonly repo: ICxCRepository) {}
  execute(codigoEmpresa: string, cuentaCobrarId: string) { return this.repo.getCobros(codigoEmpresa, cuentaCobrarId); }
}

export class EliminarCobroUseCase {
  constructor(@Inject(ICxCRepository) private readonly repo: ICxCRepository) {}
  execute(codigoEmpresa: string, cobroId: string) { return this.repo.eliminarCobro(codigoEmpresa, cobroId); }
}

export class RenovarCxCUseCase {
  constructor(@Inject(ICxCRepository) private readonly repo: ICxCRepository) {}
  execute(codigoEmpresa: string, data: RenovarCxCData) { return this.repo.renovar(codigoEmpresa, data); }
}
