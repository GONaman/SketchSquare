# Conventions

Each section is owned by one agent; append, don't overwrite other sections. Contract details live in `docs/API_CONTRACT.md`.

## Flutter (`sketch_square/`)

### Layout
- `lib/core/` — shared, feature-agnostic code: `theme/`, `network/`, `storage/`, `router/`, `widgets/`, `providers.dart`.
- `lib/features/<feature>/{data,domain,presentation}`:
  - `domain/` — freezed models (`*.dart` + committed `*.freezed.dart`/`*.g.dart`) and repository **interfaces**.
  - `data/` — repository implementations that call the `dioProvider`; parse with `fromJson`.
  - `presentation/` — screens, widgets, and Riverpod controllers.
- Shared contract models already exist: `features/auth/domain/user.dart` (`User`, `Tokens`, `UserRole`, `VerificationStatus`),
  `features/architects/domain/architect_summary.dart`, `features/drawings/domain/drawing_summary.dart` (`DrawingSummary`, `CategoryRef`, `DrawingStatus`),
  `core/network/cursor_page.dart` (`CursorPage<T>`: `items` + `nextCursor`). Add new contract models in the owning feature's `domain/`.
  Enums use `@JsonValue('UPPER_CASE')` to match `docs/API_CONTRACT.md`. Money is `int` paise.

### Routing
- Every feature exposes its routes from `presentation/<feature>_routes.dart` (e.g. `final homeRoutes = <RouteBase>[...]`).
  Tab features are registered as one `StatefulShellBranch(routes: xRoutes)` line in `core/router/app_router.dart`
  (branch order == bottom-nav order). Non-tab features (e.g. sign-in) add their `GoRoute`s as one `...xRoutes` line to the top-level routes.
- Path constants live in `AppRoutes` (`core/router/routes.dart`). Redirect rules live in the pure function `authRedirect(AuthState, location)`
  (unit-tested); extend it there, not inline in the router.
- Remove `placeholderDetailRoute` from a tab's routes once that tab has real sub-routes.

### State / providers (riverpod_generator)
- Use `@riverpod` / `@Riverpod(keepAlive: true)` annotations; commit the generated `*.g.dart` (decision D3). Regenerate with
  `dart run build_runner build --delete-conflicting-outputs` (run inside `sketch_square/`).
- Provider functions take a plain `Ref` (`import 'package:flutter_riverpod/flutter_riverpod.dart'` when the file has no other riverpod import).
- Core providers (`core/providers.dart`): `secureStorageProvider`, `tokenStoreProvider`, `dioProvider`. Auth session: `authControllerProvider`
  (`AuthState.unauthenticated | authenticated(user)`; currently a stub — Phase 2 makes it real). Theme: `appThemeModeProvider`.
- Repositories: define an interface in `domain/`, an implementation in `data/` taking `Dio`, and a `@riverpod` provider that builds it from `dioProvider`.
  Screens depend on the interface provider so tests can override it with a fake.
- Pagination: request `?cursor=&limit=`, parse with `CursorPage.fromJson(json, Item.fromJson)`.

### Errors
- The error interceptor puts an `ApiException` (`code`, `message`, `details?`, `statusCode`) into `DioException.error`.
  In repositories/controllers use `catch (e) { throw toApiException(e); }` and branch on `ApiErrorCodes.*` (all contract codes are defined).
  Client-only codes: `NETWORK_ERROR`, `TIMEOUT`, `CANCELLED`, `UNKNOWN`.
- The auth-header interceptor reads `TokenStore`; the refresh-on-401 interceptor is added in Phase 2 next to it in `core/network/dio_client.dart`.

### Theme & UI
- Use `Theme.of(context).colorScheme` / `textTheme` — no hard-coded colours outside `core/theme/app_colors.dart`. Accent is blueprint blue `#1F3A93`
  (lighter tint in dark mode). Inter via google_fonts; `AppTheme.useGoogleFonts = false` in tests (the test helper does this).
- Empty/placeholder states: `BlueprintEmptyState` / `PlaceholderScreen` (blueprint grid motif, use sparingly).

### Testing
- `test/helpers/pump_app.dart`: `pumpApp(tester, overrides: [...])` pumps the whole app with in-memory secure storage and no font downloads;
  `inAppBar('Title')` finds a tab title inside the AppBar. Override repository providers with fakes; for Dio-level tests use
  `DioAdapter` from `http_mock_adapter` on `createDio(tokenStore: ..., baseUrl: 'http://test')`.
- Tests mirror `lib/` under `test/` (`test/features/<feature>/...`, `test/core/...`).
- Before shipping: `flutter analyze && flutter test` (and `dart format lib test`).

### Running
- `flutter run --dart-define=API_BASE_URL=http://localhost:3000` (iOS simulator / web); Android emulator default is `http://10.0.2.2:3000`.

## Backend (NestJS, `backend/`)

### Running
- Infra: `docker compose -f infra/docker-compose.yml up -d`; `cp backend/.env.example backend/.env` (all defaults work locally).
- `npm run start:dev` (API on :3000, Swagger UI `/docs`), `npm run lint`, `npm test` (unit, `src/**/*.spec.ts`),
  `npm run test:e2e` (`test/**/*.e2e-spec.ts`, runs in band against the `sketchsquare_test` DB — `test/setup-env.ts` forces it),
  `npm run openapi` (rebuilds and rewrites `docs/openapi.yaml`; needs no running infra).
- `@nestjs/config` v4 and `@nestjs/swagger` v11 are pinned deliberately (newer majors require Nest 12 / ESM).

