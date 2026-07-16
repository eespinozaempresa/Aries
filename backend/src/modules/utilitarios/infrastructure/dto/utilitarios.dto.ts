import {
  IsInt, IsNumber, IsString, IsNotEmpty, Length,
  IsOptional, Min, Max, IsIn,
} from 'class-validator';

export class UpdateParametrosDto {
  @IsNumber()
  @Min(0)
  @Max(100)
  igv: number;

  @IsInt()
  @Min(1)
  @Max(365)
  tiempoFinanciamiento: number;
}

export class CreateUsuarioDto {
  @IsString()
  @IsNotEmpty()
  @Length(1, 10)
  codigo: string;

  @IsString()
  @IsNotEmpty()
  @Length(1, 80)
  nombre: string;

  @IsString()
  @IsNotEmpty()
  clave: string;

  @IsString()
  @IsIn(['ADMIN', 'supervisor', 'operador'])
  nivel: string;

  @IsOptional()
  @IsString()
  email?: string;
}

export class UpdateUsuarioDto {
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @Length(1, 80)
  nombre?: string;

  @IsOptional()
  @IsString()
  @IsIn(['ADMIN', 'supervisor', 'operador'])
  nivel?: string;

  @IsOptional()
  @IsString()
  email?: string;
}
