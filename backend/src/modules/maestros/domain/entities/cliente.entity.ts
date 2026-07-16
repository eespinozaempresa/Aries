export interface Cliente {
  id: string;
  codigoEmpresa: string;
  codigo: string;
  razonSocial: string;
  direccion?: string;
  rucDni?: string;
  telefono?: string;
  celular?: string;
  email?: string;
  activo: boolean;
  createdAt?: string;
  updatedAt?: string;
}
