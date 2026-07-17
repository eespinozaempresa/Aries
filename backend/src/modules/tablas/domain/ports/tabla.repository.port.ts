import { TablaBase, Documento, TipoLista } from '../entities/tabla-base.entity';

export interface TablaFilter {
  codigoEmpresa: string;
  q?: string;
  activo?: boolean;
}

export abstract class ITablaRepository<T extends TablaBase> {
  abstract findAll(filter: TablaFilter): Promise<T[]>;
  abstract findByCodigo(codigoEmpresa: string, codigo: string): Promise<T | null>;
  abstract save(codigoEmpresa: string, data: Partial<T>, id?: string): Promise<T>;
}

export abstract class ILineaRepository     extends ITablaRepository<import('../entities/tabla-base.entity').Linea>  {}
export abstract class IMedidaRepository    extends ITablaRepository<import('../entities/tabla-base.entity').Medida> {}
export abstract class IBancoRepository     extends ITablaRepository<import('../entities/tabla-base.entity').Banco>  {}
export abstract class IMarcaRepository     extends ITablaRepository<import('../entities/tabla-base.entity').Marca>  {}
export abstract class IDocumentoRepository extends ITablaRepository<Documento> {}
export abstract class ITipoListaRepository extends ITablaRepository<TipoLista> {}
