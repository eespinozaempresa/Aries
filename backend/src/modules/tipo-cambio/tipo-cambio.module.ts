import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { ITipoCambioRepository } from './domain/ports/tipo-cambio.repository.port';
import { SupabaseTipoCambioRepository } from './infrastructure/repositories/supabase-tipo-cambio.repository';
import { GetTipoCambioHoyUseCase } from './application/use-cases/get-tipo-cambio-hoy.use-case';
import { GetTipoCambioByFechaUseCase } from './application/use-cases/get-tipo-cambio-by-fecha.use-case';
import { RegistrarTipoCambioUseCase } from './application/use-cases/registrar-tipo-cambio.use-case';
import { ListTipoCambioUseCase } from './application/use-cases/list-tipo-cambio.use-case';
import { UpdateTipoCambioUseCase } from './application/use-cases/update-tipo-cambio.use-case';
import { DeleteTipoCambioUseCase } from './application/use-cases/delete-tipo-cambio.use-case';
import { TipoCambioController } from './infrastructure/controllers/tipo-cambio.controller';

@Module({
  imports: [AuthModule],
  controllers: [TipoCambioController],
  providers: [
    { provide: ITipoCambioRepository, useClass: SupabaseTipoCambioRepository },
    GetTipoCambioHoyUseCase,
    GetTipoCambioByFechaUseCase,
    RegistrarTipoCambioUseCase,
    ListTipoCambioUseCase,
    UpdateTipoCambioUseCase,
    DeleteTipoCambioUseCase,
  ],
})
export class TipoCambioModule {}
