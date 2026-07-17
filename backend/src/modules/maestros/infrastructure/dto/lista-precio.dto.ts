import { IsUUID, IsNumber, IsBoolean, IsOptional, Min } from 'class-validator';

export class CreateListaPrecioDto {
  @IsUUID()
  idArticulo: string;

  @IsUUID()
  idTipoLista: string;

  @IsNumber({ maxDecimalPlaces: 4 }) @Min(0)
  precioVentaBase: number;

  @IsNumber({ maxDecimalPlaces: 2 }) @Min(0)
  descuentoPct: number;

  @IsNumber({ maxDecimalPlaces: 4 }) @Min(0)
  descuentoMonto: number;

  @IsNumber({ maxDecimalPlaces: 4 }) @Min(0)
  precioVenta: number;

  @IsOptional() @IsBoolean()
  activo?: boolean;
}

export class UpdateListaPrecioDto {
  @IsOptional() @IsUUID()
  idTipoLista?: string;

  @IsOptional() @IsNumber({ maxDecimalPlaces: 4 }) @Min(0)
  precioVentaBase?: number;

  @IsOptional() @IsNumber({ maxDecimalPlaces: 2 }) @Min(0)
  descuentoPct?: number;

  @IsOptional() @IsNumber({ maxDecimalPlaces: 4 }) @Min(0)
  descuentoMonto?: number;

  @IsOptional() @IsNumber({ maxDecimalPlaces: 4 }) @Min(0)
  precioVenta?: number;

  @IsOptional() @IsBoolean()
  activo?: boolean;
}
