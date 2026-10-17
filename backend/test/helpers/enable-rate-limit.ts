// Side-effect import: must come before AppModule is imported, because ConfigModule validates env at import time.
process.env.RATE_LIMIT_ENABLED = 'true';
