import { Injectable, InternalServerErrorException, ConflictException, NotFoundException } from '@nestjs/common';
import { SupabaseService } from '../../../../shared/infrastructure/supabase/supabase.service';
import {
  IFormulaRepository,
  FormulaSearchParams,
  SaveFormulaData,
} from '../../domain/ports/formula.repository.port';
import { Formula, DetalleFormula } from '../../domain/entities/formula.entity';

@Injectable()
export class SupabaseFormulaRepository implements IFormulaRepository {
  constructor(private readonly supabase: SupabaseService) {}

  async findAll(p: FormulaSearchParams): Promise<Formula[]> {
    let query = this.supabase.db
      .from('formulas')
      .select('*, articulos(descripcion)')
      .eq('codigo_empresa', p.codigoEmpresa)
      .order('codigo_articulo', { ascending: true });

    if (p.activo !== undefined) query = query.eq('activo', p.activo);

    const { data, error } = await query;
    if (error) throw new InternalServerErrorException(error.message);

    let rows = data ?? [];
    if (p.q) {
      const q = p.q.toLowerCase();
      rows = rows.filter((r: any) =>
        (r.codigo_articulo as string).toLowerCase().includes(q) ||
        ((r.articulos?.descripcion as string) ?? '').toLowerCase().includes(q));
    }
    return rows.map((r: any) => this.toEntity(r, []));
  }

  async findById(id: string, codigoEmpresa: string): Promise<Formula | null> {
    const { data, error } = await this.supabase.db
      .from('formulas')
      .select('*, articulos(descripcion), detalle_formulas(*, articulos(descripcion))')
      .eq('id', id)
      .eq('codigo_empresa', codigoEmpresa)
      .maybeSingle();
    if (error) throw new InternalServerErrorException(error.message);
    if (!data) return null;

    const detalle = ((data as any).detalle_formulas ?? [])
      .map((r: any) => this.toDetalle(r))
      .sort((a: DetalleFormula, b: DetalleFormula) => a.orden - b.orden);
    return this.toEntity(data, detalle);
  }

  async findActivasByArticulos(
    codigoEmpresa: string,
    codigosArticulo: string[],
  ): Promise<Map<string, DetalleFormula[]>> {
    const map = new Map<string, DetalleFormula[]>();
    if (!codigosArticulo.length) return map;

    const { data, error } = await this.supabase.db
      .from('formulas')
      .select('codigo_articulo, detalle_formulas(codigo_articulo, cantidad, orden)')
      .eq('codigo_empresa', codigoEmpresa)
      .eq('activo', true)
      .in('codigo_articulo', codigosArticulo);
    if (error) throw new InternalServerErrorException(error.message);

    for (const row of data ?? []) {
      const detalle: DetalleFormula[] = ((row as any).detalle_formulas ?? []).map((d: any) => ({
        codigoEmpresa,
        codigoArticulo: d.codigo_articulo as string,
        cantidad: Number(d.cantidad),
        orden: Number(d.orden ?? 0),
      }));
      if (detalle.length) map.set((row as any).codigo_articulo as string, detalle);
    }
    return map;
  }

  async create(codigoEmpresa: string, d: SaveFormulaData): Promise<Formula> {
    const activo = d.activo ?? true;
    const codigoArticulo = d.codigoArticulo.toUpperCase();
    const { data, error } = await this.supabase.db
      .from('formulas')
      .insert({
        codigo_empresa: codigoEmpresa,
        codigo_articulo: codigoArticulo,
        observacion: d.observacion ?? null,
        activo,
      })
      .select()
      .single();
    if (error) {
      if (error.code === '23505') {
        throw new ConflictException(`Ya existe una fórmula para el artículo ${d.codigoArticulo}`);
      }
      throw new InternalServerErrorException(error.message);
    }

    await this.replaceDetalle(data.id, codigoEmpresa, d.detalle);
    await this.syncConFormula(codigoEmpresa, codigoArticulo, activo);
    return (await this.findById(data.id, codigoEmpresa)) as Formula;
  }

