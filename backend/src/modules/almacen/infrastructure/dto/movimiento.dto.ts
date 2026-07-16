import {
  IsString, IsNotEmpty, IsDateString, IsEnum, IsOptional,
  IsArray, ArrayMinSize, ValidateNested, IsNumber, IsPositive, Min,
} from 'class-validator';
import { Type } from 'class-transformer';

export class LineaMovimientoDto {
  @IsString() @IsNotEmpty()
  codigoArticulo: string;

  @IsNumber({ maxDecimalPlaces: 4 }) @IsPositive()
  cantidad: number;

  @IsNumber({ maxDecimalPlaces: 4 }) @Min(0)
  precioUnitario: number;
}

export class RegistrarMovimientoDto {
  @IsString() @IsNotEmpty()
  codigoDocumento: string;

  @IsString() @IsNotEmpty()
  serie: string;

  @IsDateString()
  fecha: string;

  @IsEnum(['INGRESO', 'SALIDA', 'TRASLADO'])
  tipo: 'INGRESO' | 'SALIDA' | 'TRASLADO';

  @IsString() @IsNotEmpty()
  codigoAlmacenOrigen: string;

  @IsString() @IsOptional()
  codigoAlmacenDest?: string;

  @IsString() @IsOptional()
  observacion?: string;

  @IsString() @IsOptional()
  concepto?: string;

  @IsArray() @ArrayMinSize(1) @ValidateNested({ each: true }) @Type(() => LineaMovimientoDto)
  lineas: LineaMovimientoDto[];
}