### Layout
```
backend/src/
  app.module.ts        # root; one import line per feature module
  app.setup.ts         # configureApp(app) (CORS, ValidationPipe, error filter) + swagger; used by main.ts, e2e tests, openapi tool
  config/              # env.schema.ts (zod, single source of every env var) + AppConfigModule (global)
  common/              # errors/ (ApiException), filters/, pipes/, decorators/ (Public, AllowUnverified, Roles), pagination.ts
  prisma/ redis/ storage/   # global infra modules: PrismaService, REDIS_CLIENT (ioredis), S3_CLIENT (aws-sdk v3)
  health/              # GET /health
  <feature>/           # e.g. auth/, drawings/, wallet/ — module, controller(s), service(s), dto/, *.spec.ts next to the code
backend/test/          # e2e specs (*.e2e-spec.ts)
backend/prisma/        # schema.prisma, migrations/, seed.ts
```

### Adding a feature module
1. `src/<feature>/<feature>.module.ts` (+ controller, service, `dto/`). Prisma, Redis, S3 and config are global — just inject them.
2. Register it with **one line** in `AppModule.imports` (below the `// Feature modules` comment; on conflicts keep both lines).
3. New env var: add it to `config/env.schema.ts` **and** `backend/.env.example` (a unit test asserts the example validates).
4. Run `npm run openapi` and commit `docs/openapi.yaml` whenever endpoints/DTOs change.

### Config
Inject `ConfigService<Env, true>` and read with `config.get('KEY', { infer: true })` (typed, validated, numbers/booleans already coerced).
Never read `process.env` outside `config/`.

### Errors
Always the contract shape `{ error: { code, message, details? } }`, produced by the global `AllExceptionsFilter`.
- Domain errors: `throw new ApiException(HttpStatus.FORBIDDEN, 'FREE_LIMIT_REACHED', 'message', { optional: 'details' })`
  (`ApiErrorCode` lists exactly the contract codes).
- Stock Nest exceptions (`NotFoundException`, `ConflictException`, …) are mapped by status. Prisma `P2002` → 409 `CONFLICT`, `P2025` → 404.
- Anything unexpected → 500 `INTERNAL` (message hidden, stack logged).

### DTOs / validation
`class-validator` DTOs; the global pipe has `whitelist` + `forbidNonWhitelisted` + `transform`, so unknown properties are a 400
`VALIDATION_ERROR` with `details.fields` (`{ "<path>": ["msg", …] }`). The Swagger CLI plugin infers DTO schemas from class-validator
decorators and TS types; add `@ApiProperty` only when the inference is not enough. Tag controllers with `@ApiTags('<feature>')`
and `@ApiBearerAuth()` on authenticated ones.

### Access control (guards)
Decorators live in `common/decorators/access.decorators.ts`:
- `@Public()` — no token (contract `[public]`), `@AllowUnverified()` — token required, any verificationStatus (contract `[auth]`),
  `@Roles('ADMIN')` — role restriction (contract `[admin]`). Undecorated routes = logged-in + APPROVED.
- The global `JwtAuthGuard` / `VerifiedGuard` / `RolesGuard` (registered as `APP_GUARD` in the auth module, Phase 2) read this metadata with `Reflector`.
  Controller sketch:
  ```ts
  @ApiTags('drawings') @ApiBearerAuth() @Controller('drawings')
  export class DrawingsController {
    @Post() create(@CurrentUser() user: AuthUser, @Body() dto: CreateDrawingDto) { … }   // APPROVED only
    @Get('search') @Public() search(@Query() q: SearchDto) { … }                          // only if the contract says [public]
  }
  ```
  Ownership checks belong in the service (`if (drawing.architectId !== user.id) throw new ApiException(403, 'FORBIDDEN', …)`).
- `/health` is already `@Public()`.

### Pagination
Use `common/pagination.ts`: extend/use `PageQueryDto` (`cursor`, `limit` 20/max 50), fetch `limit + 1` rows ordered by a stable key
(include `id` as tiebreaker), return `toPage(rows, limit, last => ({ …keysetValues }))` → `{ items, nextCursor }`; decode with `decodeCursor`.

### Money, ledger, time
Integer paise everywhere (Prisma `Int`/`BigInt`, never floats). Timestamps are returned as ISO strings (Date → JSON). Lengths in feet.

### Database
- Schema: `backend/prisma/schema.prisma`; change it with `npx prisma migrate dev --name <name> < /dev/null` (use `--create-only` and hand-edit when raw SQL is needed). See `docs/data-model.md` for DB-level rules (partial unique, triggers, FTS, ledger).
- Identifiers in raw SQL are quoted (`"Drawing"."pricePaise"`). Never write `Drawing.plotAreaSqft` or `searchVector`.
- Ledger: only through `LedgerService.postTransaction(entries, tx?)` (import `LedgerModule`; it is a feature module like any other). Pass the caller's `tx` from `prisma.$transaction(async (tx) => …)` to commit atomically with purchase/withdrawal updates.
- e2e DB: `globalSetup` migrates `sketchsquare_test` (override with `TEST_DATABASE_URL`); call `resetDb(prisma)` from `test/helpers/db.ts` in `beforeEach` (TRUNCATE ... CASCADE; ledger rows cannot be DELETEd).

### Tests
- Unit tests next to the code; infra-free (mock Prisma/Redis/S3).
- e2e: build `Test.createTestingModule({ imports: [AppModule] })`, then `configureApp(app)` before `app.init()` so the real pipe/filter apply;
  use Supertest. They hit the real docker Postgres (`sketchsquare_test`), Redis and MinIO, so infra must be up. Clean up the rows you create.
