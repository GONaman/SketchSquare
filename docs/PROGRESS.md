# SketchSquare — Progress

Resume rule: re-read `AGENTS.md` and this file, then continue from the first unticked item.
Workflow: every sub-step is a small branch → PR → squash-merge into `main` (never push to `main` directly).

## Phase 0 — Scaffold
- [x] 0.1 Repo hygiene (.gitignore, untrack .idea, AGENTS.md, copilot-instructions, progress/decisions docs)
- [x] 0.2 infra/docker-compose.yml (postgres, redis, minio + bucket init, mailpit)
- [x] 0.3 backend NestJS scaffold (config, swagger, health, Prisma, lint/test)
- [x] 0.4 Flutter core (theme, dio, error model, secure storage, router, 5-tab shell)
- [x] 0.5 Root README
- [x] 0.6 GitHub Actions CI

## Phase 1 — Database schema
- [x] 1.1 Prisma schema + migration (enums, indexes, partial unique, FTS)
- [x] 1.2 Seed script
- [x] 1.3 Ledger zero-sum guard + test
- [x] 1.4 docs/data-model.md

## Phase 2 — Auth, onboarding, verification
- [x] 2.1 Backend auth (signup/login/refresh/logout/reset)
- [x] 2.2 Backend verification + admin + email jobs + global guard
- [x] 2.3 Backend e2e tests
- [x] 2.4 Flutter auth core (interceptor, router guard)
- [x] 2.5 Flutter intro/sign in/sign up/forgot
- [x] 2.6 Flutter pending screen + admin area

