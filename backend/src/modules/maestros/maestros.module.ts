import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';

import { IArticuloRepository } from './domain/ports/articulo.repository.port';
import { IClienteRepository } from './domain/ports/cliente.repository.port';
import { IProveedorRepository } from './domain/ports/proveedor.repository.port';
import { IAlmacenRepository } from './domain/ports/almacen.repository.port';

import { SupabaseArticuloRepository } from './infrastructure/repositories/supabase-articulo.repository';
import { SupabaseClienteRepository } from './infrastructure/repositories/supabase-cliente.repository';
import { SupabaseProveedorRepository } from './infrastructure/repositories/supabase-proveedor.repository';
import { SupabaseAlmacenRepository } from './infrastructure/repositories/supabase-almacen.repository';

import { SearchArticulosUseCase } from './application/use-cases/articulos/search-articulos.use-case';
import { SaveArticuloUseCase } from './application/use-cases/articulos/save-articulo.use-case';
import { SearchClientesUseCase } from './application/use-cases/clientes/search-clientes.use-case';
import { SaveClienteUseCase } from './application/use-cases/clientes/save-cliente.use-case';
import { SearchProveedoresUseCase } from './application/use-cases/proveedores/search-proveedores.use-case';
import { SaveProveedorUseCase } from './application/use-cases/proveedores/save-proveedor.use-case';
import { SearchAlmacenesUseCase } from './application/use-cases/almacenes/search-almacenes.use-case';
import { SaveAlmacenUseCase } from './application/use-cases/almacenes/save-almacen.use-case';

import { ArticulosController } from './infrastructure/controllers/articulos.controller';
import { ClientesController } from './infrastructure/controllers/clientes.controller';
import { ProveedoresController } from './infrastructure/controllers/proveedores.controller';
import { AlmacenesController } from './infrastructure/controllers/almacenes.controller';

@Module({
  imports: [AuthModule],
  controllers: [
    ArticulosController,
    ClientesController,
    ProveedoresController,
    AlmacenesController,
  ],
  providers: [
    { provide: IArticuloRepository,  useClass: SupabaseArticuloRepository },
    { provide: IClienteRepository,   useClass: SupabaseClienteRepository },
    { provide: IProveedorRepository, useClass: SupabaseProveedorRepository },
    { provide: IAlmacenRepository,   useClass: SupabaseAlmacenRepository },
    SearchArticulosUseCase, SaveArticuloUseCase,
    SearchClientesUseCase,  SaveClienteUseCase,
    SearchProveedoresUseCase, SaveProveedorUseCase,
    SearchAlmacenesUseCase, SaveAlmacenUseCase,
  ],
  exports: [
    IArticuloRepository, IClienteRepository,
    IProveedorRepository, IAlmacenRepository,
    SearchArticulosUseCase, SearchClientesUseCase,
    SearchProveedoresUseCase, SearchAlmacenesUseCase,
  ],
})
export class MaestrosModule {}
