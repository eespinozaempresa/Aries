import {
  IsString, IsNotEmpty, IsDateString, IsEnum, IsOptional,
  IsArray, ArrayMinSize, ValidateNested, IsNumber, IsPositive, Min, IsInt,
} from 'class-validator';
import { Type } from 'class-transformer';

export class LineaCompraDto {
  @IsString() @IsNotEmpty()
  codigoArticulo: string;

  @IsNumber({ maxDecimalPlaces: 4 }) @IsPositive()
  cantidad: number;

  @IsNumber({ maxDecimalPlaces: 4 }) @Min(0)
  precioUnitario: number;

  @IsDateString() @IsOptional()
  fechaVencimiento?: string;
}

export class RegistrarCompraDto {
  @IsString() @IsNotEmpty()
  codigoDocumento: string;

  @IsString() @IsNotEmpty()
  serie: string;

  @IsDateString()
  fecha: string;

  @IsEnum(['CONTADO', 'CREDITO'])
  formaPago: 'CONTADO' | 'CREDITO';

  @IsInt() @Min(0) @IsOptional()
  plazoDias?: number;

  @IsDateString() @IsOptional()
  fechaVencimiento?: string;

  @IsString() @IsOptional()
  observacion?: string;

  @IsString() @IsNotEmpty()
  codigoAlmacen: string;

  @IsString() @IsNotEmpty()
  codigoProveedor: string;

  @IsEnum(['PEN', 'USD']) @IsOptional()
  moneda?: string;

  @IsNumber({ maxDecimalPlaces: 4 }) @IsOptional() @Min(0.0001)
  tipoCambio?: number;

  @IsArray() @ArrayMinSize(1) @ValidateNested({ each: true }) @Type(() => LineaCompraDto)
  lineas: LineaCompraDto[];
}
