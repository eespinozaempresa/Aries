import { Injectable } from '@nestjs/common';
import { SupabaseService } from '../../../../shared/infrastructure/supabase/supabase.service';
import { BloqueoActivo, IBloqueoRepository, TipoBloqueo } from '../../domain/ports/bloqueo.repository.port';

@Injectable()
export class SupabaseBloqueoRepository implements IBloqueoRepository {
  constructor(private readonly supabase: SupabaseService) {}

  async getActivo(usuarioId: string): Promise<BloqueoActivo | null> {
    const nowIso = new Date().toISOString();
    const { data } = await this.supabase.db
      .from('usuario_bloqueos')
      .select('tipo, fecha_fin')
      .eq('usuario_id', usuarioId)
      .is('desbloqueado_en', null)
      .or(`fecha_fin.is.null,fecha_fin.gt.${nowIso}`)
      .order('fecha_inicio', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (!data) return null;
    return {
      tipo: data.tipo as TipoBloqueo,
      fechaFin: data.fecha_fin ? new Date(data.fecha_fin) : null,
    };
  }

  async crear(usuarioId: string, tipo: TipoBloqueo, fechaFin: Date | null, motivo: string): Promise<void> {
    await this.supabase.db.from('usuario_bloqueos').insert({
      usuario_id: usuarioId,
      tipo,
      motivo,
      fecha_fin: fechaFin ? fechaFin.toISOString() : null,
    });
  }

  async contarTemporalesDesde(usuarioId: string, desde: Date): Promise<number> {
    const { count } = await this.supabase.db
      .from('usuario_bloqueos')
      .select('id', { count: 'exact', head: true })
      .eq('usuario_id', usuarioId)
      .eq('tipo', 'TEMPORAL')
      .gte('fecha_inicio', desde.toISOString());
    return count ?? 0;
  }

  async desbloquear(usuarioId: string, adminId: string): Promise<void> {
    await this.supabase.db
      .from('usuario_bloqueos')
      .update({ desbloqueado_en: new Date().toISOString(), desbloqueado_por: adminId })
      .eq('usuario_id', usuarioId)
      .is('desbloqueado_en', null);
  }
}
