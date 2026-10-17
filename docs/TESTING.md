# Testing

## Backend unit + e2e (`backend/`)

```bash
cd backend
npm run lint
npm test                 # unit
TEST_DATABASE_URL=postgresql://sketch:sketch@localhost:5432/sketchsquare_test npm run test:e2e
```

`test:e2e` truncates `TEST_DATABASE_URL` between tests: never point it at a dev DB.

## End-to-end HTTP smoke (`backend/scripts/smoke.ts`)

Drives the **real running API** over HTTP (no Nest internals), covering every user flow:
signup -> KYC upload -> admin approve -> login/refresh (rotation + reuse detection) -> profile + avatar -> create drawing
-> presigned PUT to MinIO -> register sheets -> publish -> wait for `PUBLISHED` -> search (text, plot size incl. rotated
and metres, filters, every sort, cursors) -> detail -> favorites -> cart -> checkout (stub Razorpay) -> signed webhook
(+ replay) -> buyer-watermarked download -> free-download quota -> review -> wallet balance/ledger -> bank account ->
withdrawal (paid and failed + reversal) -> Razorpay X webhook -> authorization spot checks -> remove drawing.
It also asserts the exact response shapes in `docs/API_CONTRACT.md` and the `{ error: { code, message } }` envelope.

Prerequisites: `docker compose up -d` in `infra/` (Postgres, Redis, MinIO), a migrated + seeded DB (`npx prisma migrate deploy && npm run seed`;
the script logs in as the seeded admin), no `RAZORPAY_*` keys (stub providers). `pdftotext` (poppler) is optional and enables
the PDF watermark text assertion.

```bash
cd backend
npm run build && RATE_LIMIT_ENABLED=false PORT=3100 node dist/main &   # signup/login throttles would otherwise trip (429)
SMOKE_BASE_URL=http://localhost:3100 npm run smoke
```

Each run creates fresh users and uniquely tagged drawings, so it can be repeated against the same DB. Use a dedicated DB
and `QUEUE_PREFIX` if other developers/agents share the infra.

### Capturing fixtures for the Flutter tests

```bash
npm run smoke -- --capture ../sketch_square/test/fixtures/api
```

writes every captured response (JWTs and `X-Amz-*` signatures redacted) as JSON. The Flutter contract tests in
`sketch_square/test/fixtures/` parse these with the real models; re-capture and commit when the API changes.

## Flutter (`sketch_square/`)

```bash
cd sketch_square
flutter analyze
flutter test
```

Run the app against a local backend with `--dart-define=API_BASE_URL=http://localhost:3100` (Android emulator: `http://10.0.2.2:3100`).
