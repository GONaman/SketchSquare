import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { AppModule } from '../src/app.module';
import { TokenService } from '../src/auth/tokens/token.service';
import { PrismaService } from '../src/prisma/prisma.service';
import { createTestUser } from './helpers/auth';
import { resetDb } from './helpers/db';

describe('TokenService (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let tokens: TokenService;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    await app.init();
    prisma = app.get(PrismaService);
    tokens = app.get(TokenService);
  });

  beforeEach(() => resetDb(prisma));
  afterAll(async () => {
    await resetDb(prisma);
    await app.close();
  });

  it('stores only a hash of the refresh token', async () => {
    const u = await createTestUser(app);
    const rows = await prisma.refreshToken.findMany({
      where: { userId: u.user.id },
    });
    expect(rows).toHaveLength(1);
    expect(rows[0].tokenHash).not.toContain(u.refreshToken);
    expect(rows[0].tokenHash).toHaveLength(64);
  });

  it('rotates: old token is revoked and linked to its replacement in the same family', async () => {
    const u = await createTestUser(app);
    const next = await tokens.rotate(u.refreshToken);
    expect(next.userId).toBe(u.user.id);
    expect(next.refreshToken).not.toBe(u.refreshToken);
    expect(next.expiresIn).toBe(900);

    const rows = await prisma.refreshToken.findMany({
      where: { userId: u.user.id },
      orderBy: { createdAt: 'asc' },
    });
    expect(rows).toHaveLength(2);
    expect(rows[0].revokedAt).not.toBeNull();
    expect(rows[0].replacedById).toBe(rows[1].id);
    expect(rows[1].revokedAt).toBeNull();
    expect(rows[1].familyId).toBe(rows[0].familyId);
  });

  it('reusing a rotated token revokes the entire family', async () => {
    const u = await createTestUser(app);
    const next = await tokens.rotate(u.refreshToken);
    await expect(tokens.rotate(u.refreshToken)).rejects.toMatchObject({
      code: 'UNAUTHORIZED',
    });
    // the legitimate successor is dead too
    await expect(tokens.rotate(next.refreshToken)).rejects.toMatchObject({
      code: 'UNAUTHORIZED',
    });
    expect(
      await prisma.refreshToken.count({
        where: { userId: u.user.id, revokedAt: null },
      }),
    ).toBe(0);
  });

  it('reuse in one family does not affect another session of the same user', async () => {
    const u = await createTestUser(app);
    const other = await tokens.issueTokens(u.user);
    await tokens.rotate(u.refreshToken);
    await expect(tokens.rotate(u.refreshToken)).rejects.toBeDefined();
    await expect(tokens.rotate(other.refreshToken)).resolves.toBeDefined();
  });

  it('concurrent use of the same token lets exactly one caller win', async () => {
    const u = await createTestUser(app);
    const results = await Promise.allSettled([
      tokens.rotate(u.refreshToken),
      tokens.rotate(u.refreshToken),
    ]);
    expect(results.filter((r) => r.status === 'fulfilled')).toHaveLength(1);
  });

  it('rejects unknown and expired tokens', async () => {
    const u = await createTestUser(app);
    await expect(tokens.rotate('nope')).rejects.toBeDefined();
    await prisma.refreshToken.updateMany({
      where: { userId: u.user.id },
      data: { expiresAt: new Date(Date.now() - 1000) },
    });
    await expect(tokens.rotate(u.refreshToken)).rejects.toBeDefined();
  });

  it('revoke() kills the session and is idempotent', async () => {
    const u = await createTestUser(app);
    await tokens.revoke(u.refreshToken);
    await tokens.revoke(u.refreshToken);
    await tokens.revoke('unknown');
    await expect(tokens.rotate(u.refreshToken)).rejects.toBeDefined();
  });

  it('revokeAllForUser revokes every session', async () => {
    const u = await createTestUser(app);
    const second = await tokens.issueTokens(u.user);
    await tokens.revokeAllForUser(u.user.id);
    await expect(tokens.rotate(second.refreshToken)).rejects.toBeDefined();
  });
});
