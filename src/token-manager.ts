import jwt from 'jsonwebtoken';

interface TokenCacheEntry {
  token: string;
  expiresAt: number; // epoch seconds
}

export class TokenManager {
  private secret: string;
  private subject: string;
  private ttlSeconds: number;
  private refreshBufferSeconds: number;
  private cache: TokenCacheEntry | null = null;

  constructor(options?: {
    secret?: string;
    subject?: string;
    ttlSeconds?: number;
    refreshBufferSeconds?: number;
  }) {
    this.secret = options?.secret || process.env['JWT_SECRET'] || '';
    this.subject = options?.subject || process.env['JWT_SUB'] || 'scheduler-app';
    this.ttlSeconds = options?.ttlSeconds || Number(process.env['JWT_TTL_SECONDS'] || 60 * 24 * 60 * 60);
    this.refreshBufferSeconds = options?.refreshBufferSeconds || Number(process.env['JWT_REFRESH_BUFFER_SECONDS'] || 60 * 60);

    if (!this.secret) {
      throw new Error('TokenManager requires JWT_SECRET to be set');
    }
  }

  public getToken(): string {
    const now = Math.floor(Date.now() / 1000);
    if (this.cache && (this.cache.expiresAt - now) > this.refreshBufferSeconds) {
      return this.cache.token;
    }

    const iat = now;
    const exp = now + this.ttlSeconds;
    const token = jwt.sign({ sub: this.subject, iat, exp }, this.secret);
    this.cache = { token, expiresAt: exp };
    return token;
  }

  public getExpiresAt(): number | null {
    return this.cache?.expiresAt || null;
  }

  public isEnabled(): boolean {
    return !!this.secret;
  }
}


