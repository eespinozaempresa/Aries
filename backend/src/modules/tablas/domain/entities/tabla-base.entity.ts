export interface TablaBase {
  id: string;
  codigoEmpresa: string;
  codigo: string;
  descripcion: string;
  activo: boolean;
}

export interface Linea   extends TablaBase {}
export interface Medida  extends TablaBase {}
export interface Banco   extends TablaBase {}
export interface Marca   extends TablaBase {}

export interface Documento extends TablaBase {
  abreviatura?: string;
  serie: string;
  numeroSiguiente: number;
  aplicaIgv: boolean;
  tipo?: string;
}
