export interface TipoCambio {
  id: string;
  codigoEmpresa: string;
  fecha: string; // YYYY-MM-DD
  tipoCambio: number;
  usuarioRegistro?: string;
  createdAt?: string;
}
