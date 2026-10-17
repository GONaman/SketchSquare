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
  (`AuthState.initializing | unauthenticated | authenticated(user)`, real since Phase 2 — see "Flutter auth" below). Theme: `appThemeModeProvider`.
- Repositories: define an interface in `domain/`, an implementation in `data/` taking `Dio`, and a `@riverpod` provider that builds it from `dioProvider`.
  Screens depend on the interface provider so tests can override it with a fake.
- Pagination: request `?cursor=&limit=`, parse with `CursorPage.fromJson(json, Item.fromJson)`.

### Errors
- The error interceptor puts an `ApiException` (`code`, `message`, `details?`, `statusCode`) into `DioException.error`.
  In repositories/controllers use `catch (e) { throw toApiException(e); }` and branch on `ApiErrorCodes.*` (all contract codes are defined).
  Client-only codes: `NETWORK_ERROR`, `TIMEOUT`, `CANCELLED`, `UNKNOWN`.
- The auth-header interceptor reads `TokenStore`; the refresh-on-401 interceptor sits next to it in `core/network/dio_client.dart`.

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

### Access control (guards) — implemented in `src/auth/`
Decorators: `Public`, `AllowUnverified`, `Roles` from `common/decorators/access.decorators` (re-exported by `src/auth/decorators`);
`CurrentUser` + `AuthUser` (`{id,email,fullName,role,verificationStatus}`) from `common/decorators/current-user.decorator`.
- `@Public()` — no token (contract `[public]`), `@AllowUnverified()` — token required, any verificationStatus (contract `[auth]`),
  `@Roles('ADMIN')` — role restriction (contract `[admin]`). Undecorated routes = logged-in + APPROVED. ADMINs skip the approval check.
- Guards are global (`APP_GUARD` in `AuthModule`, order: throttler → `JwtAuthGuard` (401 `UNAUTHORIZED`) → `RolesGuard` (403 `FORBIDDEN`) →
  `ApprovedGuard` (403 `VERIFICATION_REQUIRED`)). **New controllers need no guard wiring** — just add the decorators the contract asks for.
  The user is re-read from the DB per request, so approval/role changes apply immediately (access tokens carry only `sub` + `role`).
  Import `AuthModule` only if you need `TokenService` / `PasswordService` (`src/auth/guards` exports the guard classes for unit tests).
- Rate limit: global 300 req/min/IP (`@nestjs/throttler`); tighten per route with `@Throttle({ default: { limit: 10, ttl: 60_000 } })` → 429 `RATE_LIMITED`.
  `RATE_LIMIT_ENABLED=false` disables it (the e2e setup does this by default).
- Contract `User` JSON: `toUserResponse(user, freeDownloadLimit)` from `src/auth/user.mapper.ts`.
- e2e helper: `createTestUser(app, { role?, verificationStatus?, email? })` from `test/helpers/auth.ts` inserts a user and returns
  `{ user, password, accessToken, refreshToken }`; use `.set(...bearer(u))` on supertest requests.
  ```ts
  @ApiTags('drawings') @ApiBearerAuth() @Controller('drawings')
  export class DrawingsController {
    @Post() create(@CurrentUser() user: AuthUser, @Body() dto: CreateDrawingDto) { … }   // APPROVED only
    @Get('search') @Public() search(@Query() q: SearchDto) { … }                          // only if the contract says [public]
  }
  ```
  Ownership checks belong in the service (`if (drawing.architectId !== user.id) throw new ApiException(403, 'FORBIDDEN', …)`).
- `/health` is already `@Public()`. A test-only demo controller registered in a test module must carry `@Public()` (or a token), too.
- Parallel worktrees share `sketchsquare_test`; `resetDb` truncates it, so set `TEST_DATABASE_URL` to a per-worktree DB (auto-created) when several agents run e2e at once.

### Pagination
Use `common/pagination.ts`: extend/use `PageQueryDto` (`cursor`, `limit` 20/max 50), fetch `limit + 1` rows ordered by a stable key
(include `id` as tiebreaker), return `toPage(rows, limit, last => ({ …keysetValues }))` → `{ items, nextCursor }`; decode with `decodeCursor`.

### Money, ledger, time
Integer paise everywhere (Prisma `Int`/`BigInt`, never floats). Timestamps are returned as ISO strings (Date → JSON). Lengths in feet.

