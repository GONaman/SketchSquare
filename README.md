# SketchSquare

An architect-only marketplace to buy, sell and discover architectural drawings. The headline feature is **search by plot size** (width × length, with tolerance and rotation).

| Part | Tech | Path |
|---|---|---|
| Mobile app | Flutter 3.29 · Riverpod · go_router · dio | [`sketch_square/`](sketch_square) |
| API | NestJS 11 · Prisma · PostgreSQL 16 · Redis · BullMQ | [`backend/`](backend) |
| Local infra | Docker Compose: Postgres, Redis, MinIO (S3), Mailpit | [`infra/`](infra) |

Docs: [`AGENTS.md`](AGENTS.md) (spec) · [`docs/API_CONTRACT.md`](docs/API_CONTRACT.md) · [`docs/openapi.yaml`](docs/openapi.yaml) · [`docs/data-model.md`](docs/data-model.md) · [`docs/CONVENTIONS.md`](docs/CONVENTIONS.md) · [`docs/DECISIONS.md`](docs/DECISIONS.md) · [`docs/PROGRESS.md`](docs/PROGRESS.md)

## Quick start

Prerequisites: Docker, Node 22, Flutter 3.29.1.

```bash
# 1. Infra (Postgres :5432, Redis :6379, MinIO :9000/:9001, Mailpit UI :8025)
docker compose -f infra/docker-compose.yml up -d

# 2. Backend (API on :3000, Swagger UI at /docs)
cd backend
cp .env.example .env          # defaults work against the compose stack
npm ci
npx prisma migrate deploy
npx prisma db seed            # demo data and an admin user (see docs/data-model.md)
npm run start:dev

# 3. App
cd ../sketch_square
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000   # Android emulator: http://10.0.2.2:3000
```

## Tests

```bash
cd backend && npm run lint && npm test && npm run test:e2e   # e2e uses the sketchsquare_test database
cd sketch_square && flutter analyze && flutter test
```

CI (`.github/workflows/ci.yml`) runs both suites on every PR.

## Third-party services

Razorpay, email, push and payouts run in **stub mode** by default so everything works locally without credentials. See `docs/API_CONTRACT.md` and `docs/DECISIONS.md` for what to configure for production.

## Contributing workflow

Small feature branches → PR → squash-merge into `main`. No direct pushes to `main`.
