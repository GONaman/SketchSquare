import { Controller, Get, INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { Role, VerificationStatus } from '@prisma/client';
import { JwtService } from '@nestjs/jwt';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/app.setup';
import {
  AllowUnverified,
  CurrentUser,
  Public,
  Roles,
} from '../src/auth/decorators';
import type { AuthUser } from '../src/auth/decorators';
import { PrismaService } from '../src/prisma/prisma.service';
import { bearer, createTestUser } from './helpers/auth';
import { resetDb } from './helpers/db';

@Controller('__guards')
class GuardsDemoController {
  @Get('public') @Public() pub() {
    return { ok: true };
  }
  @Get('approved') approved(@CurrentUser() user: AuthUser) {
    return { id: user.id, role: user.role };
  }
  @Get('unverified') @AllowUnverified() unverified(
    @CurrentUser('verificationStatus') status: string,
  ) {
    return { status };
  }
  @Get('admin') @Roles('ADMIN') @AllowUnverified() admin() {
    return { ok: true };
  }
}

describe('Global auth guards (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  const http = () => request(app.getHttpServer());

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
      controllers: [GuardsDemoController],
    }).compile();
    app = moduleRef.createNestApplication();
    configureApp(app);
    await app.init();
    prisma = app.get(PrismaService);
  });

  beforeEach(() => resetDb(prisma));
  afterAll(async () => {
    await resetDb(prisma);
    await app.close();
  });

  it('@Public routes need no token', async () => {
    await http().get('/__guards/public').expect(200);
  });

  it('rejects missing, malformed and wrongly-signed tokens with 401 UNAUTHORIZED', async () => {
    for (const header of [
      undefined,
      'Bearer garbage',
      `Bearer ${new JwtService().sign({ sub: 'x' }, { secret: 'wrong' })}`,
    ]) {
      const req = http().get('/__guards/approved');
      const res = await (
        header ? req.set('Authorization', header) : req
      ).expect(401);
      expect((res.body as { error: { code: string } }).error.code).toBe(
        'UNAUTHORIZED',
      );
    }
  });

  it('rejects an expired access token', async () => {
    const u = await createTestUser(app);
    const expired = app
      .get(JwtService)
      .sign(
        { sub: u.user.id, role: u.user.role },
        { secret: 'dev-only-access-secret-change-me', expiresIn: -10 },
      );
    await http()
      .get('/__guards/approved')
      .set('Authorization', `Bearer ${expired}`)
      .expect(401);
  });

  it('rejects a token whose user no longer exists', async () => {
    const u = await createTestUser(app);
    await prisma.user.delete({ where: { id: u.user.id } });
    await http()
      .get('/__guards/approved')
      .set(...bearer(u))
      .expect(401);
  });

  it('APPROVED architect passes and @CurrentUser resolves', async () => {
    const u = await createTestUser(app);
    const res = await http()
      .get('/__guards/approved')
      .set(...bearer(u))
      .expect(200);
    expect(res.body).toEqual({ id: u.user.id, role: 'ARCHITECT' });
  });

  it.each([VerificationStatus.PENDING, VerificationStatus.REJECTED])(
    '%s architect is blocked with 403 VERIFICATION_REQUIRED on protected routes',
    async (verificationStatus) => {
      const u = await createTestUser(app, { verificationStatus });
      const res = await http()
        .get('/__guards/approved')
        .set(...bearer(u))
        .expect(403);
      expect((res.body as { error: { code: string } }).error.code).toBe(
        'VERIFICATION_REQUIRED',
      );
    },
  );

  it('@AllowUnverified lets unverified users in', async () => {
    const u = await createTestUser(app, {
      verificationStatus: VerificationStatus.PENDING,
    });
    const res = await http()
      .get('/__guards/unverified')
      .set(...bearer(u))
      .expect(200);
    expect(res.body).toEqual({ status: 'PENDING' });
  });

  it('approval takes effect on the next request without a new token', async () => {
    const u = await createTestUser(app, {
      verificationStatus: VerificationStatus.PENDING,
    });
    await http()
      .get('/__guards/approved')
      .set(...bearer(u))
      .expect(403);
    await prisma.user.update({
      where: { id: u.user.id },
      data: { verificationStatus: VerificationStatus.APPROVED },
    });
    await http()
      .get('/__guards/approved')
      .set(...bearer(u))
      .expect(200);
  });

  it('@Roles(ADMIN) returns 403 FORBIDDEN for architects and passes for admins', async () => {
    const architect = await createTestUser(app);
    const res = await http()
      .get('/__guards/admin')
      .set(...bearer(architect))
      .expect(403);
    expect((res.body as { error: { code: string } }).error.code).toBe(
      'FORBIDDEN',
    );
    const admin = await createTestUser(app, { role: Role.ADMIN });
    await http()
      .get('/__guards/admin')
      .set(...bearer(admin))
      .expect(200);
  });

  it('admins are not subject to architect verification', async () => {
    const admin = await createTestUser(app, {
      role: Role.ADMIN,
      verificationStatus: VerificationStatus.PENDING,
    });
    await http()
      .get('/__guards/approved')
      .set(...bearer(admin))
      .expect(200);
  });
});
