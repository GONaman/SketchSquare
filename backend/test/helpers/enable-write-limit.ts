// Side-effect import: must come before AppModule is imported, because ConfigModule validates env at import time.
process.env.RATE_LIMIT_ENABLED = 'true';
process.env.RATE_LIMIT_WRITE_PER_MIN = '5';
process.env.CORS_ORIGINS = 'https://app.example.com, https://admin.example.com';
