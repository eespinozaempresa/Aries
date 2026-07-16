import { IsString, IsNumber, IsEnum, IsOptional, IsDateString, Min } from 'class-validator';

export class RegistrarPagoDto {
  @IsString() cuentaPagarId: string;
  @IsString() numeroVoucher: string;
  @IsDateString() fecha: string;
  @IsEnum(['EFECTIVO', 'TRANSFERENCIA', 'CHEQUE']) tipoPago: 'EFECTIVO' | 'TRANSFERENCIA' | 'CHEQUE';
  @IsOptional() @IsString() numeroOperacion?: string;
  @IsOptional() @IsString() codigoBanco?: string;
  @IsNumber() @Min(0.01) monto: number;
}

export class RenovarCxPDto {
  @IsDateString() nuevaFechaVencimiento: string;
  @IsOptional() @IsNumber() @Min(0) interes?: number;
  @IsString() codigoDocumento: string;
  @IsString() numeroDocumento: string;
}
