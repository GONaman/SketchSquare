import { overrideEnv } from './override-env';

// Side-effect import: must come before AppModule is imported, because ConfigModule validates env at import time.
overrideEnv({
  RATE_LIMIT_ENABLED: 'true',
  RATE_LIMIT_WRITE_PER_MIN: '5',
  CORS_ORIGINS: 'https://app.example.com, https://admin.example.com',
});
