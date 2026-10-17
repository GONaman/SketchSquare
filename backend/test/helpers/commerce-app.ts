import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { AppModule } from '../../src/app.module';
import { configureApp } from '../../src/app.setup';
import { PrismaService } from '../../src/prisma/prisma.service';

export interface TestApp {
  app: INestApplication;
  prisma: PrismaService;
}

export interface BuildOptions {
  overrides?: { token: unknown; useValue: unknown }[];
}

/** Boots the real AppModule (raw body enabled for webhook signatures), with optional provider overrides. */
export async function buildCommerceApp(
  opts: BuildOptions = {},
): Promise<TestApp> {
  let builder = Test.createTestingModule({ imports: [AppModule] });
  for (const o of opts.overrides ?? []) {
    builder = builder.overrideProvider(o.token as string).useValue(o.useValue);
  }
  const moduleRef = await builder.compile();
  const app = moduleRef.createNestApplication({ rawBody: true });
  configureApp(app);
  await app.init();
  return { app, prisma: app.get(PrismaService) };
}
