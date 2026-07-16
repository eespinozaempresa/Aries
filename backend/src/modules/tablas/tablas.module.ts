import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { SupabaseModule } from '../../shared/infrastructure/supabase/supabase.module';
import {
  ILineaRepository, IMedidaRepository, IBancoRepository,
  IMarcaRepository, IDocumentoRepository,
} from './domain/ports/tabla.repository.port';
import {
  SupabaseLineaRepo, SupabaseMedidaRepo, SupabaseBancoRepo,
  SupabaseMarcaRepo, SupabaseDocumentoRepo,
} from './infrastructure/repositories/supabase-tabla.repository';
import {
  LineasController, MedidasController, BancosController,
  MarcasController, DocumentosController,
} from './infrastructure/controllers/tablas.controller';

@Module({
  imports: [SupabaseModule, AuthModule],
  controllers: [
    LineasController, MedidasController, BancosController,
    MarcasController, DocumentosController,
  ],
  providers: [
    { provide: ILineaRepository,     useClass: SupabaseLineaRepo },
    { provide: IMedidaRepository,    useClass: SupabaseMedidaRepo },
    { provide: IBancoRepository,     useClass: SupabaseBancoRepo },
    { provide: IMarcaRepository,     useClass: SupabaseMarcaRepo },
    { provide: IDocumentoRepository, useClass: SupabaseDocumentoRepo },
  ],
  exports: [
    ILineaRepository, IMedidaRepository, IBancoRepository,
    IMarcaRepository, IDocumentoRepository,
  ],
})
export class TablasModule {}
