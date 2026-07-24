export type TipoBloqueo = 'TEMPORAL' | 'INDEFINIDO';

export interface BloqueoActivo {
  tipo: TipoBloqueo;
  fechaFin: Date | null;
}

export abstract class IBloqueoRepository {
  abstract getActivo(usuarioId: string): Promise<BloqueoActivo | null>;
  abstract crear(usuarioId: string, tipo: TipoBloqueo, fechaFin: Date | null, motivo: string): Promise<void>;
  abstract contarTemporalesDesde(usuarioId: string, desde: Date): Promise<number>;
  abstract desbloquear(usuarioId: string, adminId: string): Promise<void>;
}
