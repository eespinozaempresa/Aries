import { ConflictException, InternalServerErrorException } from '@nestjs/common';
import { SupabaseClient } from '@supabase/supabase-js';

export interface UsageCheck {
  table: string;
  column: string;
  /** Valor contra el que se compara `column`: el código o el id del registro que se intenta eliminar. */
  matchOn?: 'codigo' | 'id';
}

/**
 * Lanza ConflictException si el registro (codigo/id) aparece referenciado
 * en alguna de las tablas indicadas. Se usa como validación explícita previa
 * al DELETE, en vez de depender únicamente del error 23503 de la FK
 * (necesario para relaciones sin FK real, o con ON DELETE SET NULL/CASCADE).
 */
export async function assertNotInUse(
  db: SupabaseClient,
  checks: readonly UsageCheck[],
  codigoEmpresa: string,
  match: { codigo?: string; id?: string },
): Promise<void> {
  for (const { table, column, matchOn = 'codigo' } of checks) {
    const value = matchOn === 'id' ? match.id : match.codigo;
    if (!value) continue;

    const { count, error } = await db
      .from(table)
      .select('id', { count: 'exact', head: true })
      .eq('codigo_empresa', codigoEmpresa)
      .eq(column, value);
    if (error) throw new InternalServerErrorException(error.message);
    if ((count ?? 0) > 0) {
      throw new ConflictException('No se puede eliminar: tiene operaciones asociadas');
    }
  }
}
