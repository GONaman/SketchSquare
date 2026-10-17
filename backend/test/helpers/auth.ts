import { INestApplication } from '@nestjs/common';
import { Role, User, VerificationStatus } from '@prisma/client';
import { randomUUID } from 'node:crypto';
import { PasswordService } from '../../src/auth/password/password.service';
import { TokenService } from '../../src/auth/tokens/token.service';
import { PrismaService } from '../../src/prisma/prisma.service';

export interface TestUser {
  user: User;
  password: string;
  accessToken: string;
  refreshToken: string;
}

/**
 * Inserts a user straight into the test DB and mints real tokens for it (no HTTP round trip).
 * Defaults to an APPROVED architect; use `bearer(testUser)` for the Authorization header.
 */
export async function createTestUser(
  app: INestApplication,
  overrides: Partial<
    Pick<
      User,
      'email' | 'fullName' | 'role' | 'verificationStatus' | 'city' | 'phone'
    >
  > & { password?: string } = {},
): Promise<TestUser> {
  const prisma = app.get(PrismaService);
  const password = overrides.password ?? 'Passw0rd!test';
  const passwordHash = await app.get(PasswordService).hash(password);
  const user = await prisma.user.create({
    data: {
      email: overrides.email ?? `user-${randomUUID()}@example.com`,
      passwordHash,
      fullName: overrides.fullName ?? 'Test Architect',
      address: '1 Test Street',
      phone: overrides.phone ?? '+919999999999',
      city: overrides.city ?? 'Bengaluru',
      role: overrides.role ?? Role.ARCHITECT,
      verificationStatus:
        overrides.verificationStatus ?? VerificationStatus.APPROVED,
    },
  });
  const tokens = await app.get(TokenService).issueTokens(user);
  return {
    user,
    password,
    accessToken: tokens.accessToken,
    refreshToken: tokens.refreshToken,
  };
}

export const bearer = (u: Pick<TestUser, 'accessToken'>): [string, string] => [
  'Authorization',
  `Bearer ${u.accessToken}`,
];