## Phase 3 — Upload pipeline
- [x] 3.1 Drawings CRUD + categories (seller create/patch/delete; category list/requests live in the discovery module)
- [x] 3.2 Storage + sheets (presigned upload, magic bytes)
- [x] 3.3 Publish + processing worker (previews, pHash)
- [x] 3.4 WatermarkService
- [x] 3.5 Flutter upload flow (domain/data #11, controller #17, multi-step UI + tests)

## Phase 4 — Discovery
- [x] 4.1 Search endpoint (size tolerance + rotation, filters, sort)
- [x] 4.2 Detail, categories, cities, architects
- [x] 4.3 Flutter home + search + filters
- [x] 4.4 Flutter featured + drawing detail

## Phase 5 — Purchasing
- [x] 5.1 Cart + checkout + Razorpay (stub) + webhook + ledger
- [x] 5.2 Downloads + free quota + reviews
- [x] 5.3 Flutter basket/checkout/download/reviews (basket, checkout, order result, purchases library + download/open/share, review sheet; the reviews *list* is part of the drawing detail screen and reuses `DrawingsRepository.listReviews`)

## Phase 6 — Seller side, wallet, profile
- [x] 6.1 Manage drawings + stats endpoints
- [x] 6.2 Wallet + bank account + withdrawals + payouts (stub payouts; RazorpayX via env)
- [x] 6.3 Profile endpoints (GET/PATCH /me, avatar upload-url + confirm)
- [x] 6.4 Flutter profile, manage drawings, wallet — profile (identity, public stats, edit phone/city, avatar upload, settings with theme + sign out); manage drawings (seller list, filters, stats, edit published, remove; route `AppRoutes.manageDrawings`); wallet (balance, ledger, bank account, withdraw, payout history). Written against the contract; the backend wallet endpoints (6.2) and profile endpoints (6.3) are not merged yet, so wallet/avatar flows are verified with fakes + Dio contract tests only

## Phase 7 — Hardening
- [x] 7.1 Security + authorization matrix test
- [x] 7.2 Observability + perf
- [x] 7.3 Flutter polish — theme mode persisted; offline banner (HTTP-driven, no extra plugin); cached images everywhere; every async screen has loading/empty/error states (checkout fixed); Semantics + tooltips + ≥48 dp targets; tests pump every screen in light/dark at 1.3× text scale (`test/a11y/`); Sentry via `SENTRY_DSN` define; placeholder Privacy/Terms screens linked from sign-up, settings and checkout
- [ ] 7.4 Deployment docs + release build + TESTING.md — Flutter half done: generated blueprint icon/splash, bundle id `com.sketchsquare.app`, Android signing from `key.properties`/env, intro static fallback, `flutter build web` + `flutter build apk --release` succeed, manual QA checklist in docs/TESTING.md. Backend deployment docs remain

## Phase 8 — Future features
- [x] 8.1 Favorites — backend done (`PUT/DELETE /drawings/:id/favorite`, `GET /me/favorites`, `viewer.isFavorite`); Flutter done: detail heart (optimistic + rollback) and Favorites list under Profile (`/profile/favorites`, heart on its tiles). Needs manual check: search/home tiles carry no favorite state (the API's `DrawingSummary` has no `isFavorite`)
- [x] 8.2 Express interest — backend done (`PUT/DELETE /drawings/:id/interest`, `GET /drawings/:id/interests`, `viewer.isInterested`); Flutter done: "I'm interested" toggle on paid, non-own, unpurchased drawing detail (optimistic + rollback) and an owner "Interested" list (bottom sheet from the paid published card in Manage Drawings); push on new interest comes with 8.5
- [x] 8.3 Contribution rule — backend + Flutter (Upload → Pricing shows `GET /me/contribution-status` guidance, disables Paid when `canPublishPaid` is false, friendly `CONTRIBUTION_REQUIRED` message)
- [x] 8.6 Refunds/disputes (Part 3) — backend: `GET /admin/purchases[/:id]`, `POST /admin/purchases/:id/refund`, `RefundProvider` (stub/Razorpay), TAX enum reserved; Flutter: Admin → Refunds screens (search, detail, refund with reason + confirm) and a clearer negative-balance withdrawal-blocked message in the wallet
- [x] 8.4 Plagiarism check + admin review queue — backend: SHA-256 hard block + pHash flagging in the processing job, `GET /admin/plagiarism-flags`, `POST …/:id/approve|reject` + emails; Flutter admin review screen (`/admin/plagiarism`, side-by-side previews, approve/reject-with-reason) + uploader messaging (upload status and Manage Drawings) done; pHash threshold needs tuning on real plans
- [x] 8.5 Push notifications — backend done (`PushService` with FCM v1 sender when `FCM_*` env set, otherwise a logging stub; `POST/DELETE /me/device-tokens`, `GET /me/notifications`, `POST /me/notifications/read`; events: verification result, sale, withdrawal paid/failed, new review, interest); Flutter done: in-app Notifications list under Profile (`/profile/notifications`, unread badge, mark read / mark all read, optimistic + rollback) and a `PushService` seam (no-op default) that registers/unregisters the device token on sign-in/out; FCM itself is not wired (see Needs manual check)

## Needs manual check
- Push (8.5): Flutter ships `PushService` with a no-op implementation, so no device token is ever registered. To enable push: add `firebase_core` + `firebase_messaging`, the Firebase config (`google-services.json` / `GoogleService-Info.plist`), implement `PushService` over `FirebaseMessaging.instance`, and override `pushServiceProvider` (see `features/notifications/domain/push_service.dart`). Push payload deep links are not handled; tapping a notification in the in-app list navigates.
- Flutter release (7.4): the debug-signed release APK builds locally; create a real keystore and `android/key.properties` (docs/TESTING.md) before any store upload. iOS was not built (no Xcode here): check the icon/launch screen/bundle id `com.sketchsquare.app` and set a signing team. Eyeball the generated icon and splash on a device (light + dark launch) and replace `assets/branding/app_icon.png` with real artwork if wanted.
- Legal (7.4): Privacy Policy and Terms are placeholder text (`features/legal/presentation/legal_content.dart`) and need review by counsel; the Terms state the buyer's non-exclusive licence and the no-resale / no-re-upload rule but not jurisdiction, refunds or the seller agreement.
- Intro video: `assets/videos/intro.mp4` is still a placeholder (static `intro_fallback.png` shows if it cannot play); replace with the real demo.
- Offline banner (7.3): detection is driven by failed/succeeding API calls and a 5 s `/health` probe, not the OS network state; try airplane mode and a stopped backend on a device. Sentry (7.3) was only unit-tested with a fake init; send one real event with a DSN.
- Refunds (8.6): Flutter Admin → Refunds screens and the wallet's negative-balance message were only tested against fakes and a scripted Dio adapter; try a real refund end to end (search → detail → refund → buyer loses access, seller wallet drops, Withdraw disabled) on a device and eyeball the dialog and the negative-balance warning. The real Razorpay refund call (`RazorpayRefundProvider`) is only unit-tested with a fake `fetch`; verify against Razorpay test keys (refund id, idempotency header, partial-failure retry). The stub provider is used whenever keys are unset (refused in production).
- Integration (smoke + web): `backend/scripts/smoke.ts` (21 steps) passes against the real API and its JSON is replayed through every Flutter Dio repository (`sketch_square/test/contract/`). Flutter web (login, home, detail, featured, basket, profile) was driven headlessly against the live backend and renders. **Not exercised through the Flutter UI:** upload (file picker), stub checkout button, download/open/share, wallet/bank/withdraw screens, avatar upload, admin screens, real Razorpay checkout (`razorpay_flutter` is mobile-only), and any native device. Phase 8 backend features (interest, refunds, contribution status, plagiarism review) have no Flutter client yet beyond showing the server `message` for `CONTRIBUTION_REQUIRED`.
- Presigned URLs use `S3_PUBLIC_ENDPOINT`; set it to a host the device can reach (Android emulator `http://10.0.2.2:9000`) or uploads/previews fail on-device while working on web/iOS simulator.
- Search: the backend also supports `floors`, `facing`, `bedrooms`, `tag` filters and `popularity` / `size_match` sorts; the Flutter filter sheet does not expose them yet (contract superset, no mismatch).
- Smoke script: the backend holds visually similar previews `UNDER_REVIEW` and blocks byte-identical files, so generated test sheets must be random noise (already handled); reusing fixed sample images would stall publish.
- Refunds (8.6): the real Razorpay refund call (`RazorpayRefundProvider`) is only unit-tested with a fake `fetch`; verify against Razorpay test keys (refund id, idempotency header, partial-failure retry). The stub provider is used whenever keys are unset (refused in production).
- Admin area (2.6): "Open document" uses `url_launcher` (external app) on the presigned `documentUrl`; verify on a device. Approve/reject/list were only tested against fakes and a scripted Dio adapter, not the real backend (2.1/2.2).
- Flutter intro video (`sketch_square/assets/videos/intro.mp4`) is a placeholder; TODO replace with the real ~30 s demo. `video_player` playback itself is only checked on a device/emulator (tests stub it).
- Flutter document picker (`file_picker`) on iOS/macOS/Android: verify picking PDF/JPG/PNG on a real device (platform permissions/entitlements untested).
- Password-reset email link does not open the app (no deep-link setup); users paste the code from the email (A10).
- Discovery (4.3): eyeball the drawing grid on real devices and at large text scales; check keyboard/focus behaviour of the search field and plot-size fields; verify cursor paging and `sizeMatch` against the real backend once 4.1 is merged; cached-image behaviour of `DrawingPreviewImage` is untested.
- Search: full-text `q` uses `plainto_tsquery` (no prefix matching; stopword-only queries match nothing). Perf numbers are from 50k synthetic rows on local Postgres; re-check with real data volume (data-model.md, SR6).
- Drawing detail (4.4): pinch-zoom/swipe of the `photo_view` gallery (and the full-screen preview) on a real device; the "Download" button is a placeholder snackbar until the download flow (5.3) lands; favorites call `PUT/DELETE /drawings/:id/favorite`, which the backend only implements in Phase 8 (the heart reverts with the server's error until then).
