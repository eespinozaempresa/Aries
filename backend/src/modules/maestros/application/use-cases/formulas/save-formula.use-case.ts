import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { IFormulaRepository, SaveFormulaData } from '../../../domain/ports/formula.repository.port';
import { IArticuloRepository } from '../../../domain/ports/articulo.repository.port';
import { Formula } from '../../../domain/entities/formula.entity';

@Injectable()
export class SaveFormulaUseCase {
  constructor(
    private readonly repo: IFormulaRepository,
    private readonly articulos: IArticuloRepository,
  ) {}

  async execute(codigoEmpresa: string, data: SaveFormulaData, id?: string): Promise<Formula> {
    if (!data.detalle?.length) {
      throw new BadRequestException('La fórmula debe tener al menos una Parte');
    }

    const codigoPrincipal = data.codigoArticulo.toUpperCase();
    const principal = await this.articulos.findByCodigo(codigoPrincipal, codigoEmpresa);
    if (!principal) throw new NotFoundException(`Artículo Principal ${codigoPrincipal} no encontrado`);
    if (!principal.activo) throw new BadRequestException(`Artículo Principal ${codigoPrincipal} está inactivo`);

    const codigosComponentes = data.detalle.map((d) => d.codigoArticulo.toUpperCase());
    const duplicados = [...new Set(
      codigosComponentes.filter((c, i) => codigosComponentes.indexOf(c) !== i),
    )];
    if (duplicados.length) {
      throw new BadRequestException(`Parte duplicada en la fórmula: ${duplicados.join(', ')}`);
    }
    if (codigosComponentes.includes(codigoPrincipal)) {
      throw new BadRequestException('Una Parte no puede ser igual al artículo Principal');
    }

    for (const componente of data.detalle) {
      if (componente.cantidad <= 0) {
        throw new BadRequestException(`La cantidad de la Parte ${componente.codigoArticulo} debe ser mayor a 0`);
      }
      const codigoComponente = componente.codigoArticulo.toUpperCase();
      const art = await this.articulos.findByCodigo(codigoComponente, codigoEmpresa);
      if (!art) throw new NotFoundException(`Parte ${codigoComponente} no encontrada`);
      if (!art.activo) throw new BadRequestException(`Parte ${codigoComponente} está inactiva`);
    }

    if (id) {
      const existing = await this.repo.findById(id, codigoEmpresa);
      if (!existing) throw new NotFoundException('Fórmula no encontrada');
      return this.repo.update(id, codigoEmpresa, data);
    }
    return this.repo.create(codigoEmpresa, data);
  }
}
