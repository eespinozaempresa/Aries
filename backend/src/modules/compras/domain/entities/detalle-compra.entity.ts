export interface DetalleCompra {
  id: string;
  compraId: string;
  codigoEmpresa: string;
  codigoArticulo: string;
  descripcionArticulo?: string;
  cantidad: number;
  precioUnitario: number;
  importe: number;
  fechaVencimiento?: string;
  precioUnitarioUsd: number;
  importeUsd: number;
}
