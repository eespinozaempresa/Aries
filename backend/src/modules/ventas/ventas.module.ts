import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { SupabaseModule } from '../../shared/infrastructure/supabase/supabase.module';
import { IVentaRepository } from './domain/ports/venta.repository.port';
import { SupabaseVentaRepository } from './infrastructure/repositories/supabase-venta.repository';
import { RegistrarVentaUseCase } from './application/use-cases/registrar-venta.use-case';
import { AnularVentaUseCase } from './application/use-cases/anular-venta.use-case';
import { ListVentasUseCase } from './application/use-cases/list-ventas.use-case';
import { ReporteUtilidadUseCase } from './application/use-cases/reporte-utilidad.use-case';
import { VentasController } from './infrastructure/controllers/ventas.controller';

@Module({
  imports: [SupabaseModule, AuthModule],
  controllers: [VentasController],
  providers: [
    { provide: IVentaRepository, useClass: SupabaseVentaRepository },
    RegistrarVentaUseCase,
    AnularVentaUseCase,
    ListVentasUseCase,
    ReporteUtilidadUseCase,
  ],
  exports: [IVentaRepository],
})
export class VentasModule {}
