export interface DetalleVenta {
  id: string;
  ventaId: string;
  codigoEmpresa: string;
  codigoArticulo: string;
  descripcionArticulo?: string;
  cantidad: number;
  precioUnitario: number;
  descuentoPct: number;
  importe: number;
  precioUnitarioUsd: number;
  importeUsd: number;
}
