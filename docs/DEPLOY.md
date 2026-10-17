# Deploying the SketchSquare backend

This covers the **backend** (NestJS API). Flutter release builds and store submission are tracked separately (Phase 7.3/7.4 app half).

## What you deploy
- **API container** built from `backend/Dockerfile` (multi-stage; Node 22, `poppler-utils` for PDF previews, `fonts-dejavu-core` for watermarks; runs as the unprivileged `node` user, ~250 MB).
- **PostgreSQL 16**, **Redis 7** (BullMQ queues and shared rate-limit counters), an **S3-compatible bucket store** (AWS S3, Cloudflare R2, MinIO).
- A TLS-terminating reverse proxy / load balancer in front of the API.

```bash
docker build -t sketchsquare-api backend/
```

On start the container's entrypoint runs `prisma migrate deploy` (idempotent; Postgres serialises concurrent runs with an advisory lock, so several replicas starting at once is safe) and then `node dist/main.js`. Set `RUN_MIGRATIONS=false` to skip it, e.g. when migrations run as a separate release/pre-deploy step:

```bash
docker run --rm -e DATABASE_URL=... sketchsquare-api node node_modules/prisma/build/index.js migrate deploy --schema prisma/schema.prisma
```

Migrations are forward-only; back up before a release that changes the schema.

`infra/docker-compose.prod.yml` + `infra/Caddyfile` are a worked single-host example (API, Postgres, Redis, MinIO, Caddy with automatic HTTPS):

```bash
docker compose --env-file infra/.env.prod -f infra/docker-compose.prod.yml up -d --build
```

## Environment checklist
Anything marked **required** has no default in production; the API exits at boot with a list of problems if it is missing or unsafe.

| Variable | Notes |
|---|---|
| `NODE_ENV=production` | **required** (set by the image). |
| `DATABASE_URL` | **required**, `postgresql://user:pass@host:5432/db`. Not the dev `sketch:sketch` login. |
| `REDIS_URL` | **required**. Also used for rate-limit counters (`RATE_LIMIT_STORAGE=redis`, default) so limits hold across instances. |
| `S3_ENDPOINT`, `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY` | **required**; not `minioadmin`, not localhost. For AWS S3 use the regional endpoint and `S3_FORCE_PATH_STYLE=false`. |
| `S3_REGION`, `S3_BUCKET_ORIGINALS`, `S3_BUCKET_PREVIEWS`, `S3_BUCKET_KYC` | Defaults `us-east-1`, `originals`, `previews`, `kyc`. |
| `S3_PUBLIC_ENDPOINT` | Host embedded in presigned URLs when clients reach storage on a different host than the API does (internal MinIO, split DNS). |
| `S3_PREVIEWS_PUBLIC_URL` | **required**. Public/CDN base URL of the previews bucket, e.g. `https://cdn.example.com/previews`. |
| `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET` | **required**, different, >= 32 random chars (`openssl rand -base64 48`). Rotating them logs everyone out. |
| `CORS_ORIGINS` | Comma-separated allowlist of web origins. `*` is refused in production. Native mobile apps do not send an `Origin`, so this only matters for web clients. |
| `APP_BASE_URL` | Public URL used in password-reset links (https). |
| `TRUST_PROXY` | Number of proxy hops in front of the API (1 behind a single load balancer). Without it every client shares the load balancer's IP and therefore one rate-limit key. |
| `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`, `RAZORPAY_WEBHOOK_SECRET` | Real payments. Unset key => stub checkout (refused in production). Register `POST {API}/payments/razorpay/webhook` in the Razorpay dashboard with the same secret. |
| `PAYOUT_PROVIDER=razorpayx`, `RAZORPAYX_KEY_ID`, `RAZORPAYX_KEY_SECRET`, `RAZORPAYX_ACCOUNT_NUMBER`, `RAZORPAYX_WEBHOOK_SECRET` | Real payouts. `stub` is refused in production. Register the RazorpayX payout webhook (`POST {API}/payments/razorpayx/webhook`) with `RAZORPAYX_WEBHOOK_SECRET`. |
| `SMTP_HOST`, `SMTP_PORT`, `SMTP_SECURE`, `SMTP_USER`, `SMTP_PASS`, `EMAIL_FROM` | Transactional mail (password reset, verification outcome). `localhost` (Mailpit) is refused. |
| `FCM_PROJECT_ID`, `FCM_CLIENT_EMAIL`, `FCM_PRIVATE_KEY` | Push notifications; all three or the logging stub is used (warning only). |
| `SENTRY_DSN` (+ `SENTRY_ENVIRONMENT`, `SENTRY_TRACES_SAMPLE_RATE`) | Error reporting is **off** unless the DSN is set. Only 5xx errors are sent, tagged with the request id; headers, cookies and bodies are stripped. |
| `METRICS_TOKEN` | Protects `GET /metrics` (`Authorization: Bearer <token>`). When unset, `/metrics` answers only peers on private addresses and never requests carrying `X-Forwarded-For`. Keep `/metrics` off the public listener regardless (the example Caddyfile 404s it). |
| `LOG_LEVEL` | `info` default. JSON on stdout; every line has the request id; passwords, tokens, secrets and `Authorization`/cookie headers are redacted. |
| `RATE_LIMIT_ENABLED`, `RATE_LIMIT_WRITE_PER_MIN`, `RATE_LIMIT_STORAGE` | Defaults `true`, `60`, `redis`. Disabling the limiter is refused in production. |
| `BODY_LIMIT` | Default `100kb` for JSON; uploads go straight to S3 via presigned URLs. |
| `SHUTDOWN_DRAIN_MS`, `SHUTDOWN_TIMEOUT_MS` | See *Graceful shutdown*. |
| Business rules | `FREE_DOWNLOAD_LIMIT`, `PLATFORM_FEE_BPS`, `MIN_WITHDRAWAL_PAISE`, `CONTRIBUTION_FREE_PER_PAID`, `PLAGIARISM_*` have sensible defaults (see `backend/.env.example`). |

