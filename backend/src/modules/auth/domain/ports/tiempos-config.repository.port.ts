export interface TiemposConfig {
  maxIntentosFallidos: number;
  ventanaIntentosMinutos: number;
  bloqueoTemporalMinutos: number;
  maxBloqueosTemporales: number;
  ventanaBloqueosMinutos: number;
}

export abstract class ITiemposConfigRepository {
  abstract getConfig(): Promise<TiemposConfig>;
}