### Database
- Schema: `backend/prisma/schema.prisma`; change it with `npx prisma migrate dev --name <name> < /dev/null` (use `--create-only` and hand-edit when raw SQL is needed). See `docs/data-model.md` for DB-level rules (partial unique, triggers, FTS, ledger).
- Identifiers in raw SQL are quoted (`"Drawing"."pricePaise"`). Never write `Drawing.plotAreaSqft` or `searchVector`.
- Ledger: only through `LedgerService.postTransaction(entries, tx?)` (import `LedgerModule`; it is a feature module like any other). Pass the caller's `tx` from `prisma.$transaction(async (tx) => …)` to commit atomically with purchase/withdrawal updates.
- Seed: `npm run seed` (idempotent, see `backend/prisma/README-seed.md` for the dev accounts/passwords; `prisma migrate reset --force` re-runs it). Extend `prisma/seed.ts` with fixed-id upserts when a later phase needs sample data.
- e2e DB: `globalSetup` migrates `sketchsquare_test` (override with `TEST_DATABASE_URL`); call `resetDb(prisma)` from `test/helpers/db.ts` in `beforeEach` (TRUNCATE ... CASCADE; ledger rows cannot be DELETEd).

### Tests
- Unit tests next to the code; infra-free (mock Prisma/Redis/S3).
- e2e: build `Test.createTestingModule({ imports: [AppModule] })`, then `configureApp(app)` before `app.init()` so the real pipe/filter apply;
  use Supertest. They hit the real docker Postgres (`sketchsquare_test`), Redis and MinIO, so infra must be up. Clean up the rows you create.

## Flutter auth (`sketch_square/lib/features/auth`, Phase 2.4–2.6)

### Session
- `authControllerProvider` is a real session: `AuthState.initializing` (validating stored tokens via `GET /me`) → `unauthenticated | authenticated(user)`.
  Methods (`signIn`, `signUp`, `signOut`, `refreshUser`) throw `ApiException`. Read the user with `ref.watch(authControllerProvider)` and pattern-match `Authenticated(:final user)`.
- Tokens live in `TokenStore` (secure storage). `AuthRepository` (interface, `DioAuthRepository`) is a pure API client; the controller persists tokens.
  Override `authRepositoryProvider` with a fake in tests (`test/helpers/fake_auth_repository.dart`).
- `RefreshInterceptor` (`core/network/refresh_interceptor.dart`) refreshes on 401 (single-flight, retries once, skips `/auth/*`) and, if the server rejects the
  refresh token, clears tokens and bumps `sessionExpiredProvider` → the controller signs out. Transport/5xx failures during refresh keep the session.
- `sharedPreferencesProvider` has no default: `main()` and `pumpApp` override it. `introSeenProvider` is the onboarding flag.

### Router guard
`authRedirect(auth, location, {introSeen})` (pure, unit-tested): initializing → `/splash`; logged out → public auth routes (`AppRoutes.publicRoutes`) else intro (first run) /
sign-in; PENDING/REJECTED → `/verification-pending` (and `/sign-up`, so the document step can finish); APPROVED → app, `/admin*` only for role ADMIN.
New logged-out screens must be added to `AppRoutes.publicRoutes`; new non-tab routes of a feature go in its `*_routes.dart` and are spread into the router.

### Screens
- Logged-out screens use `AuthFormScaffold` + `PasswordField` (`presentation/widgets/`), validators from `AuthValidators` (domain, pure), and show failures with `FormErrorBanner`;
  `serverFieldErrors(apiException)` maps a contract `VALIDATION_ERROR` (`details.fields`) to `TextFormField.forceErrorText`.
- Navigate between logged-out screens with `go` when the next screen can change the auth state (sign-up), `push` otherwise (A7).
- `VerificationForm` (features/verification) is the shared COA number + document form; pickers/repositories are injected via `documentPickerProvider` /
  `verificationRepositoryProvider` so tests use `FakeDocumentPicker` / `FakeVerificationRepository` (`test/helpers/fake_verification.dart`).
- The intro video is built through `introVideoBuilderProvider` (tests override it; `video_player` has no test platform). The asset is a placeholder (A11).
- Widget tests of logged-out flows: `pumpLoggedOut(tester, {auth, verification, picker, introSeen})` in `test/helpers/auth_test_utils.dart` (tall viewport, fakes wired).

### Verification status and admin
- `VerificationStatusScreen` (`/verification-pending`) shows status, request details, rejection reason, refresh, and (re)submit via `VerificationForm`; status rule in A12.
- Admin lives in `features/admin` (`adminRoutes` at top-level `/admin`, `/admin/verification/:id`), reached from the Profile tab only for role ADMIN; the guard also blocks non-admins.
  `AdminRepository` / `DioAdminRepository` follow the contract; `PendingVerifications` is a paged AsyncNotifier. Tests use `FakeAdminRepository` and `makeAdminVerification`
  (`test/helpers/fake_admin.dart`); `pumpApp` wires fakes for admin, verification and document picker by default. Override `documentLauncherProvider` instead of hitting url_launcher.

