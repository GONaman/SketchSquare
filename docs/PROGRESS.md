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
- [ ] 2.1 Backend auth (signup/login/refresh/logout/reset)
- [ ] 2.2 Backend verification + admin + email jobs + global guard
- [ ] 2.3 Backend e2e tests
- [x] 2.4 Flutter auth core (interceptor, router guard)
- [x] 2.5 Flutter intro/sign in/sign up/forgot
- [x] 2.6 Flutter pending screen + admin area

## Phase 3 — Upload pipeline
- [x] 3.1 Drawings CRUD + categories (seller create/patch/delete; category list/requests live in the discovery module)
- [x] 3.2 Storage + sheets (presigned upload, magic bytes)
- [ ] 3.3 Publish + processing worker (previews, pHash)
- [x] 3.4 WatermarkService
- [x] 3.5 Flutter upload flow (domain/data #11, controller #17, multi-step UI + tests)

## Phase 4 — Discovery
- [ ] 4.1 Search endpoint (size tolerance + rotation, filters, sort)
- [ ] 4.2 Detail, categories, cities, architects
- [x] 4.3 Flutter home + search + filters
- [ ] 4.4 Flutter featured + drawing detail

## Phase 5 — Purchasing
- [x] 5.1 Cart + checkout + Razorpay (stub) + webhook + ledger
- [ ] 5.2 Downloads + free quota + reviews
- [x] 5.3 Flutter basket/checkout/download/reviews (basket, checkout, order result, purchases library + download/open/share, review sheet; the reviews *list* is part of the drawing detail screen and reuses `DrawingsRepository.listReviews`)

## Phase 6 — Seller side, wallet, profile
- [ ] 6.1 Manage drawings + stats endpoints
- [ ] 6.2 Wallet + bank account + withdrawals + payouts
- [ ] 6.3 Profile endpoints
- [ ] 6.4 Flutter profile, manage drawings, wallet

## Phase 7 — Hardening
- [ ] 7.1 Security + authorization matrix test
- [ ] 7.2 Observability + perf
- [ ] 7.3 Flutter polish
- [ ] 7.4 Deployment docs + release build + TESTING.md

## Phase 8 — Future features
- [ ] 8.1 Favorites
- [ ] 8.2 Express interest
- [ ] 8.3 Contribution rule
- [ ] 8.4 Plagiarism check + admin review queue
- [ ] 8.5 Push notifications (stub)

## Needs manual check
- Admin area (2.6): "Open document" uses `url_launcher` (external app) on the presigned `documentUrl`; verify on a device. Approve/reject/list were only tested against fakes and a scripted Dio adapter, not the real backend (2.1/2.2).
- Flutter intro video (`sketch_square/assets/videos/intro.mp4`) is a placeholder; TODO replace with the real ~30 s demo. `video_player` playback itself is only checked on a device/emulator (tests stub it).
- Flutter document picker (`file_picker`) on iOS/macOS/Android: verify picking PDF/JPG/PNG on a real device (platform permissions/entitlements untested).
- Password-reset email link does not open the app (no deep-link setup); users paste the code from the email (A10).
- Discovery (4.3): eyeball the drawing grid on real devices and at large text scales; check keyboard/focus behaviour of the search field and plot-size fields; verify cursor paging and `sizeMatch` against the real backend once 4.1 is merged; cached-image behaviour of `DrawingPreviewImage` is untested.
