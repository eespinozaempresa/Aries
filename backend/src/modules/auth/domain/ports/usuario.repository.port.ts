import { Usuario } from '../entities/usuario.entity';

export abstract class IUsuarioRepository {
  abstract findByCodigoEmpresaAndCodigo(
    codigoEmpresa: string,
    codigo: string,
  ): Promise<Usuario | null>;
  abstract findAllByCodigo(codigo: string): Promise<Usuario[]>;
}
