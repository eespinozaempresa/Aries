import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { ITipoCambioRepository } from './domain/ports/tipo-cambio.repository.port';
import { SupabaseTipoCambioRepository } from './infrastructure/repositories/supabase-tipo-cambio.repository';
import { GetTipoCambioHoyUseCase } from './application/use-cases/get-tipo-cambio-hoy.use-case';
import { RegistrarTipoCambioUseCase } from './application/use-cases/registrar-tipo-cambio.use-case';
import { TipoCambioController } from './infrastructure/controllers/tipo-cambio.controller';

@Module({
  imports: [AuthModule],
  controllers: [TipoCambioController],
  providers: [
    { provide: ITipoCambioRepository, useClass: SupabaseTipoCambioRepository },
    GetTipoCambioHoyUseCase,
    RegistrarTipoCambioUseCase,
  ],
})
export class TipoCambioModule {}
