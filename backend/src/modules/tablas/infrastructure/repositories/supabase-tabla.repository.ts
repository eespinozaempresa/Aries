import { Injectable, InternalServerErrorException, ConflictException } from '@nestjs/common';
import { SupabaseService } from '../../../../shared/infrastructure/supabase/supabase.service';
import { TablaBase, Documento } from '../../domain/entities/tabla-base.entity';
import { ITablaRepository, TablaFilter } from '../../domain/ports/tabla.repository.port';

function makeRepo<T extends TablaBase>(tableName: string, fromRow: (r: Record<string, unknown>) => T) {
  @Injectable()
  class SupabaseTablaRepo extends ITablaRepository<T> {
    constructor(readonly supabase: SupabaseService) { super(); }

    async findAll(f: TablaFilter): Promise<T[]> {
      let q = this.supabase.db.from(tableName).select('*').eq('codigo_empresa', f.codigoEmpresa);
      if (f.activo !== undefined) q = q.eq('activo', f.activo);
      if (f.q) q = q.or(`descripcion.ilike.%${f.q}%,codigo.ilike.%${f.q}%`);
      q = q.order('codigo', { ascending: true });
      const { data, error } = await q;
      if (error) throw new InternalServerErrorException(error.message);
      return (data ?? []).map(fromRow);
    }

    async findByCodigo(codigoEmpresa: string, codigo: string): Promise<T | null> {
      const { data, error } = await this.supabase.db
        .from(tableName).select('*')
        .eq('codigo_empresa', codigoEmpresa).eq('codigo', codigo).maybeSingle();
      if (error) throw new InternalServerErrorException(error.message);
      return data ? fromRow(data as Record<string, unknown>) : null;
    }

    async save(codigoEmpresa: string, data: Partial<T>, id?: string): Promise<T> {
      const row = toRow(data);
      if (id) {
        const { data: updated, error } = await this.supabase.db
          .from(tableName).update(row).eq('id', id).eq('codigo_empresa', codigoEmpresa).select().single();
        if (error) throw new InternalServerErrorException(error.message);
        return fromRow(updated as Record<string, unknown>);
      }
      const { data: inserted, error } = await this.supabase.db
        .from(tableName).insert({ ...row, codigo_empresa: codigoEmpresa }).select().single();
      if (error) {
        if (error.code === '23505') throw new ConflictException('Código duplicado');
        throw new InternalServerErrorException(error.message);
      }
      return fromRow(inserted as Record<string, unknown>);
    }
  }
  return SupabaseTablaRepo;
}

function toRow(d: Record<string, unknown>): Record<string, unknown> {
  const map: Record<string, string> = {
    codigoEmpresa: 'codigo_empresa', descripcion: 'descripcion', codigo: 'codigo',
    activo: 'activo', abreviatura: 'abreviatura', serie: 'serie',
    numeroSiguiente: 'numero_siguiente', aplicaIgv: 'aplica_igv', tipo: 'tipo',
  };
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(d)) {
    const col = map[k];
    if (col) out[col] = v;
  }
  return out;
}

const base = (r: Record<string, unknown>) => ({
  id: r.id as string,
  codigoEmpresa: r.codigo_empresa as string,
  codigo: r.codigo as string,
  descripcion: r.descripcion as string,
  activo: r.activo as boolean,
});

export const SupabaseLineaRepo    = makeRepo('lineas',    (r) => ({ ...base(r) }));
export const SupabaseMedidaRepo   = makeRepo('medidas',   (r) => ({ ...base(r) }));
export const SupabaseBancoRepo    = makeRepo('bancos',    (r) => ({ ...base(r) }));
export const SupabaseMarcaRepo    = makeRepo('marcas',    (r) => ({ ...base(r) }));
export const SupabaseDocumentoRepo = makeRepo<Documento>('documentos', (r) => ({
  ...base(r),
  abreviatura:     r.abreviatura as string | undefined,
  serie:           (r.serie as string) ?? '0001',
  numeroSiguiente: Number(r.numero_siguiente),
  aplicaIgv:       r.aplica_igv as boolean,
  tipo:            r.tipo as string | undefined,
}));
