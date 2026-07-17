import { ListaPrecio } from '../entities/lista-precio.entity';

export interface SaveListaPrecioData {
  idArticulo: string;
  idTipoLista: string;
  precioVentaBase: number;
  descuentoPct: number;
  descuentoMonto: number;
  precioVenta: number;
  activo?: boolean;
}

export abstract class IListaPrecioRepository {
  abstract findByArticulo(codigoEmpresa: string, idArticulo: string): Promise<ListaPrecio[]>;
  abstract findByTipoLista(codigoEmpresa: string, idArticulo: string, idTipoLista: string): Promise<ListaPrecio | null>;
  abstract save(codigoEmpresa: string, data: SaveListaPrecioData, id?: string): Promise<ListaPrecio>;
  abstract toggleActivo(codigoEmpresa: string, id: string): Promise<ListaPrecio>;
  abstract remove(codigoEmpresa: string, id: string): Promise<void>;
}
