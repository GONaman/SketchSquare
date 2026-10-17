# Decisions log

One line of reasoning per decision. Items marked **needs owner confirmation** are business gaps from Part 3 of `AGENTS.md`.

| # | Decision | Reasoning |
|---|----------|-----------|
| D1 | Work happens via small feature branches merged by squash PR; `main` is never pushed to directly. | Owner requirement. |
| D2 | Old Firebase-based prototype (local, uncommitted) is not carried over; the spec mandates our own NestJS backend. | Spec Part 1 stack is fixed. |
| D3 | Generated Dart code (`*.g.dart`, `*.freezed.dart`) is committed. | Keeps `flutter analyze`/`test` reproducible without a codegen step in CI. |
| D4 | MinIO runs from `bitnamilegacy/minio` in docker-compose. | `minio/minio` and `minio/mc` Docker Hub images were not pullable on the dev network; Bitnami's image bundles the `mc` client too. |
| D5 | Flutter uses Riverpod 2.6 (`flutter_riverpod`/`riverpod_annotation`/`riverpod_generator` ^2.6) rather than 3.x. | `riverpod_generator` 3.x/4.x require Dart ≥3.8; the pinned SDK is Dart 3.7. |
| D6 | Flutter fonts: Inter via `google_fonts` runtime download (falls back to the platform font offline); tests turn it off via `AppTheme.useGoogleFonts = false`. | Avoids committing font binaries now; bundle Inter as an asset in Phase 7 (release readiness) if offline-first typography matters. |
| D7 | Auth session in Flutter is a stub (`authControllerProvider` returns an approved architect `User`) until Phase 2. Sign-in / verification-pending routes are placeholder screens so the redirect guard has targets. | Lets the shell render and the guard be unit-tested now. |
| D8 | `razorpay_flutter` is in `pubspec.yaml` (builds for web and passes analyze/test) but unused until Phase 5. | Spec stack; no conflicts found. |
