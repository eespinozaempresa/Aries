export interface StockItem {
  id: string;
  codigoEmpresa: string;
  codigoAlmacen: string;
  codigoArticulo: string;
  descripcionAlmacen?: string;
  descripcionArticulo?: string;
  stockInicial: number;
  stockCompras: number;
  stockVentas: number;
  stockEntradas: number;
  stockSalidas: number;
  stockTrasladosIn: number;
  stockTrasladosOut: number;
  costoPromedio: number;
  importeTotal: number;
  fechaActualizacion?: string;
  // Computed
  stockActual?: number;
}
