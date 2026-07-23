import { Module } from '@nestjs/common';
import { SupabaseModule } from '../../shared/infrastructure/supabase/supabase.module';
import { AuthModule } from '../auth/auth.module';
import { ICxCRepository } from './domain/ports/cxc.repository.port';
import { SupabaseCxCRepository } from './infrastructure/repositories/supabase-cxc.repository';
import {
  ListCxCUseCase, FindCxCUseCase,
  RegistrarCobroUseCase, GetCobrosUseCase, EliminarCobroUseCase, RenovarCxCUseCase,
} from './application/use-cases/cxc.use-cases';
import { CxCController } from './infrastructure/controllers/cxc.controller';

@Module({
  imports: [SupabaseModule, AuthModule],
  controllers: [CxCController],
  providers: [
    { provide: ICxCRepository, useClass: SupabaseCxCRepository },
    {
      provide: ListCxCUseCase,
      useFactory: (r: ICxCRepository) => new ListCxCUseCase(r),
      inject: [ICxCRepository],
    },
    {
      provide: FindCxCUseCase,
      useFactory: (r: ICxCRepository) => new FindCxCUseCase(r),
      inject: [ICxCRepository],
    },
    {
      provide: RegistrarCobroUseCase,
      useFactory: (r: ICxCRepository) => new RegistrarCobroUseCase(r),
      inject: [ICxCRepository],
    },
    {
      provide: GetCobrosUseCase,
      useFactory: (r: ICxCRepository) => new GetCobrosUseCase(r),
      inject: [ICxCRepository],
    },
    {
      provide: EliminarCobroUseCase,
      useFactory: (r: ICxCRepository) => new EliminarCobroUseCase(r),
      inject: [ICxCRepository],
    },
    {
      provide: RenovarCxCUseCase,
      useFactory: (r: ICxCRepository) => new RenovarCxCUseCase(r),
      inject: [ICxCRepository],
    },
  ],
})
export class CuentasCobrarModule {}
