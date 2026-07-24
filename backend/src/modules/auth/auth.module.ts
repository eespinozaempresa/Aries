import { Module } from '@nestjs/common';
import { JwtTokenService } from '../../shared/infrastructure/jwt/jwt.service';
import { AuthGuard } from '../../shared/infrastructure/guards/auth.guard';
// SupabaseService is @Global — injected automatically via SupabaseModule
import { IUsuarioRepository } from './domain/ports/usuario.repository.port';
import { ISessionRepository } from './domain/ports/session.repository.port';
import { IBloqueoRepository } from './domain/ports/bloqueo.repository.port';
import { ITiemposConfigRepository } from './domain/ports/tiempos-config.repository.port';
import { SupabaseUsuarioRepository } from './infrastructure/repositories/supabase-usuario.repository';
import { SupabaseSessionRepository } from './infrastructure/repositories/supabase-session.repository';
import { SupabaseBloqueoRepository } from './infrastructure/repositories/supabase-bloqueo.repository';
import { SupabaseTiemposConfigRepository } from './infrastructure/repositories/supabase-tiempos-config.repository';
import { LoginUseCase } from './application/use-cases/login.use-case';
import { LogoutUseCase } from './application/use-cases/logout.use-case';
import { RefreshTokenUseCase } from './application/use-cases/refresh-token.use-case';
import { AuthController } from './infrastructure/controllers/auth.controller';

@Module({
  controllers: [AuthController],
  providers: [
    JwtTokenService,
    AuthGuard,
    { provide: IUsuarioRepository, useClass: SupabaseUsuarioRepository },
    { provide: ISessionRepository, useClass: SupabaseSessionRepository },
    { provide: IBloqueoRepository, useClass: SupabaseBloqueoRepository },
    { provide: ITiemposConfigRepository, useClass: SupabaseTiemposConfigRepository },
    LoginUseCase,
    LogoutUseCase,
    RefreshTokenUseCase,
  ],
  exports: [JwtTokenService, AuthGuard, IBloqueoRepository],
})
export class AuthModule {}
