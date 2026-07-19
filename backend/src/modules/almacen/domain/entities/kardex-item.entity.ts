export interface KardexItem {
  id: number;
  codigoEmpresa: string;
  codigoAlmacen: string;
  codigoArticulo: string;
  descripcionAlmacen?: string;
  descripcionArticulo?: string;
  fecha: string;
  codigoDocumento: string;
  numeroDocumento: string;
  tipo: string;
  cantEntrada: number;
  precioEntrada: number;
  importeEntrada: number;
  cantSalida: number;
  precioSalida: number;
  importeSalida: number;
  stock: number;
  precioStock: number;
  importeStock: number;
}
