export interface Almacen {
  id: string;
  codigoEmpresa: string;
  codigo: string;
  descripcion: string;
  abreviatura?: string;
  ubicacion?: string;
  tipo: string;
  activo: boolean;
}
