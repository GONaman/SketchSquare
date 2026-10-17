import { HttpStatus, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { Role } from '@prisma/client';
import { createHmac, randomBytes, randomUUID } from 'node:crypto';
import { ApiException } from '../../common/errors/api-exception';
import { Env } from '../../config/env.schema';
import { PrismaService } from '../../prisma/prisma.service';
import { AccessTokenPayload, Tokens } from '../auth.types';

const DAY_MS = 24 * 60 * 60 * 1000;

@Injectable()
export class TokenService {
  constructor(
    private readonly jwt: JwtService,
    private readonly prisma: PrismaService,
    private readonly config: ConfigService<Env, true>,
  ) {}

  /** Starts a new refresh-token family (one per login/signup). */
  issueTokens(user: { id: string; role: Role }): Promise<Tokens> {
    return this.createTokens(user, randomUUID()).then((t) => ({
      accessToken: t.accessToken,
      refreshToken: t.refreshToken,
      expiresIn: t.expiresIn,
    }));
  }

  /**
   * Exchanges a refresh token for a new pair. The old token is revoked atomically; presenting an
   * already-revoked token means it leaked, so the whole family is revoked and the call fails with 401.
   * Returns the new tokens plus the owner's id.
   */
  async rotate(refreshToken: string): Promise<Tokens & { userId: string }> {
    const stored = await this.prisma.refreshToken.findUnique({
      where: { tokenHash: this.hash(refreshToken) },
      include: { user: { select: { id: true, role: true } } },
    });
    if (!stored) throw this.invalidRefresh();

    if (stored.revokedAt) {
      await this.revokeFamily(stored.familyId);
      throw this.invalidRefresh('Refresh token reuse detected');
    }
    if (stored.expiresAt <= new Date()) throw this.invalidRefresh();

    // updateMany with `revokedAt: null` makes concurrent use of the same token race-safe: only one wins.
    const claimed = await this.prisma.refreshToken.updateMany({
      where: { id: stored.id, revokedAt: null },
      data: { revokedAt: new Date() },
    });
    if (claimed.count !== 1) {
      await this.revokeFamily(stored.familyId);
      throw this.invalidRefresh('Refresh token reuse detected');
    }

    const { tokenId, ...tokens } = await this.createTokens(
      stored.user,
      stored.familyId,
    );
    await this.prisma.refreshToken.update({
      where: { id: stored.id },
      data: { replacedById: tokenId },
    });
    return { ...tokens, userId: stored.user.id };
  }

  /** Logout: revokes the whole session (family). Unknown tokens are ignored so logout is idempotent. */
  async revoke(refreshToken: string): Promise<void> {
    const stored = await this.prisma.refreshToken.findUnique({
      where: { tokenHash: this.hash(refreshToken) },
      select: { familyId: true },
    });
    if (stored) await this.revokeFamily(stored.familyId);
  }

  /** Used after a password reset so stolen sessions die. */
  async revokeAllForUser(userId: string): Promise<void> {
    await this.prisma.refreshToken.updateMany({
      where: { userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }

  private async createTokens(
    user: { id: string; role: Role },
    familyId: string,
  ): Promise<Tokens & { tokenId: string }> {
    const expiresIn = this.config.get('JWT_ACCESS_TTL_SECONDS', {
      infer: true,
    });
    const payload: AccessTokenPayload = { sub: user.id, role: user.role };
    const accessToken = await this.jwt.signAsync(payload, {
      secret: this.config.get('JWT_ACCESS_SECRET', { infer: true }),
      expiresIn,
      algorithm: 'HS256',
    });

    const refreshToken = randomBytes(48).toString('base64url');
    const ttlDays = this.config.get('JWT_REFRESH_TTL_DAYS', { infer: true });
    const row = await this.prisma.refreshToken.create({
      select: { id: true },
      data: {
        userId: user.id,
        familyId,
        tokenHash: this.hash(refreshToken),
        expiresAt: new Date(Date.now() + ttlDays * DAY_MS),
      },
    });
    return { accessToken, refreshToken, expiresIn, tokenId: row.id };
  }

  private async revokeFamily(familyId: string): Promise<void> {
    await this.prisma.refreshToken.updateMany({
      where: { familyId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }

  /** Keyed hash: a DB leak alone is not enough to forge lookups of tokens. */
  private hash(token: string): string {
    return createHmac(
      'sha256',
      this.config.get('JWT_REFRESH_SECRET', { infer: true }),
    )
      .update(token)
      .digest('hex');
  }

  private invalidRefresh(message = 'Invalid refresh token'): ApiException {
    return new ApiException(HttpStatus.UNAUTHORIZED, 'UNAUTHORIZED', message);
  }
}
