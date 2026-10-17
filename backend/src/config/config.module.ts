import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { validateEnv } from './env.schema';
import { assertProductionSafe } from './production-guard';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      cache: true,
      validate: (raw: Record<string, unknown>) => {
        const env = validateEnv(raw);
        assertProductionSafe(env);
        return env;
      },
    }),
  ],
})
export class AppConfigModule {}
