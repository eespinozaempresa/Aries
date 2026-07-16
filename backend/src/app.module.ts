import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import configuration from './config/configuration';
import { SupabaseModule } from './shared/infrastructure/supabase/supabase.module';
import { AuthModule } from './modules/auth/auth.module';
import { TablasModule } from './modules/tablas/tablas.module';
import { MaestrosModule } from './modules/maestros/maestros.module';
import { AlmacenModule } from './modules/almacen/almacen.module';
import { ComprasModule } from './modules/compras/compras.module';
import { VentasModule } from './modules/ventas/ventas.module';
import { CuentasCobrarModule } from './modules/cuentas-cobrar/cuentas-cobrar.module';
import { CuentasPagarModule } from './modules/cuentas-pagar/cuentas-pagar.module';
import { CajaModule } from './modules/caja/caja.module';
import { TipoCambioModule } from './modules/tipo-cambio/tipo-cambio.module';
import { UtilitariosModule } from './modules/utilitarios/utilitarios.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, load: [configuration] }),
    SupabaseModule,
    AuthModule,
    TipoCambioModule,
    TablasModule,
    MaestrosModule,
    AlmacenModule,
    ComprasModule,
    VentasModule,
    CuentasCobrarModule,
    CuentasPagarModule,
    CajaModule,
    UtilitariosModule,
  ],
})
export class AppModule {}
