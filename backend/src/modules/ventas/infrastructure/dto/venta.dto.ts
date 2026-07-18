import {
  IsString, IsNotEmpty, IsDateString, IsEnum, IsOptional,
  IsArray, ArrayMinSize, ValidateNested, IsNumber, IsPositive, Min, IsInt, Max,
} from 'class-validator';
import { Type } from 'class-transformer';

export class LineaVentaDto {
  @IsString() @IsNotEmpty()
  codigoArticulo: string;

  @IsNumber({ maxDecimalPlaces: 4 }) @IsPositive()
  cantidad: number;

  @IsNumber({ maxDecimalPlaces: 4 }) @Min(0)
  precioUnitario: number;

  @IsNumber({ maxDecimalPlaces: 2 }) @Min(0) @Max(100) @IsOptional()
  descuentoPct?: number;
}

export class RegistrarVentaDto {
  @IsString() @IsNotEmpty()
  codigoDocumento: string;

  @IsString() @IsNotEmpty()
  serie: string;

  @IsDateString()
  fecha: string;

  @IsString() @IsOptional()
  observacion?: string;

  @IsString() @IsNotEmpty()
  codigoAlmacen: string;

  @IsString() @IsNotEmpty()
  codigoCliente: string;

  @IsEnum(['CONTADO', 'CREDITO'])
  tipoVenta: 'CONTADO' | 'CREDITO';

  @IsInt() @Min(0) @IsOptional()
  plazoDias?: number;

  @IsString() @IsOptional()
  moneda?: string;

  @IsNumber({ maxDecimalPlaces: 4 }) @Min(0.0001) @IsOptional()
  tipoCambio?: number;

  @IsArray() @ArrayMinSize(1) @ValidateNested({ each: true }) @Type(() => LineaVentaDto)
  lineas: LineaVentaDto[];
}
