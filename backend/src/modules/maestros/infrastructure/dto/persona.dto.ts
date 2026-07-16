import {
  IsString, IsOptional, IsBoolean, IsEmail,
  MaxLength, MinLength,
} from 'class-validator';

export class CreatePersonaDto {
  @IsString() @MinLength(1) @MaxLength(10)
  codigo: string;

  @IsString() @MinLength(1) @MaxLength(100)
  razonSocial: string;

  @IsOptional() @IsString() @MaxLength(100)
  direccion?: string;

  @IsOptional() @IsString() @MaxLength(15)
  rucDni?: string;

  @IsOptional() @IsString() @MaxLength(20)
  telefono?: string;

  @IsOptional() @IsString() @MaxLength(20)
  celular?: string;

  @IsOptional() @IsEmail()
  email?: string;
}

export class UpdatePersonaDto {
  @IsOptional() @IsString() @MinLength(1) @MaxLength(100)
  razonSocial?: string;

  @IsOptional() @IsString() @MaxLength(100)
  direccion?: string;

  @IsOptional() @IsString() @MaxLength(15)
  rucDni?: string;

  @IsOptional() @IsString() @MaxLength(20)
  telefono?: string;

  @IsOptional() @IsString() @MaxLength(20)
  celular?: string;

  @IsOptional() @IsEmail()
  email?: string;

  @IsOptional() @IsBoolean()
  activo?: boolean;
}
