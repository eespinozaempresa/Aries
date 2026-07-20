import { IsString, IsNumber, IsEnum, IsOptional, IsDateString, IsUUID, Min } from 'class-validator';

export class AbrirCajaDto {
  @IsString() codigoCaja: string;
  @IsNumber() @Min(0) montoApertura: number;
}

export class CerrarCajaDto {
  @IsNumber() @Min(0) montosCierre: number;
}

export class RegistrarMovCajaDto {
  @IsUUID() sesionCajaId: string;
  @IsEnum(['INGRESO', 'EGRESO']) tipo: 'INGRESO' | 'EGRESO';
  @IsString() concepto: string;
  @IsOptional() @IsString() referencia?: string;
  @IsOptional() @IsString() tipoPago?: string;
  @IsNumber() @Min(0.01) monto: number;
  @IsDateString() fecha: string;
}
