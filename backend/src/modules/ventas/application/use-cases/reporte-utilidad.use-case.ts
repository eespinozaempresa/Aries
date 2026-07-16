import { Injectable } from '@nestjs/common';
import { SupabaseService } from '../../../../shared/infrastructure/supabase/supabase.service';

export interface UtilidadItem {
  codigoArticulo: string;
  descripcion: string;
  cantidadVendida: number;
  precioPromVenta: number;
  costoPromedio: number;
  utilidadUnit: number;
  utilidadTotal: number;
  margenPct: number;
}

@Injectable()
export class ReporteUtilidadUseCase {
  constructor(private readonly supabase: SupabaseService) {}

  async execute(
    codigoEmpresa: string,
    codigoAlmacen?: string,
    desde?: string,
    hasta?: string,
  ): Promise<UtilidadItem[]> {
    // Aggregate sales by article
    let dvQ = this.supabase.db
      .from('detalle_ventas')
      .select('codigo_articulo, cantidad, importe')
      .eq('codigo_empresa', codigoEmpresa);

    if (desde || hasta || codigoAlmacen) {
      let vQ = this.supabase.db
        .from('ventas')
        .select('id')
        .eq('codigo_empresa', codigoEmpresa)
        .eq('anulado', false);
      if (codigoAlmacen) vQ = vQ.eq('codigo_almacen', codigoAlmacen);
      if (desde) vQ = vQ.gte('fecha', desde);
      if (hasta) vQ = vQ.lte('fecha', hasta);
      const { data: ventasIds } = await vQ;
      const ids = (ventasIds ?? []).map((v: { id: string }) => v.id);
      if (!ids.length) return [];
      dvQ = dvQ.in('venta_id', ids);
    }

    const { data: detalles } = await dvQ;
    if (!detalles?.length) return [];

    // Sum by article
    const byArt = new Map<string, { cant: number; importe: number }>();
    for (const d of detalles) {
      const prev = byArt.get(d.codigo_articulo) ?? { cant: 0, importe: 0 };
      byArt.set(d.codigo_articulo, {
        cant:    prev.cant    + Number(d.cantidad),
        importe: prev.importe + Number(d.importe),
      });
    }

    // Get current stock costs and article names
    const codigos = [...byArt.keys()];
    const { data: stocks } = await this.supabase.db
      .from('stock')
      .select('codigo_articulo, costo_promedio')
      .eq('codigo_empresa', codigoEmpresa)
      .in('codigo_articulo', codigos);

    const { data: arts } = await this.supabase.db
      .from('articulos')
      .select('codigo, descripcion')
      .eq('codigo_empresa', codigoEmpresa)
      .in('codigo', codigos);

    const costoMap   = new Map((stocks ?? []).map((s: any) => [s.codigo_articulo, Number(s.costo_promedio)]));
    const descMap    = new Map((arts ?? []).map((a: any) => [a.codigo, a.descripcion as string]));

    const result: UtilidadItem[] = [];
    for (const [cod, { cant, importe }] of byArt) {
      const costo        = costoMap.get(cod) ?? 0;
      const precioPromV  = cant > 0 ? importe / cant : 0;
      const utilidadUnit = precioPromV - costo;
      const utilidadTot  = utilidadUnit * cant;
      const margen       = precioPromV > 0 ? (utilidadUnit / precioPromV) * 100 : 0;
      result.push({
        codigoArticulo:  cod,
        descripcion:     descMap.get(cod) ?? cod,
        cantidadVendida: cant,
        precioPromVenta: parseFloat(precioPromV.toFixed(4)),
        costoPromedio:   parseFloat(costo.toFixed(4)),
        utilidadUnit:    parseFloat(utilidadUnit.toFixed(4)),
        utilidadTotal:   parseFloat(utilidadTot.toFixed(2)),
        margenPct:       parseFloat(margen.toFixed(2)),
      });
    }

    return result.sort((a, b) => b.utilidadTotal - a.utilidadTotal);
  }
}
