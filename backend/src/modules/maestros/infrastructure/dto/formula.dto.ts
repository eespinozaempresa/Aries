import {
  IsString, IsOptional, IsBoolean, IsNumber, IsPositive, IsInt,
  MaxLength, MinLength, IsArray, ArrayMinSize, ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

export class DetalleFormulaDto {
  @IsString() @MinLength(1) @MaxLength(10)
  codigoArticulo: string;

  @IsNumber({ maxDecimalPlaces: 4 }) @IsPositive()
  cantidad: number;

  @IsOptional() @IsInt()
  orden?: number;
}

export class CreateFormulaDto {
  @IsString() @MinLength(1) @MaxLength(10)
  codigoArticulo: string;

  @IsOptional() @IsString() @MaxLength(150)
  observacion?: string;

  @IsOptional() @IsBoolean()
  activo?: boolean;

  @IsArray() @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => DetalleFormulaDto)
  detalle: DetalleFormulaDto[];
}

export class UpdateFormulaDto {
  @IsString() @MinLength(1) @MaxLength(10)
  codigoArticulo: string;

  @IsOptional() @IsString() @MaxLength(150)
  observacion?: string;

  @IsOptional() @IsBoolean()
  activo?: boolean;

  @IsArray() @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => DetalleFormulaDto)
  detalle: DetalleFormulaDto[];
}