  async update(id: string, codigoEmpresa: string, d: SaveFormulaData): Promise<Formula> {
    const activo = d.activo ?? true;
    const codigoArticulo = d.codigoArticulo.toUpperCase();
    const { error } = await this.supabase.db
      .from('formulas')
      .update({
        codigo_articulo: codigoArticulo,
        observacion: d.observacion ?? null,
        activo,
      })
      .eq('id', id)
      .eq('codigo_empresa', codigoEmpresa);
    if (error) {
      if (error.code === '23505') {
        throw new ConflictException(`Ya existe una fórmula para el artículo ${d.codigoArticulo}`);
      }
      throw new InternalServerErrorException(error.message);
    }

    await this.replaceDetalle(id, codigoEmpresa, d.detalle);
    await this.syncConFormula(codigoEmpresa, codigoArticulo, activo);
    return (await this.findById(id, codigoEmpresa)) as Formula;
  }

  async toggleActivo(codigoEmpresa: string, id: string): Promise<Formula> {
    const { data: current, error: findErr } = await this.supabase.db
      .from('formulas')
      .select('activo, codigo_articulo')
      .eq('id', id)
      .eq('codigo_empresa', codigoEmpresa)
      .maybeSingle();
    if (findErr) throw new InternalServerErrorException(findErr.message);
    if (!current) throw new NotFoundException('Fórmula no encontrada');

    const nuevoActivo = !current.activo;
    const { error } = await this.supabase.db
      .from('formulas')
      .update({ activo: nuevoActivo })
      .eq('id', id)
      .eq('codigo_empresa', codigoEmpresa);
    if (error) throw new InternalServerErrorException(error.message);

    await this.syncConFormula(codigoEmpresa, current.codigo_articulo as string, nuevoActivo);
    return (await this.findById(id, codigoEmpresa)) as Formula;
  }

  private async syncConFormula(codigoEmpresa: string, codigoArticulo: string, conFormula: boolean): Promise<void> {
    const { error } = await this.supabase.db
      .from('articulos')
      .update({ con_formula: conFormula })
      .eq('codigo_empresa', codigoEmpresa)
      .eq('codigo', codigoArticulo);
    if (error) throw new InternalServerErrorException(error.message);
  }

  private async replaceDetalle(
    formulaId: string,
    codigoEmpresa: string,
    detalle: SaveFormulaData['detalle'],
  ): Promise<void> {
    const { error: delError } = await this.supabase.db
      .from('detalle_formulas')
      .delete()
      .eq('formula_id', formulaId)
      .eq('codigo_empresa', codigoEmpresa);
    if (delError) throw new InternalServerErrorException(delError.message);

    const { error } = await this.supabase.db.from('detalle_formulas').insert(
      detalle.map((c, i) => ({
        formula_id: formulaId,
        codigo_empresa: codigoEmpresa,
        codigo_articulo: c.codigoArticulo.toUpperCase(),
        cantidad: c.cantidad,
        orden: c.orden ?? i,
      })),
    );
    if (error) throw new InternalServerErrorException(error.message);
  }

  private toEntity(r: Record<string, any>, detalle: DetalleFormula[]): Formula {
    return {
      id: r.id as string,
      codigoEmpresa: r.codigo_empresa as string,
      codigoArticulo: r.codigo_articulo as string,
      descripcionArticulo: r.articulos?.descripcion as string | undefined,
      observacion: r.observacion as string | undefined,
      activo: r.activo as boolean,
      detalle,
      createdAt: r.created_at as string | undefined,
      updatedAt: r.updated_at as string | undefined,
    };
  }

  private toDetalle(r: Record<string, any>): DetalleFormula {
    return {
      id: r.id as string,
      formulaId: r.formula_id as string,
      codigoEmpresa: r.codigo_empresa as string,
      codigoArticulo: r.codigo_articulo as string,
      descripcionArticulo: r.articulos?.descripcion as string | undefined,
      cantidad: Number(r.cantidad),
      orden: Number(r.orden ?? 0),
    };
  }
}
