import {
  Controller, Get, Post, Put, Patch, Body, Param, Query,
  UseGuards, Request, NotFoundException,
} from '@nestjs/common';
import { AuthGuard } from '../../../../shared/infrastructure/guards/auth.guard';
import {
  ILineaRepository, IMedidaRepository, IBancoRepository,
  IMarcaRepository, IDocumentoRepository, ITipoListaRepository, ITipoPagoRepository,
} from '../../domain/ports/tabla.repository.port';
import { ListTablaUseCase, SaveTablaUseCase } from '../../application/use-cases/tabla.use-cases';
import {
  CreateTablaDto, UpdateTablaDto,
  CreateDocumentoDto, UpdateDocumentoDto,
  CreateTipoListaDto, UpdateTipoListaDto,
  CreateTipoPagoDto, UpdateTipoPagoDto,
} from '../dto/tabla.dto';
import { Linea, Medida, Banco, Marca, Documento, TipoLista, TipoPago } from '../../domain/entities/tabla-base.entity';

function makeController<T extends import('../../domain/entities/tabla-base.entity').TablaBase>(
  path: string,
  repoToken: abstract new (...args: unknown[]) => import('../../domain/ports/tabla.repository.port').ITablaRepository<T>,
) {
  @UseGuards(AuthGuard)
  @Controller(`tablas/${path}`)
  class TablaController {
    private listUC: ListTablaUseCase<T>;
    private saveUC: SaveTablaUseCase<T>;

    constructor(repo: typeof repoToken extends abstract new (...a: unknown[]) => infer R ? R : never) {
      this.listUC = new ListTablaUseCase(repo as unknown as import('../../domain/ports/tabla.repository.port').ITablaRepository<T>);
      this.saveUC = new SaveTablaUseCase(repo as unknown as import('../../domain/ports/tabla.repository.port').ITablaRepository<T>);
    }

    @Get()
    list(@Request() req: any, @Query('q') q?: string, @Query('activo') activo?: string) {
      const activoFilter = activo === 'true' ? true : activo === 'false' ? false : undefined;
      return this.listUC.execute({ codigoEmpresa: req.user.empresa, q, activo: activoFilter });
    }

    @Post()
    create(@Body() dto: CreateTablaDto, @Request() req: any) {
      return this.saveUC.execute(req.user.empresa, dto as unknown as Partial<T>);
    }

    @Put(':id')
    update(@Param('id') id: string, @Body() dto: UpdateTablaDto, @Request() req: any) {
      return this.saveUC.execute(req.user.empresa, dto as unknown as Partial<T>, id);
    }

    @Patch(':id/toggle')
    async toggle(@Param('id') id: string, @Request() req: any) {
      const items = await this.listUC.execute({ codigoEmpresa: req.user.empresa });
      const item = (items as T[]).find((i) => i.id === id);
      if (!item) throw new NotFoundException();
      return this.saveUC.execute(req.user.empresa, { activo: !item.activo } as Partial<T>, id);
    }
  }
  return TablaController;
}

// Each controller class must be concrete for NestJS DI to work.
// We use a simpler approach: one generic controller per entity.

@UseGuards(AuthGuard)
@Controller('tablas/lineas')
export class LineasController {
  constructor(private readonly repo: ILineaRepository) {}

  @Get()
  list(@Request() req: any, @Query('q') q?: string, @Query('activo') activo?: string) {
    return new ListTablaUseCase<Linea>(this.repo).execute({
      codigoEmpresa: req.user.empresa, q,
      activo: activo === 'true' ? true : activo === 'false' ? false : undefined,
    });
  }
  @Post()
  create(@Body() dto: CreateTablaDto, @Request() req: any) {
    return new SaveTablaUseCase<Linea>(this.repo).execute(req.user.empresa, dto);
  }
  @Put(':id')
  update(@Param('id') id: string, @Body() dto: UpdateTablaDto, @Request() req: any) {
    return new SaveTablaUseCase<Linea>(this.repo).execute(req.user.empresa, dto, id);
  }
  @Patch(':id/toggle')
  async toggle(@Param('id') id: string, @Request() req: any) {
    const item = await this.repo.findByCodigo(req.user.empresa, id);
    const all  = await this.repo.findAll({ codigoEmpresa: req.user.empresa });
    const found = all.find((i) => i.id === id);
    if (!found) throw new NotFoundException();
    return new SaveTablaUseCase<Linea>(this.repo).execute(req.user.empresa, { activo: !found.activo }, id);
  }
}

