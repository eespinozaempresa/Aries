import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { SupabaseService } from '../../../../shared/infrastructure/supabase/supabase.service';
import { IFormulaRepository } from '../../../maestros/domain/ports/formula.repository.port';
import { DetalleFormula } from '../../../maestros/domain/entities/formula.entity';

export interface ParametrosPartes {
  almacenPartes: string | null;
  operacionPartes: 'VENTAS' | 'MOVIMIENTOS' | null;
}

export interface LineaCosteada {
  codigoArticulo: string;
  cantidad: number;
  precioUnitario: number;
}

@Injectable()
export class FormulaExplosionService {
  constructor(
    private readonly supabase: SupabaseService,
    private readonly formulas: IFormulaRepository,
  ) {}

  async getParametrosPartes(codigoEmpresa: string): Promise<ParametrosPartes> {
    const { data, error } = await this.supabase.db
      .from('parametros')
      .select('almacen_partes, operacion_partes')
      .eq('codigo_empresa', codigoEmpresa)
      .maybeSingle();
    if (error) throw new InternalServerErrorException(error.message);
    return {
      almacenPartes: (data as any)?.almacen_partes || null,
      operacionPartes: ((data as any)?.operacion_partes || null) as ParametrosPartes['operacionPartes'],
    };
  }

  /** Solo true si almacenPartes Y operacionPartes están configurados y coinciden con `modulo`. */
  activaPara(p: ParametrosPartes, modulo: 'VENTAS' | 'MOVIMIENTOS'): boolean {
    return !!p.almacenPartes && p.operacionPartes === modulo;
  }

  /** Fórmulas activas de un lote de artículos Principal (delegado directo al repositorio de fórmulas). */
  getFormulasActivas(codigoEmpresa: string, codigos: string[]): Promise<Map<string, DetalleFormula[]>> {
    return this.formulas.findActivasByArticulos(codigoEmpresa, codigos);
  }

  async costoBaseMap(codigoEmpresa: string, codigos: string[]): Promise<Map<string, number>> {
    if (!codigos.length) return new Map();
    const { data, error } = await this.supabase.db
      .from('articulos')
      .select('codigo, precio_compra_base')
      .eq('codigo_empresa', codigoEmpresa)
      .in('codigo', codigos);
    if (error) throw new InternalServerErrorException(error.message);
    return new Map((data ?? []).map((a: any) => [a.codigo, Number(a.precio_compra_base)]));
  }

  async costoPromedioMap(codigoEmpresa: string, codigoAlmacen: string, codigos: string[]): Promise<Map<string, number>> {
    if (!codigos.length) return new Map();
    const { data, error } = await this.supabase.db
      .from('stock')
      .select('codigo_articulo, costo_promedio')
      .eq('codigo_empresa', codigoEmpresa)
      .eq('codigo_almacen', codigoAlmacen)
      .in('codigo_articulo', codigos);
    if (error) throw new InternalServerErrorException(error.message);
    return new Map((data ?? []).map((s: any) => [s.codigo_articulo, Number(s.costo_promedio)]));
  }

  /** costo_promedio en `codigoAlmacen` si es > 0; si no, precio_compra_base del artículo. */
  async costoConRespaldo(codigoEmpresa: string, codigoAlmacen: string, codigos: string[]): Promise<Map<string, number>> {
    if (!codigos.length) return new Map();
    const [costoPromedio, costoBase] = await Promise.all([
      this.costoPromedioMap(codigoEmpresa, codigoAlmacen, codigos),
      this.costoBaseMap(codigoEmpresa, codigos),
    ]);
    const map = new Map<string, number>();
    for (const codigo of codigos) {
      const cp = costoPromedio.get(codigo) ?? 0;
      map.set(codigo, cp > 0 ? cp : (costoBase.get(codigo) ?? 0));
    }
    return map;
  }

  /**
   * Dadas líneas {codigoArticulo, cantidad} de Principal(es), retorna las líneas de
   * Partes explotadas (BOM) valorizadas: costo_promedio en `almacenPartes` si es > 0,
   * si no precio_compra_base de esa Parte. Retorna [] si ninguna línea tiene fórmula activa.
   */
  async explotarPartes(
    codigoEmpresa: string,
    almacenPartes: string,
    lineas: { codigoArticulo: string; cantidad: number }[],
  ): Promise<LineaCosteada[]> {
    const codigosPrincipal = [...new Set(lineas.map((l) => l.codigoArticulo))];
    const formulasActivas = await this.formulas.findActivasByArticulos(codigoEmpresa, codigosPrincipal);
    if (!formulasActivas.size) return [];

    const codigosComponentes = [...new Set(
      [...formulasActivas.values()].flat().map((c) => c.codigoArticulo),
    )];
    const costoComponentes = await this.costoConRespaldo(codigoEmpresa, almacenPartes, codigosComponentes);

    const lineasPartes: LineaCosteada[] = [];
    for (const l of lineas) {
      const componentes = formulasActivas.get(l.codigoArticulo);
      if (!componentes) continue;
      for (const c of componentes) {
        lineasPartes.push({
          codigoArticulo: c.codigoArticulo,
          cantidad:       l.cantidad * c.cantidad,
          precioUnitario: costoComponentes.get(c.codigoArticulo) ?? 0,
        });
      }
    }
    return lineasPartes;
  }
}
