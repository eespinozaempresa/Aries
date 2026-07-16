import { Module } from '@nestjs/common';
import { SupabaseModule } from '../../shared/infrastructure/supabase/supabase.module';
import { AuthModule } from '../auth/auth.module';
import { ICxPRepository } from './domain/ports/cxp.repository.port';
import { SupabaseCxPRepository } from './infrastructure/repositories/supabase-cxp.repository';
import {
  ListCxPUseCase, FindCxPUseCase,
  RegistrarPagoUseCase, GetPagosUseCase, RenovarCxPUseCase,
} from './application/use-cases/cxp.use-cases';
import { CxPController } from './infrastructure/controllers/cxp.controller';

@Module({
  imports: [SupabaseModule, AuthModule],
  controllers: [CxPController],
  providers: [
    { provide: ICxPRepository, useClass: SupabaseCxPRepository },
    {
      provide: ListCxPUseCase,
      useFactory: (r: ICxPRepository) => new ListCxPUseCase(r),
      inject: [ICxPRepository],
    },
    {
      provide: FindCxPUseCase,
      useFactory: (r: ICxPRepository) => new FindCxPUseCase(r),
      inject: [ICxPRepository],
    },
    {
      provide: RegistrarPagoUseCase,
      useFactory: (r: ICxPRepository) => new RegistrarPagoUseCase(r),
      inject: [ICxPRepository],
    },
    {
      provide: GetPagosUseCase,
      useFactory: (r: ICxPRepository) => new GetPagosUseCase(r),
      inject: [ICxPRepository],
    },
    {
      provide: RenovarCxPUseCase,
      useFactory: (r: ICxPRepository) => new RenovarCxPUseCase(r),
      inject: [ICxPRepository],
    },
  ],
})
export class CuentasPagarModule {}
