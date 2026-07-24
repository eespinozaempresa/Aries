import { IsNotEmpty, IsString, Length } from 'class-validator';

export class SeleccionarEmpresaDto {
  @IsString()
  @IsNotEmpty()
  @Length(1, 10)
  codigoEmpresa: string;
}
