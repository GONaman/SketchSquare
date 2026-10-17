#!/bin/sh
# Applies pending database migrations, then replaces itself with the API process (so SIGTERM reaches Node for graceful shutdown).
set -eu

if [ "${RUN_MIGRATIONS:-true}" = "true" ]; then
  echo "[entrypoint] prisma migrate deploy"
  node node_modules/prisma/build/index.js migrate deploy --schema prisma/schema.prisma
fi

exec "$@"
