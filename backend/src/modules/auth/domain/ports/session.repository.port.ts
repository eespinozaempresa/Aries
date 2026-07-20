export interface StoreRefreshTokenParams {
  usuarioId: string;
  tokenHash: string;
  expiresAt: Date;
}

export interface LogAuditParams {
  codigoEmpresa: string;
  usuarioId?: string;
  usuarioCodigo?: string;
  tipo: 'LOGIN' | 'LOGIN_FAIL' | 'LOGOUT';
  ip?: string;
  dispositivo?: string;
}

export abstract class ISessionRepository {
  abstract storeRefreshToken(params: StoreRefreshTokenParams): Promise<void>;
  abstract findValidRefreshToken(tokenHash: string): Promise<{ usuarioId: string; expiresAt: Date } | null>;
  abstract revokeRefreshToken(tokenHash: string): Promise<void>;
  abstract revokeAllUserTokens(usuarioId: string): Promise<void>;
  abstract logAudit(params: LogAuditParams): Promise<void>;
}
