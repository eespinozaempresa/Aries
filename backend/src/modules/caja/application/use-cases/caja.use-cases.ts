import { Inject } from '@nestjs/common';
import {
  ICajaRepository, CajaFilter,
  AbrirCajaData, CerrarCajaData, RegistrarMovCajaData, ActualizarMovCajaData,
} from '../../domain/ports/caja.repository.port';

export class ListCajaUseCase {
  constructor(@Inject(ICajaRepository) private readonly repo: ICajaRepository) {}
  execute(filter: CajaFilter) { return this.repo.list(filter); }
}

export class FindSesionUseCase {
  constructor(@Inject(ICajaRepository) private readonly repo: ICajaRepository) {}
  execute(id: string, codigoEmpresa: string) { return this.repo.findById(id, codigoEmpresa); }
}

export class AbrirCajaUseCase {
  constructor(@Inject(ICajaRepository) private readonly repo: ICajaRepository) {}
  execute(codigoEmpresa: string, data: AbrirCajaData) { return this.repo.abrir(codigoEmpresa, data); }
}

export class CerrarCajaUseCase {
  constructor(@Inject(ICajaRepository) private readonly repo: ICajaRepository) {}
  execute(codigoEmpresa: string, data: CerrarCajaData) { return this.repo.cerrar(codigoEmpresa, data); }
}

export class RegistrarMovCajaUseCase {
  constructor(@Inject(ICajaRepository) private readonly repo: ICajaRepository) {}
  execute(codigoEmpresa: string, data: RegistrarMovCajaData) { return this.repo.registrarMovimiento(codigoEmpresa, data); }
}

export class ReporteCajaUseCase {
  constructor(@Inject(ICajaRepository) private readonly repo: ICajaRepository) {}
  execute(codigoEmpresa: string, sesionCajaId: string) { return this.repo.reporte(codigoEmpresa, sesionCajaId); }
}

export class EliminarMovCajaUseCase {
  constructor(@Inject(ICajaRepository) private readonly repo: ICajaRepository) {}
  execute(codigoEmpresa: string, movimientoId: string) { return this.repo.eliminarMovimiento(codigoEmpresa, movimientoId); }
}

export class ActualizarMovCajaUseCase {
  constructor(@Inject(ICajaRepository) private readonly repo: ICajaRepository) {}
  execute(codigoEmpresa: string, movimientoId: string, data: ActualizarMovCajaData) {
    return this.repo.actualizarMovimiento(codigoEmpresa, movimientoId, data);
  }
}
