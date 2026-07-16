import { IsString, IsNotEmpty, IsOptional, IsBoolean, IsNumber, IsPositive, MaxLength, Min } from 'class-validator';

export class CreateTablaDto {
  @IsString() @IsNotEmpty() @MaxLength(5)
  codigo: string;

  @IsString() @IsNotEmpty() @MaxLength(100)
  descripcion: string;

  @IsBoolean() @IsOptional()
  activo?: boolean;
}

export class UpdateTablaDto {
  @IsString() @IsOptional() @MaxLength(100)
  descripcion?: string;

  @IsBoolean() @IsOptional()
  activo?: boolean;
}

export class CreateDocumentoDto extends CreateTablaDto {
  @IsString() @IsOptional() @MaxLength(5)
  abreviatura?: string;

  @IsString() @IsNotEmpty() @MaxLength(4)
  serie: string = '0001';

  @IsNumber() @Min(1) @IsOptional()
  numeroSiguiente?: number;

  @IsBoolean() @IsOptional()
  aplicaIgv?: boolean;

  @IsString() @IsOptional() @MaxLength(15)
  tipo?: string;
}

export class UpdateDocumentoDto {
  @IsString() @IsOptional() @MaxLength(100)
  descripcion?: string;

  @IsBoolean() @IsOptional()
  activo?: boolean;

  @IsString() @IsOptional() @MaxLength(5)
  abreviatura?: string;

  @IsString() @IsOptional() @MaxLength(4)
  serie?: string;

  @IsNumber() @Min(1) @IsOptional()
  numeroSiguiente?: number;

  @IsBoolean() @IsOptional()
  aplicaIgv?: boolean;

  @IsString() @IsOptional() @MaxLength(15)
  tipo?: string;
}
