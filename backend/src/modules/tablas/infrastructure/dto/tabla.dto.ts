import { IsString, IsNotEmpty, IsOptional, IsBoolean, IsNumber, IsPositive, MaxLength, Min, IsUUID } from 'class-validator';

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

export class CreateTipoListaDto extends CreateTablaDto {
  @IsNumber({ maxDecimalPlaces: 2 }) @Min(0) @IsOptional()
  dsctoPct?: number;

  @IsNumber({ maxDecimalPlaces: 4 }) @Min(0) @IsOptional()
  dctoMto?: number;
}

export class UpdateTipoListaDto extends UpdateTablaDto {
  @IsNumber({ maxDecimalPlaces: 2 }) @Min(0) @IsOptional()
  dsctoPct?: number;

  @IsNumber({ maxDecimalPlaces: 4 }) @Min(0) @IsOptional()
  dctoMto?: number;
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
