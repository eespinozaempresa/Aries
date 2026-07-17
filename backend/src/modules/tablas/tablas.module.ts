import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { SupabaseModule } from '../../shared/infrastructure/supabase/supabase.module';
import {
  ILineaRepository, IMedidaRepository, IBancoRepository,
  IMarcaRepository, IDocumentoRepository, ITipoListaRepository,
} from './domain/ports/tabla.repository.port';
import {
  SupabaseLineaRepo, SupabaseMedidaRepo, SupabaseBancoRepo,
  SupabaseMarcaRepo, SupabaseDocumentoRepo, SupabaseTipoListaRepo,
} from './infrastructure/repositories/supabase-tabla.repository';
import {
  LineasController, MedidasController, BancosController,
  MarcasController, DocumentosController, TiposListaController,
} from './infrastructure/controllers/tablas.controller';

@Module({
  imports: [SupabaseModule, AuthModule],
  controllers: [
    LineasController, MedidasController, BancosController,
    MarcasController, DocumentosController, TiposListaController,
  ],
  providers: [
    { provide: ILineaRepository,      useClass: SupabaseLineaRepo },
    { provide: IMedidaRepository,     useClass: SupabaseMedidaRepo },
    { provide: IBancoRepository,      useClass: SupabaseBancoRepo },
    { provide: IMarcaRepository,      useClass: SupabaseMarcaRepo },
    { provide: IDocumentoRepository,  useClass: SupabaseDocumentoRepo },
    { provide: ITipoListaRepository,  useClass: SupabaseTipoListaRepo },
  ],
  exports: [
    ILineaRepository, IMedidaRepository, IBancoRepository,
    IMarcaRepository, IDocumentoRepository, ITipoListaRepository,
  ],
})
export class TablasModule {}