### Startup guard
`backend/src/config/production-guard.ts` runs while the environment is validated, i.e. before the app listens. With `NODE_ENV=production` it **refuses to boot** (and prints every problem) when:
- a JWT secret is a `dev-only…`/`change-me` placeholder, shorter than 32 characters, or both secrets are equal;
- S3 credentials are the MinIO defaults, or `S3_ENDPOINT` / `S3_PREVIEWS_PUBLIC_URL` / `S3_PUBLIC_ENDPOINT` point at localhost;
- `DATABASE_URL` uses the dev credentials `sketch:sketch`;
- Razorpay keys are missing (stub payments) or the webhook secret is missing;
- `PAYOUT_PROVIDER=stub`, RazorpayX is half-configured, or its webhook secret is missing;
- rate limiting is disabled, `APP_BASE_URL` or `SMTP_HOST` is localhost.

It only **warns** about: localhost DB/Redis, in-memory rate-limit storage, missing `METRICS_TOKEN`/`SENTRY_DSN`/FCM keys, `TRUST_PROXY=0`, non-https `APP_BASE_URL`.

**Escape hatch:** `ALLOW_UNSAFE_PRODUCTION=true` turns the refusals into loud `[startup-guard] UNSAFE ...` lines on stderr and boots anyway. Use it only for a staging dry run (for example, staging without real payment keys); never on a real deployment. A wildcard `CORS_ORIGINS` is rejected by the schema itself and is not covered by the hatch.

## Storage buckets
- `originals` (full-resolution sheets) and `kyc` (identity documents) must be **private**: no anonymous access, no public ACLs. The API only hands out presigned URLs (uploads: 15 min, downloads of purchased originals: 5 min).
- `previews` (watermarked, low-res) is the only bucket that may be anonymously readable, ideally only through a CDN. Never put originals in it.
- AWS S3: enable *Block all public access* on `originals` and `kyc`; for `previews` either keep the block on and serve through CloudFront with an origin access control, or add a bucket policy granting `s3:GetObject` on `previews/*` only. The IAM user/role for the API needs `s3:PutObject`, `s3:GetObject`, `s3:DeleteObject`, `s3:HeadObject`/`ListBucket` on the three buckets and nothing else.
- Configure a CORS rule on `originals` and `kyc` allowing `PUT` from your web origin(s) if a browser client uploads directly.
- `infra/docker-compose.prod.yml` shows the MinIO equivalent (`mc anonymous set none|download`).

