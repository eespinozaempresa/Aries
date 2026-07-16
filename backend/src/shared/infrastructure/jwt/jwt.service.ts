import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as jwt from 'jsonwebtoken';
import * as crypto from 'crypto';
import { v4 as uuidv4 } from 'uuid';

export interface JwtPayload {
  sub: string;      // usuario.id (UUID)
  empresa: string;  // codigo_empresa
  codigo: string;   // usuario.codigo (VARCHAR 10) — usado en codigo_usuario de tablas
  nivel: string;
  iat?: number;
  exp?: number;
}

@Injectable()
export class JwtTokenService {
  private readonly secret: string;
  private readonly accessExpiry: string;

  constructor(private readonly config: ConfigService) {
    this.secret = this.config.getOrThrow<string>('jwt.secret');
    this.accessExpiry = this.config.get<string>('jwt.accessExpiry', '15m');
  }

  signAccessToken(payload: Omit<JwtPayload, 'iat' | 'exp'>): string {
    return jwt.sign(payload, this.secret, { expiresIn: this.accessExpiry as any });
  }

  verifyAccessToken(token: string): JwtPayload {
    return jwt.verify(token, this.secret) as JwtPayload;
  }

  generateRefreshToken(): { raw: string; hash: string } {
    const raw = uuidv4();
    const hash = this.hashToken(raw);
    return { raw, hash };
  }

  hashToken(token: string): string {
    return crypto.createHash('sha256').update(token).digest('hex');
  }
}
