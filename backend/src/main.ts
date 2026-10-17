import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { Logger } from 'nestjs-pino';
import { AppModule } from './app.module';
import { configureApp, setupSwagger } from './app.setup';
import { Env } from './config/env.schema';
import { installGracefulShutdown } from './observability/graceful-shutdown';
import { initSentry } from './observability/sentry';

async function bootstrap() {
  // Sentry reads the raw environment: it must start before the app (and stays off without SENTRY_DSN).
  initSentry({
    dsn: process.env.SENTRY_DSN,
    environment: process.env.SENTRY_ENVIRONMENT ?? process.env.NODE_ENV,
    tracesSampleRate: Number(process.env.SENTRY_TRACES_SAMPLE_RATE ?? 0),
  });
  const app = await NestFactory.create(AppModule, {
    rawBody: true,
    bufferLogs: true,
  });
  const logger = app.get(Logger);
  app.useLogger(logger);
  configureApp(app);
  setupSwagger(app);
  const config = app.get<ConfigService<Env, true>>(ConfigService);
  installGracefulShutdown(app, {
    drainMs: config.get('SHUTDOWN_DRAIN_MS', { infer: true }),
    timeoutMs: config.get('SHUTDOWN_TIMEOUT_MS', { infer: true }),
  });
  const port = config.get('PORT', { infer: true });
  await app.listen(port);
  logger.log(`API listening on :${port} (docs at /docs)`, 'Bootstrap');
}
void bootstrap();
