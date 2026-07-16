import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { SupabaseService } from './supabase.service';

@Injectable()
export class NumeroDocumentoService {
  constructor(private readonly supabase: SupabaseService) {}

  async siguiente(codigoEmpresa: string, codigoDocumento: string, serie: string): Promise<string> {
    const { data, error } = await this.supabase.db.rpc('siguiente_numero_doc', {
      p_empresa: codigoEmpresa,
      p_cod_doc: codigoDocumento,
      p_serie:   serie,
    });
    if (error) throw new InternalServerErrorException(`Autonumeración: ${error.message}`);
    return data as string;
  }
}