### Testing
`pumpApp(tester, {signedIn = true, user, introSeen = true})` boots the whole app with a `FakeAuthRepository`; by default you are an approved architect
on the shell, so existing feature tests are unaffected. Use `signedIn: false` for logged-out flows, `user:` for PENDING/REJECTED/ADMIN sessions.
`test/helpers/scripted_adapter.dart` is a tiny scriptable Dio adapter for stateful HTTP sequences (e.g. 401 then 200).

### Commerce (basket / checkout)
- Repositories (`CartRepository`, `CheckoutRepository`) and platform seams (`PaymentGateway`, `PendingCheckoutStore`) are interfaces in `features/basket/domain`; Dio/Razorpay/prefs implementations live in `data/`, wired by keepAlive providers in `basket_providers.dart`. Tests override them with the fakes in `test/features/basket/fakes.dart` (`FakeCartRepository`, `FakeCheckoutRepository`, `FakePaymentGateway`).
- Controllers that cache per-user data must `ref.watch(currentUserIdProvider)` (`features/auth/presentation/current_user_provider.dart`) so they rebuild on sign-in/out.
- Tab screens in an `IndexedStatefulShell` stay mounted; refresh on re-activation with `TickerMode.of(context)` + `WidgetsBindingObserver` resume (see `basket_screen.dart`).
- Checkout state is a sealed class (`CheckoutIdle/Processing/Success/Failure/Pending`); screens only react to it, all payment logic is in `CheckoutController`.
- Shared fixtures: `fakeDrawing()` / `fakeSheet()` in `test/helpers/commerce_fixtures.dart`.
- Purchases/download seams: `PurchasesRepository`, `ReviewRepository`, `FileDownloader` (bare Dio, no auth), `FileHandler` (open/share) in `features/purchases/domain`; fakes in `test/features/purchases/fakes.dart` (`fakePurchase`, `FakePurchasesRepository` pages by index cursor). Paged lists use `PagedState` + `retryLoadMore()`.
- `core/format/file_size.dart` → `formatBytes`.
- Profile (`features/profile`): `ProfileRepository` / `AvatarPicker` interfaces, fakes in `test/features/profile/fakes.dart`. Subroutes live in `profile_routes.dart`; path constants in `AppRoutes` (`profileEdit`, `settings`, `wallet`, `manageDrawings`).
- Link to routes owned by other agents with `pushIfRegistered(context, AppRoutes.x)` (`core/router/route_utils.dart`): it shows a "Coming soon" snackbar if the path is not registered yet.
- In widget tests list `...discoveryFakes()` FIRST in `overrides`, otherwise it replaces your `architectsRepositoryProvider` override.
- Wallet (`features/wallet`): `WalletRepository` + `DioWalletRepository`, fakes in `test/features/wallet/fakes.dart`. `WalletController` (summary + `saveBankAccount` / `withdraw`), `LedgerController` / `WithdrawalsController` (`PagedState`). All validation lives in `WalletValidators` (pure, unit-tested); server codes map through `WalletValidators.messageFor`.
- Infinite lists inside a plain `ListView(children: …)`: append `LoadMoreSentinel` (`core/widgets/load_more_sentinel.dart`) keyed by the item count; it calls `loadMore` once it is built.

## Flutter discovery (home / search / detail)
- Routes: `DiscoveryPaths(base)` builds `search`/`drawing`/`architect` locations under a tab; `discoverySubRoutes(paths)` registers the sub-routes, so Home and Featured share screens.
- Search state is the URL: `DrawingSearchQuery` <-> query string (`drawing_search_query_uri.dart`). Screens derive the query from the route; change it with `context.go(paths.search(query))` and open results with `push`.
- `DrawingSearchController` (family keyed by query) holds `PagedState<DrawingSummary>` (`core/pagination`); render with `pagedDrawingSlivers(...)` (skeleton, error retry, empty, grid, prefetch + footer). Text input is debounced 400 ms.
- Plot size: `PlotSizeController` + `PlotSizeFields`; validation lives in `domain/plot_size.dart` (`validatePlotSize`). Money/size formatting only through `presentation/formatters.dart` (`formatPaise` etc.).
- Tests: fakes and JSON builders in `test/features/drawings/fixtures.dart` (`discoveryFakes()`, `FakeDrawingsRepository` records `searchCalls`). The shell keeps Home mounted behind Search, so filter `searchCalls` by query when asserting. Never `pumpAndSettle` while a page request is in flight (spinner animates forever).
- Detail/profile/featured: `DrawingDetailScreen`, `ArchitectProfileScreen` (`ArchitectProfileController`, same paging as search) and `FeaturedScreen` are mounted by `discoverySubRoutes` under each tab, so tapping through stays inside the tab's stack.
- Gallery images load through `galleryImageResolverProvider`; tests override it (done by `discoveryFakes()`) and call `precacheGalleryImage(tester)` before navigating to a detail, otherwise the PhotoView spinner never settles.


