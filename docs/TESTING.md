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

Generated sheets are random noise on purpose: the backend rejects byte-identical files and holds visually similar previews
`UNDER_REVIEW` (plagiarism check), which would stall the publish wait. The script also covers the contribution rule (a
further paid drawing without enough free ones → 403 `CONTRIBUTION_REQUIRED`; skipped when `CONTRIBUTION_FREE_PER_PAID=0`)
and the interest flow.

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

`test/contract/api_fixtures_test.dart` replays the captured backend JSON (`test/fixtures/api/*.json`) through the real Dio repositories and models; re-capture with the smoke script after any API change.

Presigned upload/download URLs use the host in `S3_PUBLIC_ENDPOINT` (default `http://localhost:9000`). A phone or Android emulator cannot reach that: set it to a host the device can resolve (emulator: `http://10.0.2.2:9000`) before booting the backend.

Run the app against a local backend with `--dart-define=API_BASE_URL=http://localhost:3100` (Android emulator: `http://10.0.2.2:3100`).

### Automated accessibility / theme coverage

`test/a11y/` pumps every screen (signed in, admin, pending verification, signed out, legal) on a 360×640 phone at **text scale 1.3** in **light and dark** themes; any overflow or build error fails the test. It also runs Flutter's Android tap-target (≥ 48 dp) and labelled-target guidelines on key screens. When you add a screen, add its route to `screens_matrix_test.dart`.

## Flutter release builds (`sketch_square/`)

Dart defines (all optional except the API URL for anything but an emulator):

| Define | Meaning |
|---|---|
| `API_BASE_URL` | Backend origin, e.g. `https://api.example.com` |
| `SENTRY_DSN` | Enables Sentry crash reporting (off when unset; PII off, 10 % traces) |
| `SENTRY_ENVIRONMENT` / `SENTRY_RELEASE` | Optional Sentry tags (default environment `development`) |

```bash
cd sketch_square
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com --dart-define=SENTRY_DSN=...
flutter build web --dart-define=API_BASE_URL=https://api.example.com
```

`flutter build web` and `flutter build apk --release` both succeed on the dev machine (APK ≈ 62 MB, `build/app/outputs/flutter-apk/app-release.apk`). If an APK build fails with "Android SDK licenses not accepted" on a fresh machine, the owner must run `flutter doctor --android-licenses` once (agents never accept licenses). iOS needs Xcode and was not built here (`flutter build ipa` on a Mac with a signing team).

**Android signing.** Without configuration the release APK is signed with the *debug* key (fine for local testing, never upload it to a store; Gradle prints a warning). For a store build create a keystore once (`keytool -genkey -v -keystore ~/sketchsquare-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias sketchsquare`) and either:

- create `sketch_square/android/key.properties` (gitignored, never commit it or the `.jks`):
  ```properties
  storeFile=/absolute/path/to/sketchsquare-release.jks
  storePassword=...
  keyAlias=sketchsquare
  keyPassword=...
  ```
- or export `SKETCHSQUARE_KEYSTORE_PATH`, `SKETCHSQUARE_KEYSTORE_PASSWORD`, `SKETCHSQUARE_KEY_ALIAS`, `SKETCHSQUARE_KEY_PASSWORD` (CI).

Back the keystore up: losing it means you can never update the published app.

**Identity.** Android `applicationId` and iOS bundle id are `com.sketchsquare.app`; app name is `SketchSquare`; version comes from `pubspec.yaml` (`version: 1.0.0+1`, `+N` is the build number).

**Icon and splash** are generated, not hand-drawn: `dart run tool/generate_brand_assets.dart` writes `assets/branding/*.png` (blueprint blue `#1F3A93` with a sketched-square mark), then `dart run flutter_launcher_icons` and `dart run flutter_native_splash:create` regenerate the Android/iOS/web icons and splash screens. After running them `git checkout` any unrelated changes under `linux/`, `macos/`, `windows/` (plugin registrants) and `ios/Runner/Info.plist`. Replace `assets/branding/app_icon.png` (1024 px) with real artwork any time and re-run the two commands.

**Intro video.** `assets/videos/intro.mp4` is a placeholder; the intro screen falls back to `assets/branding/intro_fallback.png` (a static blueprint image) when the video cannot play. TODO: drop the real ~30 s demo in at the same path.

## Manual QA checklist (device or emulator)

Run against a seeded local backend (`docs/TESTING.md` smoke prerequisites) with `S3_PUBLIC_ENDPOINT` reachable from the device. Do each flow once in light mode and once with Settings → Theme = Dark; repeat the key screens with the system font size at its largest setting.

**First run and auth**
- [ ] App icon and splash show the blueprint design; no white flash at launch.
- [ ] Intro screen plays (or shows the static backdrop); mute toggle works; Skip, Create account and Sign in all work and the intro is not shown again.
- [ ] Sign up step 1 validation (email, password rules, phone, city); Terms and Privacy links open the legal screens and come back with the form intact; consent text is visible.
- [ ] Sign up step 2: pick a PDF/JPG/PNG verification document; account is created and the "pending verification" screen shows; Refresh status works; sign out works.
- [ ] Admin approves the account (admin login → Verifications → open → approve); the architect signs in and lands on Home.
- [ ] Sign in with wrong password shows the server message; forgot password → code → reset password → sign in.
- [ ] Kill and reopen the app: session persists; theme choice persists.

**Browse and buy**
- [ ] Home: categories, latest drawings, plot-size search validation, search by text, filters sheet, sort, paging, "Request a category".
- [ ] Drawing detail: gallery swipe/zoom/full screen, watermark label, facts, reviews, favorite heart, add to basket, free-download path.
- [ ] Featured tab: top architects and architect profile.
- [ ] Basket: remove an item, totals, Checkout shows the licence notice and a working "Read the Terms of Service" link; Pay (stub in dev: success → Purchases; or Razorpay test key on a real device: success, cancel, failure → "Try again").
- [ ] Purchases: download, open and share each sheet; free-download quota text; leave a review.

**Sell**
- [ ] Upload: details step (tags, plot size ft/m), sheets (add, remove, reorder), pricing (Free/Paid; contribution-rule banner), publish; status goes Processing → Published (or Under review for a plagiarism flag).
- [ ] Manage drawings: list, filters, stats, edit price/description, remove.
- [ ] Profile: change photo, edit phone/city, stats, Settings, sign out.
- [ ] Wallet: balance and ledger, add/edit bank account, withdraw (validation, success, failure + reversal), payout history, negative-balance message.

**Admin**
- [ ] Verifications list/detail (open document, approve, reject with reason), Refunds (search, detail, refund with reason), Plagiarism review (approve, reject with reason).

**Polish**
- [ ] Offline banner: switch on airplane mode → the "No connection. Retrying…" banner (with Retry) appears without losing the current screen; turn it off → banner disappears within about 5 s and lists reload on pull-to-refresh/Retry.
- [ ] Every list shows a skeleton/spinner while loading, an empty state when empty, and an error with Retry when the backend is stopped.
- [ ] TalkBack/VoiceOver: icon buttons are announced (Remove, Download, Favorite, Show password, …); drawing images are not read as noise.
- [ ] Dark mode: no unreadable text or invisible icons on any screen; images/thumbnails have sensible placeholders.
- [ ] Sentry (only if built with `SENTRY_DSN`): throw a test error from a debug build and confirm it appears with the right environment/release and no personal data.
