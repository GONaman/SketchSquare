// Side-effect import: must come before AppModule is imported, because ConfigModule validates env at import time.
process.env.METRICS_TOKEN = 'scrape-token-for-tests';
