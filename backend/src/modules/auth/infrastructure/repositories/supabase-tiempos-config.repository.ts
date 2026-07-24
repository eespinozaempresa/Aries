import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { SupabaseService } from '../../../../shared/infrastructure/supabase/supabase.service';
import { ITiemposConfigRepository, TiemposConfig } from '../../domain/ports/tiempos-config.repository.port';

@Injectable()
export class SupabaseTiemposConfigRepository implements ITiemposConfigRepository {
  constructor(private readonly supabase: SupabaseService) {}

  async getConfig(): Promise<TiemposConfig> {
    const { data, error } = await this.supabase.db
      .from('tiempos')
      .select(
        'max_intentos_fallidos, ventana_intentos_minutos, bloqueo_temporal_minutos, max_bloqueos_temporales, ventana_bloqueos_minutos',
      )
      .limit(1)
      .maybeSingle();
    if (error) throw new InternalServerErrorException(error.message);

    return {
      maxIntentosFallidos: data?.max_intentos_fallidos ?? 5,
      ventanaIntentosMinutos: data?.ventana_intentos_minutos ?? 15,
      bloqueoTemporalMinutos: data?.bloqueo_temporal_minutos ?? 30,
      maxBloqueosTemporales: data?.max_bloqueos_temporales ?? 3,
      ventanaBloqueosMinutos: data?.ventana_bloqueos_minutos ?? 1440,
    };
  }
}
