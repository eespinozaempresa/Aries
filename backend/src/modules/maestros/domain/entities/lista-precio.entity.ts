export interface ListaPrecio {
  id: string;
  codigoEmpresa: string;
  idArticulo: string;
  idTipoLista: string;
  precioVentaBase: number;
  descuentoPct: number;
  descuentoMonto: number;
  precioVenta: number;
  activo: boolean;
  createdAt?: string;
}
