import { Global, Module } from '@nestjs/common';
import { SupabaseService } from './supabase.service';
import { NumeroDocumentoService } from './numero-documento.service';

@Global()
@Module({
  providers: [SupabaseService, NumeroDocumentoService],
  exports: [SupabaseService, NumeroDocumentoService],
})
export class SupabaseModule {}
