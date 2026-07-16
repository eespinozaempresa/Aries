import { IsNumber, Min, Max } from 'class-validator';

export class RegistrarTipoCambioDto {
  @IsNumber({ maxDecimalPlaces: 4 })
  @Min(0.0001)
  @Max(99999)
  tipoCambio: number;
}
