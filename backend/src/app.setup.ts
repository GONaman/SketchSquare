import { INestApplication } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { NestExpressApplication } from '@nestjs/platform-express';
import { DocumentBuilder, OpenAPIObject, SwaggerModule } from '@nestjs/swagger';
import type { NextFunction, Request, Response } from 'express';
import helmet from 'helmet';
import { AllExceptionsFilter } from './common/filters/all-exceptions.filter';
import { createValidationPipe } from './common/pipes/validation.pipe';
import { Env } from './config/env.schema';
import { MetricsService } from './observability/metrics.service';
import { requestIdMiddleware } from './observability/request-id';

export function parseCorsOrigins(raw: string): true | string[] {
  const origins = raw
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean);
  return origins.includes('*') ? true : origins;
}

/** Shared by main.ts, e2e tests and the openapi generator so every entry point behaves identically. */
export function configureApp(app: INestApplication): void {
  const config = app.get<ConfigService<Env, true>>(ConfigService);
  const express = app as NestExpressApplication;

  // First in the chain, so even body-parser and guard errors carry X-Request-Id.
  app.use(requestIdMiddleware);
  app.use(app.get(MetricsService).middleware);

  const hops = config.get('TRUST_PROXY', { infer: true });
  if (hops > 0) express.set('trust proxy', hops);

  // Swagger UI needs inline scripts/styles; every other route is JSON and gets the strict defaults.
  const apiHelmet = helmet();
  const docsHelmet = helmet({ contentSecurityPolicy: false });
  app.use((req: Request, res: Response, next: NextFunction) =>
    req.path.startsWith('/docs')
      ? docsHelmet(req, res, next)
      : apiHelmet(req, res, next),
  );

  app.enableCors({
    origin: parseCorsOrigins(config.get('CORS_ORIGINS', { infer: true })),
    methods: ['GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Authorization', 'Content-Type', 'Accept'],
    exposedHeaders: ['X-Request-Id', 'Retry-After'],
    maxAge: 600,
  });

  // Registered before Nest's default parser; keeps `rawBody` when the app was created with it (webhook signatures).
  const limit = config.get('BODY_LIMIT', { infer: true });
  express.useBodyParser('json', { limit });
  express.useBodyParser('urlencoded', { limit, extended: true });

  app.useGlobalPipes(createValidationPipe());
  app.useGlobalFilters(new AllExceptionsFilter());
}

export function buildOpenApiDocument(app: INestApplication): OpenAPIObject {
  const options = new DocumentBuilder()
    .setTitle('SketchSquare API')
    .setDescription('Contract: docs/API_CONTRACT.md')
    .setVersion('1.0')
    .addBearerAuth()
    .build();
  return SwaggerModule.createDocument(app, options);
}

export function setupSwagger(app: INestApplication): void {
  SwaggerModule.setup('docs', app, buildOpenApiDocument(app));
}
