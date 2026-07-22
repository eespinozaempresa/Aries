export interface DetalleFormula {
  id?: string;
  formulaId?: string;
  codigoEmpresa: string;
  codigoArticulo: string;
  descripcionArticulo?: string;
  cantidad: number;
  orden: number;
}

export interface Formula {
  id: string;
  codigoEmpresa: string;
  codigoArticulo: string;
  descripcionArticulo?: string;
  observacion?: string;
  activo: boolean;
  detalle: DetalleFormula[];
  createdAt?: string;
  updatedAt?: string;
}