@UseGuards(AuthGuard)
@Controller('tablas/medidas')
export class MedidasController {
  constructor(private readonly repo: IMedidaRepository) {}
  @Get()
  list(@Request() req: any, @Query('q') q?: string, @Query('activo') activo?: string) {
    return new ListTablaUseCase<Medida>(this.repo).execute({ codigoEmpresa: req.user.empresa, q,
      activo: activo === 'true' ? true : activo === 'false' ? false : undefined });
  }
  @Post()
  create(@Body() dto: CreateTablaDto, @Request() req: any) {
    return new SaveTablaUseCase<Medida>(this.repo).execute(req.user.empresa, dto);
  }
  @Put(':id')
  update(@Param('id') id: string, @Body() dto: UpdateTablaDto, @Request() req: any) {
    return new SaveTablaUseCase<Medida>(this.repo).execute(req.user.empresa, dto, id);
  }
  @Patch(':id/toggle')
  async toggle(@Param('id') id: string, @Request() req: any) {
    const all = await this.repo.findAll({ codigoEmpresa: req.user.empresa });
    const found = all.find((i) => i.id === id);
    if (!found) throw new NotFoundException();
    return new SaveTablaUseCase<Medida>(this.repo).execute(req.user.empresa, { activo: !found.activo }, id);
  }
}

@UseGuards(AuthGuard)
@Controller('tablas/bancos')
export class BancosController {
  constructor(private readonly repo: IBancoRepository) {}
  @Get()
  list(@Request() req: any, @Query('q') q?: string, @Query('activo') activo?: string) {
    return new ListTablaUseCase<Banco>(this.repo).execute({ codigoEmpresa: req.user.empresa, q,
      activo: activo === 'true' ? true : activo === 'false' ? false : undefined });
  }
  @Post()
  create(@Body() dto: CreateTablaDto, @Request() req: any) {
    return new SaveTablaUseCase<Banco>(this.repo).execute(req.user.empresa, dto);
  }
  @Put(':id')
  update(@Param('id') id: string, @Body() dto: UpdateTablaDto, @Request() req: any) {
    return new SaveTablaUseCase<Banco>(this.repo).execute(req.user.empresa, dto, id);
  }
  @Patch(':id/toggle')
  async toggle(@Param('id') id: string, @Request() req: any) {
    const all = await this.repo.findAll({ codigoEmpresa: req.user.empresa });
    const found = all.find((i) => i.id === id);
    if (!found) throw new NotFoundException();
    return new SaveTablaUseCase<Banco>(this.repo).execute(req.user.empresa, { activo: !found.activo }, id);
  }
}

@UseGuards(AuthGuard)
@Controller('tablas/marcas')
export class MarcasController {
  constructor(private readonly repo: IMarcaRepository) {}
  @Get()
  list(@Request() req: any, @Query('q') q?: string, @Query('activo') activo?: string) {
    return new ListTablaUseCase<Marca>(this.repo).execute({ codigoEmpresa: req.user.empresa, q,
      activo: activo === 'true' ? true : activo === 'false' ? false : undefined });
  }
  @Post()
  create(@Body() dto: CreateTablaDto, @Request() req: any) {
    return new SaveTablaUseCase<Marca>(this.repo).execute(req.user.empresa, dto);
  }
  @Put(':id')
  update(@Param('id') id: string, @Body() dto: UpdateTablaDto, @Request() req: any) {
    return new SaveTablaUseCase<Marca>(this.repo).execute(req.user.empresa, dto, id);
  }
  @Patch(':id/toggle')
  async toggle(@Param('id') id: string, @Request() req: any) {
    const all = await this.repo.findAll({ codigoEmpresa: req.user.empresa });
    const found = all.find((i) => i.id === id);
    if (!found) throw new NotFoundException();
    return new SaveTablaUseCase<Marca>(this.repo).execute(req.user.empresa, { activo: !found.activo }, id);
  }
}