## Graceful shutdown and probes
- Liveness/readiness: `GET /health` (200 `{"status":"ok","checks":{db,redis,s3}}`; 503 when a dependency is down or the process is shutting down). The image has a Docker `HEALTHCHECK` on it.
- On `SIGTERM`/`SIGINT` the API immediately reports 503 on `/health`, waits `SHUTDOWN_DRAIN_MS`, stops accepting connections, lets in-flight requests finish (at most `SHUTDOWN_TIMEOUT_MS`), then closes BullMQ, Redis and Prisma. Set `SHUTDOWN_DRAIN_MS` to roughly two load-balancer health intervals (e.g. 5000-10000) and make the platform's stop timeout larger than `SHUTDOWN_DRAIN_MS + SHUTDOWN_TIMEOUT_MS` (e.g. 40 s).
- BullMQ workers run in the API process (preview processing, payouts, notifications). Scale API replicas freely; queues are shared through Redis, so use one `QUEUE_PREFIX` per environment if several share a Redis.

## Hosting guidance (document only, not exercised here)

### Render / Railway / Fly.io
1. Create managed Postgres and Redis; create an S3/R2 bucket set (Render and Railway have no object store, so use R2/S3).
2. Deploy the Dockerfile in `backend/` as a web service. Health check path `/health`. Set the environment checklist above; `TRUST_PROXY=1`.
3. Run migrations through the container entrypoint (default) or a pre-deploy command (`RUN_MIGRATIONS=false` on the web service).
4. Render: stop timeout (`maxShutdownDelaySeconds`) 40. Fly: `kill_timeout = 40`, `[checks]` -> `/health`, `internal_port = 3000`. Railway: set `RAILWAY_HEALTHCHECK_TIMEOUT_SEC` and a healthcheck path.
5. Point Razorpay webhooks at `https://<api-host>/payments/razorpay/webhook` and RazorpayX webhooks at `https://<api-host>/payments/razorpayx/webhook`.

### AWS (EC2 + RDS + S3)
1. RDS PostgreSQL 16 (private subnet, security group open only to the API instances), ElastiCache Redis (same), S3 buckets as described above.
2. An EC2 instance (or ECS/Fargate task) running the image; instance role with the S3 permissions above instead of access keys when possible (the current code reads `S3_ACCESS_KEY_ID`/`S3_SECRET_ACCESS_KEY`, so create a dedicated IAM user for now).
3. ALB with an ACM certificate, target group health check `/health` (every 10 s, healthy threshold 2), deregistration delay >= 40 s, `TRUST_PROXY=1`.
4. Put the API's security group behind the ALB only; do not expose port 3000. Do not route `/metrics` through the ALB; scrape it from inside the VPC with `METRICS_TOKEN`.
5. Ship container logs (JSON) to CloudWatch; alert on 5xx rate and `/health` failures.

## Observability
- Logs: JSON on stdout, one object per request with `req.id`; the same id is returned as `X-Request-Id` (also on error responses) and attached to Sentry events. Send `X-Request-Id` from the load balancer to correlate across tiers (accepted when it is a short token, otherwise regenerated).
- Metrics: `GET /metrics` (Prometheus text): default Node/process metrics plus HTTP request counters and duration histograms by method, route template and status. Scrape with `Authorization: Bearer $METRICS_TOKEN`.
- Errors: Sentry via `SENTRY_DSN`.

## Release checklist
1. `npm run lint && npm test && npm run test:e2e` in `backend/` are green; `npm run openapi` produces no diff in `docs/openapi.yaml`.
2. `docker build` succeeds; start the image once with the production env against a staging DB. Because of the startup guard, a misconfigured env fails fast.
3. Back up the database; deploy; watch `/health`, the 5xx rate and the Razorpay/RazorpayX webhook deliveries.
4. Seeded demo data (`npm run seed`) and `npm run seed:bulk` are for development only; `seed:bulk` refuses `NODE_ENV=production`.
5. There is no admin sign-up endpoint: register the account through the app, then promote it in the database (`UPDATE "User" SET role='ADMIN' WHERE email='...'`) and keep its credentials in a password manager. Admin actions are written to the audit log. The seeded demo admin from `npm run seed` must never exist in production.
