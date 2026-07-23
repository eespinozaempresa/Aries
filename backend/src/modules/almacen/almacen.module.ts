import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { MaestrosModule } from '../maestros/maestros.module';
import { SupabaseModule } from '../../shared/infrastructure/supabase/supabase.module';

// Repositories
import { SupabaseMovimientoRepository } from './infrastructure/repositories/supabase-movimiento.repository';
import { SupabaseKardexRepository } from './infrastructure/repositories/supabase-kardex.repository';
import { SupabaseStockRepository } from './infrastructure/repositories/supabase-stock.repository';

// Use cases
import { RegistrarMovimientoUseCase } from './application/use-cases/registrar-movimiento.use-case';
import { AnularMovimientoUseCase } from './application/use-cases/anular-movimiento.use-case';
import { ListMovimientosUseCase } from './application/use-cases/list-movimientos.use-case';
import { EliminarMovimientoUseCase } from './application/use-cases/eliminar-movimiento.use-case';
import { GetKardexUseCase } from './application/use-cases/get-kardex.use-case';
import { GetStockUseCase } from './application/use-cases/get-stock.use-case';
import { RecalcularKardexUseCase } from './application/use-cases/recalcular-kardex.use-case';

// Controllers
import { MovimientosController } from './infrastructure/controllers/movimientos.controller';
import { KardexController } from './infrastructure/controllers/kardex.controller';
import { StockController } from './infrastructure/controllers/stock.controller';

// Port tokens
import { IMovimientoRepository } from './domain/ports/movimiento.repository.port';
import { IKardexRepository } from './domain/ports/kardex.repository.port';
import { IStockRepository } from './domain/ports/stock.repository.port';

@Module({
  imports: [SupabaseModule, AuthModule, MaestrosModule],
  controllers: [MovimientosController, KardexController, StockController],
  providers: [
    { provide: IMovimientoRepository, useClass: SupabaseMovimientoRepository },
    { provide: IKardexRepository,     useClass: SupabaseKardexRepository },
    { provide: IStockRepository,      useClass: SupabaseStockRepository },
    RegistrarMovimientoUseCase,
    AnularMovimientoUseCase,
    ListMovimientosUseCase,
    EliminarMovimientoUseCase,
    GetKardexUseCase,
    GetStockUseCase,
    RecalcularKardexUseCase,
  ],
  exports: [RecalcularKardexUseCase],
})
export class AlmacenModule {}
