export interface DetalleVenta {
  id: string;
  ventaId: string;
  codigoEmpresa: string;
  codigoArticulo: string;
  cantidad: number;
  precioUnitario: number;
  descuentoPct: number;
  importe: number;
}
