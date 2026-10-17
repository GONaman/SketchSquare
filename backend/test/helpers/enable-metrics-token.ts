import { overrideEnv } from './override-env';

// Side-effect import: must come before AppModule is imported, because ConfigModule validates env at import time.
overrideEnv({ METRICS_TOKEN: 'scrape-token-for-tests' });
