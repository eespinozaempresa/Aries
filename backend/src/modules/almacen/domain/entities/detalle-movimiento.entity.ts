export interface DetalleMovimiento {
  id: string;
  movimientoId: string;
  codigoEmpresa: string;
  codigoArticulo: string;
  descripcionArticulo?: string;
  cantidad: number;
  precioUnitario: number;
  importe: number;
}
