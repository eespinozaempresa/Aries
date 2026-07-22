import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { SupabaseModule } from '../../shared/infrastructure/supabase/supabase.module';

import { IArticuloRepository } from './domain/ports/articulo.repository.port';
import { IClienteRepository } from './domain/ports/cliente.repository.port';
import { IProveedorRepository } from './domain/ports/proveedor.repository.port';
import { IAlmacenRepository } from './domain/ports/almacen.repository.port';
import { IListaPrecioRepository } from './domain/ports/lista-precio.repository.port';
import { IFormulaRepository } from './domain/ports/formula.repository.port';

import { SupabaseArticuloRepository } from './infrastructure/repositories/supabase-articulo.repository';
import { SupabaseClienteRepository } from './infrastructure/repositories/supabase-cliente.repository';
import { SupabaseProveedorRepository } from './infrastructure/repositories/supabase-proveedor.repository';
import { SupabaseAlmacenRepository } from './infrastructure/repositories/supabase-almacen.repository';
import { SupabaseListaPrecioRepository } from './infrastructure/repositories/supabase-lista-precio.repository';
import { SupabaseFormulaRepository } from './infrastructure/repositories/supabase-formula.repository';

import { SearchArticulosUseCase } from './application/use-cases/articulos/search-articulos.use-case';
import { SaveArticuloUseCase } from './application/use-cases/articulos/save-articulo.use-case';
import { SearchClientesUseCase } from './application/use-cases/clientes/search-clientes.use-case';
import { SaveClienteUseCase } from './application/use-cases/clientes/save-cliente.use-case';
import { SearchProveedoresUseCase } from './application/use-cases/proveedores/search-proveedores.use-case';
import { SaveProveedorUseCase } from './application/use-cases/proveedores/save-proveedor.use-case';
import { SearchAlmacenesUseCase } from './application/use-cases/almacenes/search-almacenes.use-case';
import { SaveAlmacenUseCase } from './application/use-cases/almacenes/save-almacen.use-case';
import { SearchFormulasUseCase } from './application/use-cases/formulas/search-formulas.use-case';
import { SaveFormulaUseCase } from './application/use-cases/formulas/save-formula.use-case';

import { ArticulosController } from './infrastructure/controllers/articulos.controller';
import { ClientesController } from './infrastructure/controllers/clientes.controller';
import { ProveedoresController } from './infrastructure/controllers/proveedores.controller';
import { AlmacenesController } from './infrastructure/controllers/almacenes.controller';
import { ListaPreciosController } from './infrastructure/controllers/lista-precios.controller';
import { FormulasController } from './infrastructure/controllers/formulas.controller';

@Module({
  imports: [AuthModule, SupabaseModule],
  controllers: [
    ArticulosController,
    ClientesController,
    ProveedoresController,
    AlmacenesController,
    ListaPreciosController,
    FormulasController,
  ],
  providers: [
    { provide: IArticuloRepository,    useClass: SupabaseArticuloRepository },
    { provide: IClienteRepository,     useClass: SupabaseClienteRepository },
    { provide: IProveedorRepository,   useClass: SupabaseProveedorRepository },
    { provide: IAlmacenRepository,     useClass: SupabaseAlmacenRepository },
    { provide: IListaPrecioRepository, useClass: SupabaseListaPrecioRepository },
    { provide: IFormulaRepository,     useClass: SupabaseFormulaRepository },
    SearchArticulosUseCase, SaveArticuloUseCase,
    SearchClientesUseCase,  SaveClienteUseCase,
    SearchProveedoresUseCase, SaveProveedorUseCase,
    SearchAlmacenesUseCase, SaveAlmacenUseCase,
    SearchFormulasUseCase, SaveFormulaUseCase,
  ],
  exports: [
    IArticuloRepository, IClienteRepository,
    IProveedorRepository, IAlmacenRepository, IFormulaRepository,
    SearchArticulosUseCase, SearchClientesUseCase,
    SearchProveedoresUseCase, SearchAlmacenesUseCase,
  ],
})
export class MaestrosModule {}
