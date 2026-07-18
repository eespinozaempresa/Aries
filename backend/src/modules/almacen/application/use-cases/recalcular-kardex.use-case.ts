import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { SupabaseService } from '../../../../shared/infrastructure/supabase/supabase.service';

/**
 * Recalcula todo el kardex y stock de la empresa desde cero usando
 * la función SQL recalcular_kardex_empresa, que lee los movimientos
 * existentes sin crear nuevos registros en movimientos_almacen.
 */
@Injectable()
export class RecalcularKardexUseCase {
  constructor(private readonly supabase: SupabaseService) {}

  async execute(codigoEmpresa: string): Promise<{ procesados: number }> {
    const { data, error } = await this.supabase.db.rpc('recalcular_kardex_empresa', {
      p_empresa: codigoEmpresa,
    });
    if (error) throw new InternalServerErrorException(`Recálculo kardex: ${error.message}`);
    return { procesados: data as number };
  }
}
