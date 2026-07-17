import {
  IsString, IsOptional, IsBoolean, IsIn,
  MaxLength, MinLength,
} from 'class-validator';

export class CreateAlmacenDto {
  @IsString() @MinLength(1) @MaxLength(5)
  codigo: string;

  @IsOptional() @IsBoolean()
  activo?: boolean;

  @IsString() @MinLength(1) @MaxLength(60)
  descripcion: string;

  @IsOptional() @IsString() @MaxLength(15)
  abreviatura?: string;

  @IsOptional() @IsString() @MaxLength(80)
  ubicacion?: string;

  @IsOptional() @IsString() @IsIn(['ALMACEN', 'TIENDA', 'TRANSITO'])
  tipo?: string;
}

export class UpdateAlmacenDto {
  @IsOptional() @IsString() @MinLength(1) @MaxLength(60)
  descripcion?: string;

  @IsOptional() @IsString() @MaxLength(15)
  abreviatura?: string;

  @IsOptional() @IsString() @MaxLength(80)
  ubicacion?: string;

  @IsOptional() @IsString() @IsIn(['ALMACEN', 'TIENDA', 'TRANSITO'])
  tipo?: string;

  @IsOptional() @IsBoolean()
  activo?: boolean;
}