@UseGuards(AuthGuard)
@Controller('tablas/tipos-lista')
export class TiposListaController {
  constructor(private readonly repo: ITipoListaRepository) {}
  @Get()
  list(@Request() req: any, @Query('q') q?: string, @Query('activo') activo?: string) {
    return new ListTablaUseCase<TipoLista>(this.repo).execute({ codigoEmpresa: req.user.empresa, q,
      activo: activo === 'true' ? true : activo === 'false' ? false : undefined });
  }
  @Post()
  create(@Body() dto: CreateTipoListaDto, @Request() req: any) {
    return new SaveTablaUseCase<TipoLista>(this.repo).execute(req.user.empresa, dto as Partial<TipoLista>);
  }
  @Put(':id')
  update(@Param('id') id: string, @Body() dto: UpdateTipoListaDto, @Request() req: any) {
    return new SaveTablaUseCase<TipoLista>(this.repo).execute(req.user.empresa, dto as Partial<TipoLista>, id);
  }
  @Patch(':id/toggle')
  async toggle(@Param('id') id: string, @Request() req: any) {
    const all = await this.repo.findAll({ codigoEmpresa: req.user.empresa });
    const found = all.find((i) => i.id === id);
    if (!found) throw new NotFoundException();
    return new SaveTablaUseCase<TipoLista>(this.repo).execute(req.user.empresa, { activo: !found.activo }, id);
  }
}

@UseGuards(AuthGuard)
@Controller('tablas/tipos-pago')
export class TiposPagoController {
  constructor(private readonly repo: ITipoPagoRepository) {}
  @Get()
  list(@Request() req: any, @Query('q') q?: string, @Query('activo') activo?: string) {
    return new ListTablaUseCase<TipoPago>(this.repo).execute({ codigoEmpresa: req.user.empresa, q,
      activo: activo === 'true' ? true : activo === 'false' ? false : undefined });
  }
  @Post()
  create(@Body() dto: CreateTipoPagoDto, @Request() req: any) {
    return new SaveTablaUseCase<TipoPago>(this.repo).execute(req.user.empresa, dto as Partial<TipoPago>);
  }
  @Put(':id')
  update(@Param('id') id: string, @Body() dto: UpdateTipoPagoDto, @Request() req: any) {
    return new SaveTablaUseCase<TipoPago>(this.repo).execute(req.user.empresa, dto as Partial<TipoPago>, id);
  }
  @Patch(':id/toggle')
  async toggle(@Param('id') id: string, @Request() req: any) {
    const all = await this.repo.findAll({ codigoEmpresa: req.user.empresa });
    const found = all.find((i) => i.id === id);
    if (!found) throw new NotFoundException();
    return new SaveTablaUseCase<TipoPago>(this.repo).execute(req.user.empresa, { activo: !found.activo }, id);
  }
}

@UseGuards(AuthGuard)
@Controller('tablas/documentos')
export class DocumentosController {
  constructor(private readonly repo: IDocumentoRepository) {}
  @Get()
  list(
    @Request() req: any,
    @Query('q') q?: string,
    @Query('activo') activo?: string,
    @Query('tipo') tipo?: string,
  ) {
    return new ListTablaUseCase<Documento>(this.repo).execute({
      codigoEmpresa: req.user.empresa, q,
      activo: activo === 'true' ? true : activo === 'false' ? false : undefined,
      tipo,
    });
  }
  @Post()
  create(@Body() dto: CreateDocumentoDto, @Request() req: any) {
    return new SaveTablaUseCase<Documento>(this.repo).execute(req.user.empresa, dto as Partial<Documento>);
  }
  @Put(':id')
  update(@Param('id') id: string, @Body() dto: UpdateDocumentoDto, @Request() req: any) {
    return new SaveTablaUseCase<Documento>(this.repo).execute(req.user.empresa, dto as Partial<Documento>, id);
  }
  @Patch(':id/toggle')
  async toggle(@Param('id') id: string, @Request() req: any) {
    const all = await this.repo.findAll({ codigoEmpresa: req.user.empresa });
    const found = all.find((i) => i.id === id);
    if (!found) throw new NotFoundException();
    return new SaveTablaUseCase<Documento>(this.repo).execute(req.user.empresa, { activo: !found.activo }, id);
  }
}
