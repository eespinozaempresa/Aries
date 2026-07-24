import { IsInt, IsNotEmpty, IsString, Length, Max, Min } from 'class-validator';

export class LoginDto {
  @IsString()
  @IsNotEmpty()
  @Length(1, 10)
  usuario: string;

  @IsString()
  @IsNotEmpty()
  clave: string;

  @IsInt()
  @Min(1)
  @Max(9)
  captchaA: number;

  @IsInt()
  @Min(1)
  @Max(9)
  captchaB: number;

  @IsInt()
  @Min(2)
  @Max(18)
  captchaAnswer: number;
}
