export interface Articulo {
  id: string;
  codigoEmpresa: string;
  codigo: string;
  descripcion: string;
  codigoLinea?: string;
  codigoMedida?: string;
  codigoMarca?: string;
  precioCompraBase: number;
  igvCompra: number;
  precioCompra: number;
  utilidadPct: number;
  precioVentaBase: number;
  igvVenta: number;
  precioVenta: number;
  fechaRegistro?: string;
  fechaVencimiento?: string;
  stockMinimo: number;
  stockMaximo: number;
  codigoBarras?: string;
  pendiente: boolean;
  activo: boolean;
  conFormula: boolean;
  createdAt?: string;
  updatedAt?: string;
}
