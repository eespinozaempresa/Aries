import { IsString, IsNumber, IsEnum, IsOptional, IsDateString, IsArray, ValidateNested, Min } from 'class-validator';
import { Type } from 'class-transformer';

export class RegistrarCobroDto {
  @IsString() cuentaCobrarId: string;
  @IsString() numeroRecibo: string;
  @IsDateString() fecha: string;
  @IsEnum(['EFECTIVO', 'TRANSFERENCIA', 'CHEQUE']) tipoPago: 'EFECTIVO' | 'TRANSFERENCIA' | 'CHEQUE';
  @IsOptional() @IsString() numeroOperacion?: string;
  @IsOptional() @IsString() codigoBanco?: string;
  @IsNumber() @Min(0.01) monto: number;
}

export class CuotaRenovacionDto {
  @IsNumber() numeroCuota: number;
  @IsString() numeroLetra: string;
  @IsDateString() fechaVencimiento: string;
  @IsNumber() @Min(0.01) monto: number;
}

export class RenovarCxCDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CuotaRenovacionDto)
  cuotas: CuotaRenovacionDto[];
}
