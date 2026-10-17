import { HttpStatus, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHash, randomBytes } from 'node:crypto';
import { ApiException } from '../common/errors/api-exception';
import { Env } from '../config/env.schema';
import { MailService } from '../mail/mail.service';
import { PrismaService } from '../prisma/prisma.service';
import { Tokens } from './auth.types';
import {
  ForgotPasswordDto,
  LoginDto,
  ResetPasswordDto,
  SignupDto,
} from './dto/auth.dto';
import { PasswordService } from './password/password.service';
import { TokenService } from './tokens/token.service';
import { toUserResponse } from './user.mapper';

@Injectable()
export class AuthService {
  // Verified against when the email is unknown so login timing does not reveal which emails exist.
  private dummyHash?: Promise<string>;

  constructor(
    private readonly prisma: PrismaService,
    private readonly passwords: PasswordService,
    private readonly tokens: TokenService,
    private readonly mail: MailService,
    private readonly config: ConfigService<Env, true>,
  ) {}

  async signup(dto: SignupDto) {
    const existing = await this.prisma.user.findUnique({
      where: { email: dto.email },
      select: { id: true },
    });
    if (existing) this.emailTaken();

    const user = await this.prisma.user
      .create({
        data: {
          email: dto.email,
          passwordHash: await this.passwords.hash(dto.password),
          fullName: dto.fullName,
          phone: dto.phone,
          address: dto.address,
          city: dto.city,
        },
      })
      // A concurrent signup with the same email trips the unique index.
      .catch((e: { code?: string }) => {
        if (e.code === 'P2002') this.emailTaken();
        throw e;
      });
    return {
      user: this.userJson(user),
      tokens: await this.tokens.issueTokens(user),
    };
  }

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });
    const hash = user?.passwordHash ?? (await this.getDummyHash());
    const ok = await this.passwords.verify(hash, dto.password);
    if (!user || !ok) {
      throw new ApiException(
        HttpStatus.UNAUTHORIZED,
        'UNAUTHORIZED',
        'Invalid email or password',
      );
    }
    return {
      user: this.userJson(user),
      tokens: await this.tokens.issueTokens(user),
    };
  }

  async refresh(refreshToken: string): Promise<{ tokens: Tokens }> {
    const {
      accessToken,
      refreshToken: next,
      expiresIn,
    } = await this.tokens.rotate(refreshToken);
    const tokens: Tokens = { accessToken, refreshToken: next, expiresIn };
    return { tokens };
  }

  logout(refreshToken: string): Promise<void> {
    return this.tokens.revoke(refreshToken);
  }

  /** Always resolves; whether the email exists must not be observable. */
  async forgotPassword(dto: ForgotPasswordDto): Promise<void> {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
      select: { id: true, email: true, fullName: true },
    });
    if (!user) return;

    const token = randomBytes(32).toString('base64url');
    const ttlMin = this.config.get('PASSWORD_RESET_TTL_MINUTES', {
      infer: true,
    });
    await this.prisma.passwordResetToken.create({
      data: {
        userId: user.id,
        tokenHash: this.hashToken(token),
        expiresAt: new Date(Date.now() + ttlMin * 60_000),
      },
    });
    const base = this.config.get('APP_BASE_URL', { infer: true });
    await this.mail.sendPasswordReset(
      user.email,
      user.fullName,
      token,
      `${base.replace(/\/$/, '')}/reset-password?token=${encodeURIComponent(token)}`,
    );
  }

  async resetPassword(dto: ResetPasswordDto): Promise<void> {
    const row = await this.prisma.passwordResetToken.findUnique({
      where: { tokenHash: this.hashToken(dto.token) },
    });
    if (!row || row.usedAt || row.expiresAt <= new Date()) {
      throw new ApiException(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_ERROR',
        'Invalid or expired reset token',
      );
    }
    const passwordHash = await this.passwords.hash(dto.newPassword);
    await this.prisma.$transaction(async (tx) => {
      // Single-use even under concurrent submissions.
      const claimed = await tx.passwordResetToken.updateMany({
        where: { id: row.id, usedAt: null },
        data: { usedAt: new Date() },
      });
      if (claimed.count !== 1) {
        throw new ApiException(
          HttpStatus.BAD_REQUEST,
          'VALIDATION_ERROR',
          'Invalid or expired reset token',
        );
      }
      await tx.user.update({
        where: { id: row.userId },
        data: { passwordHash },
      });
      await tx.passwordResetToken.updateMany({
        where: { userId: row.userId, usedAt: null },
        data: { usedAt: new Date() },
      });
    });
    await this.tokens.revokeAllForUser(row.userId);
  }

  private userJson(user: Parameters<typeof toUserResponse>[0]) {
    return toUserResponse(
      user,
      this.config.get('FREE_DOWNLOAD_LIMIT', { infer: true }),
    );
  }

  private getDummyHash(): Promise<string> {
    return (this.dummyHash ??= this.passwords.hash(
      'dummy-password-for-timing',
    ));
  }

  private hashToken(token: string): string {
    return createHash('sha256').update(token).digest('hex');
  }

  private emailTaken(): never {
    throw new ApiException(
      HttpStatus.CONFLICT,
      'CONFLICT',
      'An account with this email already exists',
    );
  }
}
