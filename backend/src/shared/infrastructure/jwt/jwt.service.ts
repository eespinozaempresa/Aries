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

export interface PreAuthPayload {
  purpose: 'SELECT_EMPRESA';
  codigo: string;       // usuario.codigo, identidad validada por clave (sin empresa aún)
  empresas: string[];   // códigos de empresa donde la clave fue validada
  iat?: number;
  exp?: number;
}

@Injectable()
export class JwtTokenService {
  private readonly secret: string;
  private readonly accessExpiry: string;
  private readonly preAuthExpiry: string;

  constructor(private readonly config: ConfigService) {
    this.secret = this.config.getOrThrow<string>('jwt.secret');
    this.accessExpiry = this.config.get<string>('jwt.accessExpiry', '15m');
    this.preAuthExpiry = this.config.get<string>('jwt.preAuthExpiry', '10m');
  }

  signAccessToken(payload: Omit<JwtPayload, 'iat' | 'exp'>): string {
    return jwt.sign(payload, this.secret, { expiresIn: this.accessExpiry as any });
  }

  verifyAccessToken(token: string): JwtPayload {
    return jwt.verify(token, this.secret) as JwtPayload;
  }

  signPreAuthToken(payload: Omit<PreAuthPayload, 'iat' | 'exp'>): string {
    return jwt.sign(payload, this.secret, { expiresIn: this.preAuthExpiry as any });
  }

  verifyPreAuthToken(token: string): PreAuthPayload {
    return jwt.verify(token, this.secret) as PreAuthPayload;
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
