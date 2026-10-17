# Conventions

Each section is owned by one agent; append, don't overwrite other sections.

## Backend

_(Backend agent: add NestJS module/DTO/error/pagination conventions here.)_

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
