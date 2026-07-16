import { Inject } from '@nestjs/common';
import { ICxPRepository, CxPFilter, RegistrarPagoData, RenovarCxPData } from '../../domain/ports/cxp.repository.port';

export class ListCxPUseCase {
  constructor(@Inject(ICxPRepository) private readonly repo: ICxPRepository) {}
  execute(filter: CxPFilter) { return this.repo.list(filter); }
}

export class FindCxPUseCase {
  constructor(@Inject(ICxPRepository) private readonly repo: ICxPRepository) {}
  execute(id: string, codigoEmpresa: string) { return this.repo.findById(id, codigoEmpresa); }
}

export class RegistrarPagoUseCase {
  constructor(@Inject(ICxPRepository) private readonly repo: ICxPRepository) {}
  execute(codigoEmpresa: string, data: RegistrarPagoData) { return this.repo.registrarPago(codigoEmpresa, data); }
}

export class GetPagosUseCase {
  constructor(@Inject(ICxPRepository) private readonly repo: ICxPRepository) {}
  execute(codigoEmpresa: string, cuentaPagarId: string) { return this.repo.getPagos(codigoEmpresa, cuentaPagarId); }
}

export class RenovarCxPUseCase {
  constructor(@Inject(ICxPRepository) private readonly repo: ICxPRepository) {}
  execute(codigoEmpresa: string, data: RenovarCxPData) { return this.repo.renovar(codigoEmpresa, data); }
}
