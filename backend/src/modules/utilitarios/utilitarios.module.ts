import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { SupabaseUtilitariosRepository } from './infrastructure/repositories/supabase-utilitarios.repository';
import { UtilitariosController } from './infrastructure/controllers/utilitarios.controller';

@Module({
  imports: [AuthModule],
  controllers: [UtilitariosController],
  providers: [SupabaseUtilitariosRepository],
})
export class UtilitariosModule {}
