import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { SupabaseModule } from '../../shared/infrastructure/supabase/supabase.module';
import { ICompraRepository } from './domain/ports/compra.repository.port';
import { SupabaseCompraRepository } from './infrastructure/repositories/supabase-compra.repository';
import { RegistrarCompraUseCase } from './application/use-cases/registrar-compra.use-case';
import { AnularCompraUseCase } from './application/use-cases/anular-compra.use-case';
import { ListComprasUseCase } from './application/use-cases/list-compras.use-case';
import { ComprasController } from './infrastructure/controllers/compras.controller';

@Module({
  imports: [SupabaseModule, AuthModule],
  controllers: [ComprasController],
  providers: [
    { provide: ICompraRepository, useClass: SupabaseCompraRepository },
    RegistrarCompraUseCase,
    AnularCompraUseCase,
    ListComprasUseCase,
  ],
  exports: [ICompraRepository],
})
export class ComprasModule {}