## Flutter upload (`sketch_square/lib/features/upload`, Phase 3.5)

- Layers: `domain/` (pure: `DrawingForm`, validators, `money.dart`, `SheetFileRules`, repository interfaces), `data/` (Dio repo, presigned `DioSheetUploader`,
  `FilePickerSheetPicker`, `SharedPrefsDraftStore`), `presentation/` (`UploadFlow` controller + `widgets/` per step). Everything external is behind an interface with a provider.
- `uploadFlowProvider` is `keepAlive`: the flow survives tab switches. `UploadScreen` calls `ensureLoaded({resumeDraftId})`; deep-link to a draft with `/upload?draft=<id>`.
- Upload state machine per sheet: `queued → uploading(progress) → registering → done | failed`. Files upload sequentially; a failed registration keeps `objectKey`
  so retry skips the PUT. Stale async work is dropped through a generation counter (`startNew`, reload, dispose).
- Resume-safe: server DRAFT (+ sheets) is the source of truth, a local snapshot (`upload.draft.v1`) holds unsynced form edits and the step. Picked-but-not-uploaded files are not restored.
- Publish: `POST /drawings/:id/publish` then poll `GET /drawings/:id` (2 s, ≤150 tries; 5 consecutive errors → `pollStalled`, resume with `resumePolling`).
- Client limits (title/description lengths, plot range, fee estimate) are UI guard rails; the backend is authoritative and its `ApiException` messages are surfaced.
- Testing: `test/features/upload/fakes.dart` has `FakeUploadRepository`, `FakeSheetUploader` (`hold` completer to freeze progress), `FakeSheetPicker`, `InMemoryDraftStore`;
  override `uploadDelayProvider` with `(_) async {}` so polling is instant. Widget tests pump `UploadScreen` in a tall (800×3000) viewport to avoid scrolling.

## Flutter manage drawings (`sketch_square/lib/features/manage_drawings`, Phase 6.4)

- Route `AppRoutes.manageDrawings` (`/manage-drawings`) is registered via `manageDrawingsRoutes`; link to it with `context.push(AppRoutes.manageDrawings)` (e.g. from the profile tab).
- `ManageDrawingsRepository` (`GET /me/drawings`, `GET/PATCH/DELETE /drawings/:id`) + Dio impl; `managedDrawingsControllerProvider(filter)` pages with a cursor, filters out `REMOVED`, and updates its list locally after edit/remove.
- `actionsFor(status)` in `managed_drawing_card.dart` is the single place deciding which actions a status offers; stats show only for published/under-review drawings.
- Testing: `test/features/manage_drawings/fakes.dart` has `FakeManageDrawingsRepository` (`failNext`, `listFilters`, `updates`, `count`); widget tests use a small GoRouter harness to assert `/upload?draft=<id>` navigation. Avoid `pumpAndSettle` with processing cards (indeterminate progress bar).

## Backend hardening (Phase 7)

- **Rate limits:** every POST/PUT/PATCH/DELETE already counts against the `write` throttler (`RATE_LIMIT_WRITE_PER_MIN`, per IP and route, Redis-backed). Tighten sensitive routes with `@Throttle({ write: { limit, ttl } })`; never use `@SkipThrottle` on a write route.
- **Admin actions:** every `@Roles('ADMIN')` mutation must call `AuditService.record({ actorId, action: '<domain>.<verb>', entityType, entityId, metadata }, tx)` inside the decision's transaction (`AuditModule` is global).
- **Errors from middleware** (oversized/malformed body) are mapped by `AllExceptionsFilter`; keep client-error mapping there rather than in controllers.
- **Env:** new variables go into `env.schema.ts` and `.env.example`; production-only requirements belong in the schema (hard fail) or the startup guard (escape hatch available).
- **Authorization matrix (adding a route):** `backend/test/authz-matrix.ts` lists every route with its access level (`public` / `authed` / `approved` / `admin`, plus `owner: true` for drawing-owner routes). `authz-matrix.e2e-spec.ts` enumerates the routes from the Nest container and **fails if a route has no entry**, if an entry has no route, or if the declared level differs from the `@Public`/`@AllowUnverified`/`@Roles` decorators. When you add a controller method: add one line to the matrix; for owner-scoped routes also add a scenario in `OWNER_SCENARIOS` (non-owner → 403/404, owner allowed). On a rebase conflict in the matrix, keep both sides.
- **Logging:** use Nest's `Logger` (it is pino underneath, request id attached automatically); never `console.*`, never log request bodies, tokens or secrets. Put new secret-bearing field names in `observability/redact.ts`. Errors must go through `AllExceptionsFilter` so they carry `X-Request-Id`.
- **New operational endpoints** (like `/metrics`) are `@Public()` only when they have their own access control; add them to the authorization matrix and `@ApiExcludeController()` if they are not product API.
