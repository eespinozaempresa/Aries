import { Module } from '@nestjs/common';
import { SupabaseModule } from '../../shared/infrastructure/supabase/supabase.module';
import { AuthModule } from '../auth/auth.module';
import { ICajaRepository } from './domain/ports/caja.repository.port';
import { SupabaseCajaRepository } from './infrastructure/repositories/supabase-caja.repository';
import {
  ListCajaUseCase, FindSesionUseCase, AbrirCajaUseCase,
  CerrarCajaUseCase, RegistrarMovCajaUseCase, ReporteCajaUseCase,
} from './application/use-cases/caja.use-cases';
import { CajaController } from './infrastructure/controllers/caja.controller';

@Module({
  imports: [SupabaseModule, AuthModule],
  controllers: [CajaController],
  providers: [
    { provide: ICajaRepository, useClass: SupabaseCajaRepository },
    {
      provide: ListCajaUseCase,
      useFactory: (r: ICajaRepository) => new ListCajaUseCase(r),
      inject: [ICajaRepository],
    },
    {
      provide: FindSesionUseCase,
      useFactory: (r: ICajaRepository) => new FindSesionUseCase(r),
      inject: [ICajaRepository],
    },
    {
      provide: AbrirCajaUseCase,
      useFactory: (r: ICajaRepository) => new AbrirCajaUseCase(r),
      inject: [ICajaRepository],
    },
    {
      provide: CerrarCajaUseCase,
      useFactory: (r: ICajaRepository) => new CerrarCajaUseCase(r),
      inject: [ICajaRepository],
    },
    {
      provide: RegistrarMovCajaUseCase,
      useFactory: (r: ICajaRepository) => new RegistrarMovCajaUseCase(r),
      inject: [ICajaRepository],
    },
    {
      provide: ReporteCajaUseCase,
      useFactory: (r: ICajaRepository) => new ReporteCajaUseCase(r),
      inject: [ICajaRepository],
    },
  ],
})
export class CajaModule {}
