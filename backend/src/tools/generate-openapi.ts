import { NestFactory } from '@nestjs/core';
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { stringify } from 'yaml';
import { AppModule } from '../app.module';
import { buildOpenApiDocument, configureApp } from '../app.setup';

// Runs from the compiled build (`npm run openapi`) so the @nestjs/swagger CLI plugin has annotated the DTOs.
async function main() {
  const out = resolve(__dirname, '../../../docs/openapi.yaml');
  const app = await NestFactory.create(AppModule, { logger: false });
  configureApp(app);
  const doc = buildOpenApiDocument(app);
  mkdirSync(dirname(out), { recursive: true });
  writeFileSync(out, stringify(doc, { lineWidth: 0 }));
  await app.close();
  console.log(`Wrote ${out}`);
}
void main();
