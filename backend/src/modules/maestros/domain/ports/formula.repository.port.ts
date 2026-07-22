import { Formula, DetalleFormula } from '../entities/formula.entity';

export interface FormulaSearchParams {
  codigoEmpresa: string;
  q?: string;
  activo?: boolean;
}

export interface SaveDetalleFormulaData {
  codigoArticulo: string;
  cantidad: number;
  orden?: number;
}

export interface SaveFormulaData {
  codigoArticulo: string;
  observacion?: string;
  activo?: boolean;
  detalle: SaveDetalleFormulaData[];
}

export abstract class IFormulaRepository {
  abstract findAll(params: FormulaSearchParams): Promise<Formula[]>;
  abstract findById(id: string, codigoEmpresa: string): Promise<Formula | null>;
  /** Fórmulas activas para un lote de artículos Principal, usado por Ventas para explotar Partes. */
  abstract findActivasByArticulos(
    codigoEmpresa: string,
    codigosArticulo: string[],
  ): Promise<Map<string, DetalleFormula[]>>;
  abstract create(codigoEmpresa: string, data: SaveFormulaData): Promise<Formula>;
  abstract update(id: string, codigoEmpresa: string, data: SaveFormulaData): Promise<Formula>;
  abstract toggleActivo(codigoEmpresa: string, id: string): Promise<Formula>;
}
