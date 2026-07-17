import {
  IsString, IsOptional, IsNumber, IsBoolean, IsDateString,
  MaxLength, MinLength, Min,
} from 'class-validator';

export class CreateArticuloDto {
  @IsString() @MinLength(1) @MaxLength(10)
  codigo: string;

  @IsOptional() @IsBoolean()
  activo?: boolean;

  @IsString() @MinLength(1) @MaxLength(150)
  descripcion: string;

  @IsOptional() @IsString() @MaxLength(5)
  codigoLinea?: string;

  @IsOptional() @IsString() @MaxLength(5)
  codigoMedida?: string;

  @IsOptional() @IsString() @MaxLength(5)
  codigoMarca?: string;

  @IsOptional() @IsNumber({ maxDecimalPlaces: 4 }) @Min(0)
  precioCompraBase?: number;

  @IsOptional() @IsNumber({ maxDecimalPlaces: 4 }) @Min(0)
  igvCompra?: number;

  @IsOptional() @IsNumber({ maxDecimalPlaces: 4 }) @Min(0)
  precioCompra?: number;

  @IsOptional() @IsNumber({ maxDecimalPlaces: 2 }) @Min(0)
  utilidadPct?: number;

  @IsOptional() @IsNumber({ maxDecimalPlaces: 4 }) @Min(0)
  precioVentaBase?: number;

  @IsOptional() @IsNumber({ maxDecimalPlaces: 4 }) @Min(0)
  igvVenta?: number;

  @IsOptional() @IsNumber({ maxDecimalPlaces: 4 }) @Min(0)
  precioVenta?: number;

  @IsOptional() @IsDateString()
  fechaRegistro?: string;

  @IsOptional() @IsDateString()
  fechaVencimiento?: string;

  @IsOptional() @IsNumber({ maxDecimalPlaces: 4 }) @Min(0)
  stockMinimo?: number;

  @IsOptional() @IsNumber({ maxDecimalPlaces: 4 }) @Min(0)
  stockMaximo?: number;

  @IsOptional() @IsString() @MaxLength(50)
  codigoBarras?: string;
}

export class UpdateArticuloDto {
  @IsOptional() @IsString() @MinLength(1) @MaxLength(150)
  descripcion?: string;

  @IsOptional() @IsString() @MaxLength(5)
  codigoLinea?: string;

  @IsOptional() @IsString() @MaxLength(5)
  codigoMedida?: string;

  @IsOptional() @IsString() @MaxLength(5)
  codigoMarca?: string;

  @IsOptional() @IsNumber({ maxDecimalPlaces: 4 }) @Min(0)
  precioCompraBase?: number;

  @IsOptional() @IsNumber({ maxDecimalPlaces: 4 }) @Min(0)
  igvCompra?: number;

  @IsOptional() @IsNumber({ maxDecimalPlaces: 4 }) @Min(0)
  precioCompra?: number;

  @IsOptional() @IsNumber({ maxDecimalPlaces: 2 }) @Min(0)
  utilidadPct?: number;

  @IsOptional() @IsNumber({ maxDecimalPlaces: 4 }) @Min(0)
  precioVentaBase?: number;

  @IsOptional() @IsNumber({ maxDecimalPlaces: 4 }) @Min(0)
  igvVenta?: number;

  @IsOptional() @IsNumber({ maxDecimalPlaces: 4 }) @Min(0)
  precioVenta?: number;

  @IsOptional() @IsDateString()
  fechaRegistro?: string;

  @IsOptional() @IsDateString()
  fechaVencimiento?: string;

  @IsOptional() @IsNumber({ maxDecimalPlaces: 4 }) @Min(0)
  stockMinimo?: number;

  @IsOptional() @IsNumber({ maxDecimalPlaces: 4 }) @Min(0)
  stockMaximo?: number;

  @IsOptional() @IsString() @MaxLength(50)
  codigoBarras?: string;

  @IsOptional() @IsBoolean()
  activo?: boolean;
}
