# SketchSquare — Full Build Instructions for Copilot

You are building **SketchSquare** end to end in this repository. This single file is your complete brief.
Read the WHOLE file before writing any code. Then work through it autonomously.

## How you must work
1. **Read everything first.** Part 1 is the spec (product, stack, data model, rules). Part 2 is the build plan, split into phases 0–8. Part 3 lists business gaps and the defaults to use for them.
2. **Current state of the repo:** `sketch_square/` is the untouched default `flutter create` counter app (only `cupertino_icons` as a dependency, single commit, `.idea/` committed). There is no backend yet. Start from Phase 0.
3. **Save this spec into the repo** as `AGENTS.md` at the root and copy it to `.github/copilot-instructions.md`, so future sessions have it.
4. **Keep a progress file** at `docs/PROGRESS.md`: a checklist of every phase and sub-step. Tick items as you finish them. If you get interrupted or run out of context, re-read `AGENTS.md` and `docs/PROGRESS.md` and resume from the first unticked item. Never redo finished work.
5. **Execute phases strictly in order (0 → 8).** Do not start a phase until the previous one meets its acceptance criteria. Do not stop to ask me between phases — keep going.
6. **Verify every phase yourself** before moving on: run `flutter analyze`, `flutter test`, backend `npm run lint` and `npm test`, run migrations, hit the key endpoints. Fix failures before continuing. If something cannot be verified in your environment (e.g. emulator, real Razorpay keys), write it under "Needs manual check" in `docs/PROGRESS.md` and move on.
7. **Commit small and often** with clear messages (e.g. `feat(backend): drawing search with size tolerance`). At least one commit per sub-step; tag the end of each phase (`phase-0-done`, …).
8. **Ambiguity:** don't ask. Choose the simplest reasonable option consistent with Part 1, implement it, and record it in `docs/DECISIONS.md` with one line of reasoning.
9. **Only stop and ask me** if: a required secret/account is missing and there is no way to stub it, or a decision would be irreversible (e.g. deleting data, force-pushing). Everything external (payments, payouts, email, storage) must have a local/stub implementation so the whole app runs without real accounts.
10. **Don't drift:** don't swap the stack, don't add features not in this file, don't refactor unrelated code. If you notice you're unsure what a phase requires, re-read that phase here.
11. **When all phases are done**, write a final summary in `docs/PROGRESS.md`: what works, what's stubbed, the "Needs manual check" list, and exact commands to run everything.

---

# PART 1 — Project context (the spec)

## Product
SketchSquare is a mobile marketplace where **verified architects** upload, sell, buy and discover
architectural design drawings. Only verified architects can use the platform (buyers are architects too).
Key differentiator: **search by plot size** (length × breadth). Drawings are categorised by city,
and architects are ranked by rating.

## Repo layout (monorepo)
- `sketch_square/` — Flutter app (already exists; Dart SDK ^3.7). Android + iOS are the targets; web is nice-to-have.
- `backend/` — NestJS (TypeScript, Node 20 LTS) REST API.
- `infra/` — docker-compose for local dev (Postgres, Redis, MinIO, Mailpit).
- `docs/` — API contract (OpenAPI), ADRs, decisions log.

## Tech stack (fixed — do not swap)
### Mobile (Flutter)
- State: `flutter_riverpod` (with code gen `riverpod_annotation`)
- Routing: `go_router` with auth redirect guard
- HTTP: `dio` with interceptors (auth header, token refresh, error mapping)
- Models: `freezed` + `json_serializable`
- Secure token storage: `flutter_secure_storage`
- Media: `video_player`, `cached_network_image`, `file_picker`, `photo_view` (zoomable previews)
- Payments: `razorpay_flutter`
- Structure: feature-first — `lib/features/<feature>/{data,domain,presentation}`, shared code in `lib/core/`
### Backend
- NestJS + Prisma ORM + PostgreSQL 16
- Redis + BullMQ for background jobs (watermarking, preview generation, emails, payouts)
- Object storage: S3 API (MinIO locally, AWS S3 or Cloudflare R2 in prod). Buckets: `originals` (private), `previews` (public-read via CDN or signed), `kyc` (private)
- File processing: `sharp` (images), `pdf-lib` (PDF watermark), poppler `pdftoppm` (PDF → preview PNG)
- Auth: email + password (argon2id), JWT access token (15 min) + rotating refresh token (30 days, stored hashed)
- Email: Mailpit locally, Resend/SES in prod, behind an `EmailService` interface
- Payments: Razorpay Orders + webhook verification; withdrawals via RazorpayX Payouts behind a `PayoutProvider` interface (stub implementation for dev)
- Validation: `class-validator` DTOs; OpenAPI via `@nestjs/swagger`
- Tests: Jest unit + Supertest e2e against a test Postgres

## Domain model (source of truth — keep Prisma schema aligned)
- **User**: id, email (unique), passwordHash, fullName (immutable after signup), address (immutable), phone, avatarUrl,
  city, role (ARCHITECT | ADMIN), verificationStatus (PENDING | APPROVED | REJECTED), architectRating (cached avg),
  freeDownloadsUsed, createdAt.
- **VerificationRequest**: userId, coaRegistrationNumber (Council of Architecture, India), documentKey (S3, kyc bucket),
  status, reviewerId, reviewNote, submittedAt, reviewedAt.
- **Category**: id, name, slug, isActive. Seed: Houses, Villas, Hotels, Shopping Complex, Banks, Government Buildings.
- **CategoryRequest**: userId, requestedName, status (PENDING | APPROVED | REJECTED).
- **Drawing** (a listing / project): id, architectId, title, description, categoryId, city,
  plotLengthFt, plotBreadthFt (store in feet as decimals; app lets user enter ft or m and converts),
  plotAreaSqft (derived), floors, facing (N/E/S/W/NE/…, optional), pricePaise (integer; 0 = free),
  status (DRAFT | PROCESSING | PUBLISHED | REMOVED), avgRating, ratingCount, viewCount, purchaseCount, createdAt.
- **DrawingSheet**: drawingId, type (ARCHITECTURAL | STRUCTURAL | ELECTRICAL | SANITARY | PLUMBING | HVAC | OTHER),
  originalKey (private), originalMime, isPreview (bool — architect picks 1–2 sheets as samples),
  previewKey (watermarked low-res PNG), pHash (perceptual hash of preview, for plagiarism checks later).
- **Purchase**: id, buyerId, drawingId, pricePaise, platformFeePaise, status (CREATED | PAID | FAILED | REFUNDED),
  razorpayOrderId, razorpayPaymentId, createdAt. Unique (buyerId, drawingId) where status = PAID.
- **Review**: buyerId, drawingId, rating (1–5), comment. Only allowed if buyer has a PAID purchase (or a free download). One per buyer per drawing, editable.
- **DrawingView**: drawingId, viewerId, viewedAt (dedupe per viewer per 24h).
- **Interest** (future): userId, drawingId. **Favorite** (future): userId, drawingId.
- **CartItem**: userId, drawingId.
- **LedgerEntry** (double-entry, append-only): id, txnId, accountType (USER_WALLET | PLATFORM_REVENUE | PAYMENT_GATEWAY | PAYOUT_CLEARING),
  accountOwnerId (nullable), amountPaise (signed), entryType (SALE | PLATFORM_FEE | WITHDRAWAL | WITHDRAWAL_REVERSAL | REFUND),
  referenceId, createdAt. Every txnId must sum to zero. Wallet balance = SUM(amountPaise) for that user's USER_WALLET.
- **Withdrawal**: userId, amountPaise, bankAccount (encrypted at rest / tokenised by provider), status (REQUESTED | PROCESSING | PAID | FAILED), providerRef.
- **BankAccount**: userId, holderName, ifsc, accountNumberLast4, providerFundAccountId (never store full account number in plain text).

## Business rules
- Unverified users can log in but can only see a "verification pending" screen and edit their verification submission.
- Verification is manual by an ADMIN; target turnaround 24h. On approve → send "Welcome to SketchSquare" email. On reject → email with reason, user can resubmit.
- Free download limit per user: `FREE_DOWNLOAD_LIMIT` env var, default 20.
- Platform commission: `PLATFORM_FEE_BPS` env var, default 1000 (10%). Money is ALWAYS integer paise. Never use floats for money.
- Minimum withdrawal: `MIN_WITHDRAWAL_PAISE`, default 50000 (₹500).
- Architects cannot buy, review, or cart their own drawings.
- Originals are never publicly accessible. Downloads use short-lived (5 min) presigned URLs, only after an entitlement check (PAID purchase, or free drawing within quota).
- Preview sheets are shown as watermarked, downscaled images (max 1600px long edge) with a tiled diagonal watermark: "SketchSquare • <architect name> • PREVIEW".
- Purchased downloads of PDFs/images get a buyer-specific watermark footer: "Licensed to <buyer name> • <purchase id> • SketchSquare" so leaks are traceable.
- Accepted upload formats MVP: PDF, PNG, JPG. DWG/DXF accepted as an attached source file but not previewed or watermarked (flag in UI). Max 50 MB per file.
- Name and address are NOT updatable after signup. Phone, avatar, city are updatable.
- Removing a drawing sets status REMOVED: hidden from search, but past buyers keep download access.
- Webhooks (Razorpay) must be signature-verified and idempotent (store processed event ids).

## Engineering rules
- Keep the API contract in `docs/openapi.yaml` in sync (generate from Nest swagger).
- Every endpoint: DTO validation, auth guard, ownership checks, consistent error shape `{ error: { code, message, details? } }`.
- Pagination: cursor-based (`?cursor=&limit=`), default limit 20, max 50.
- No secrets in code. Use `.env` + `.env.example`. Flutter base URL via `--dart-define=API_BASE_URL=...`.
- Write tests for: auth, entitlement checks, ledger balancing, webhook idempotency, search filters.
- Small commits per sub-step with clear messages. Don't refactor unrelated code.
- If something in the spec is ambiguous, pick the simplest reasonable option, implement it, and log it in `docs/DECISIONS.md`.
- Before finishing any phase: `flutter analyze` clean, `flutter test` passes, `npm run lint && npm test` pass in backend.

## UI direction
Clean, minimal, architectural: off-white background, near-black text, one accent colour (deep blueprint blue #1F3A93),
generous whitespace, a blueprint grid motif used sparingly (splash, empty states). Typography: a geometric sans (e.g. Inter or Manrope via google_fonts).
Support light + dark theme. Bottom navigation with 5 tabs: Home, Featured, Upload, Basket, Profile.
---

# PART 2 — Build plan (execute phases in order, without waiting for me)

## Phase 0 — Clean up and scaffold

Phase 0: scaffold the monorepo. The repo currently has a default Flutter counter app in sketch_square/ and a committed .idea/ folder.

Do this:
1. Add a root .gitignore covering .idea/, node_modules, .env, build outputs, and remove .idea/ from git tracking (git rm --cached).
2. Create infra/docker-compose.yml with: postgres:16, redis:7, minio (with a bucket init container creating originals, previews, kyc buckets), mailpit. Healthchecks on all.
3. Create backend/ as a NestJS TypeScript project with Prisma, ESLint+Prettier, Jest, @nestjs/config with schema-validated env (zod or joi), @nestjs/swagger served at /docs, a /health endpoint checking DB + Redis + S3. Add .env.example with every variable mentioned in Part 1.
4. In sketch_square/: replace the counter app. Add the packages listed in Part 1. Set up lib/core/ (theme light+dark per UI direction, dio client with base URL from --dart-define, error model, secure storage wrapper), lib/app.dart with go_router, and a placeholder 5-tab shell (Home, Featured, Upload, Basket, Profile) using StatefulShellRoute so each tab keeps its own navigation stack. Update the app name to "SketchSquare".
5. Root README.md: how to run infra, backend, and the app (including the dart-define for API URL; Android emulator uses 10.0.2.2).
6. Add a GitHub Actions workflow: backend lint+test (with a postgres service), flutter analyze+test.

Acceptance criteria:
- `docker compose -f infra/docker-compose.yml up -d` brings everything up healthy.
- `npm run start:dev` in backend serves /health returning ok and /docs.
- `flutter run` shows the 5-tab shell with the new theme.
- CI workflow file is valid.
Commit in small steps. Then summarise what you did and anything you decided in docs/DECISIONS.md.
## Phase 1 — Database schema

Phase 1: implement the full Prisma schema for the domain model in Part 1 (including future tables Interest and Favorite, so we don't need painful migrations later).

- Use enums as defined. Add indexes for: Drawing(status, categoryId), Drawing(city), Drawing(plotLengthFt, plotBreadthFt), Drawing(pricePaise), Drawing(avgRating), User(architectRating), LedgerEntry(accountOwnerId, accountType), Purchase(buyerId), and a Postgres full-text GIN index on Drawing title+description (use a raw SQL migration for the tsvector column).
- Partial unique index: one PAID purchase per (buyerId, drawingId).
- Seed script: the 6 categories, 1 ADMIN user, 3 approved architects in different cities (Bengaluru, Delhi, Jaipur), ~15 published drawings with varied sizes/prices (some free), and placeholder preview images.
- Add a DB-level CHECK or a service-level guard + test that every ledger txnId sums to zero.

Acceptance: `npx prisma migrate dev` and `npm run seed` work from a clean DB. Write a short docs/data-model.md with an ER diagram in Mermaid.

## Phase 2 — Auth, onboarding video, architect verification

Phase 2: registration, login, verification.

Backend:
- POST /auth/signup (email, password, fullName, phone, address, city) → creates user with verificationStatus PENDING.
- POST /auth/login, POST /auth/refresh (rotate refresh token, detect reuse → revoke family), POST /auth/logout.
- POST /auth/forgot-password + /auth/reset-password via emailed token.
- POST /verification (multipart: coaRegistrationNumber + document PDF/JPG/PNG ≤10MB) → stores in kyc bucket. GET /verification/me for status.
- Admin endpoints (ADMIN role guard): GET /admin/verifications?status=PENDING, POST /admin/verifications/:id/approve, POST /admin/verifications/:id/reject {note}. Admin gets a presigned URL to view the document.
- On approve: enqueue a BullMQ email job sending the "Welcome to SketchSquare" email (HTML template). On reject: email with the reason.
- Global guard: routes other than auth/verification/profile-read require verificationStatus APPROVED → else 403 with code VERIFICATION_REQUIRED.
- Rate-limit auth endpoints (@nestjs/throttler).

Flutter:
- Intro screen for logged-out users: plays a ~30s demo video (assets/videos/intro.mp4 — add a placeholder and a TODO), muted autoplay with tap-to-unmute, a "Skip" button after 3 seconds, and "Sign in" / "Create account" buttons visible throughout. Show it only until the user has logged in once on this device (store a flag), afterwards go straight to login.
- Sign in, Sign up (2 steps: basic details → architect verification upload), Forgot password screens. Clear inline validation.
- "Verification pending" screen: shows status, submitted date, "we'll email you within 24 hours", option to resubmit if rejected, logout.
- go_router redirect: not logged in → intro/login; logged in but not APPROVED → pending screen; APPROVED → shell.
- Dio interceptor transparently refreshes the token on 401 once and retries; on failure logs out.
- A minimal Admin area inside the app, visible only to ADMIN role: list of pending verifications, view document, approve/reject with note.

Tests: e2e for signup → verify → approve → access granted; refresh token reuse detection; non-approved user blocked.
Acceptance: full flow works on emulator with Mailpit showing the welcome email.

## Phase 3 — Upload drawings, watermarking, previews

Phase 3: upload pipeline.

Backend:
- POST /drawings (create DRAFT with metadata: title, description, categoryId, city, plotLength, plotBreadth, unit ft|m, floors, facing, price in rupees → convert to paise, or isFree).
- POST /drawings/:id/sheets/upload-url → returns a presigned PUT URL for the originals bucket (validate type and size declared). Client uploads directly to S3.
- POST /drawings/:id/sheets (register sheet: type, objectKey, isPreview). Validate actual object exists, check mime by magic bytes server-side.
- POST /drawings/:id/publish → requires ≥1 sheet and 1–2 preview sheets → status PROCESSING → BullMQ job:
  - For preview sheets: PDF → render page 1 with pdftoppm; images → sharp. Downscale to 1600px, apply tiled diagonal watermark "SketchSquare • <architect name> • PREVIEW" at ~15% opacity, store in previews bucket, compute pHash and store it.
  - Mark PUBLISHED when done, FAILED-with-reason on error (surface to user).
- Download watermark: implement a WatermarkService that, given an original + buyer, produces a buyer-specific copy (PDF: footer on every page via pdf-lib; images: footer strip via sharp). Cache the result per purchase in S3. DWG/DXF: pass through unchanged.
- Add poppler-utils to the backend Dockerfile.

Flutter (Upload tab):
- Multi-step form: Details → Plot size (ft/m toggle, live area display) → Sheets (add multiple files via file_picker, pick sheet type for each, mark 1–2 as preview) → Pricing (Free / Paid with ₹ input, show "you'll receive ₹X after 10% platform fee") → Review & Publish.
- Upload progress per file, retry on failure, and save as draft if the user leaves.
- After publish, show "Processing previews…" and poll status.

Tests: watermark service unit tests with fixture PDF and PNG; publish rejects 0 or >2 preview sheets; non-owner cannot add sheets.
## Phase 4 — Home, search, filters, sort, drawing detail

Phase 4: discovery.

Backend: GET /drawings/search with query params:
- q (full-text over title/description), categoryId
- Size search: length, breadth, unit, tolerancePct (default 10) → match drawings where both dimensions are within tolerance; ALSO match the rotated plot (length↔breadth swapped). Return a `sizeMatch` score so exact matches rank first.
- city (multi), minDrawingRating, minArchitectRating, priceType (free|paid|all), minPrice, maxPrice
- sort: relevance (default) | price_asc | price_desc | drawing_rating | architect_rating | newest
- cursor pagination. Only PUBLISHED drawings from APPROVED architects.
- GET /drawings/:id detail (preview URLs, sheets list with types — not originals, architect summary, rating, reviews page 1, whether current user has purchased/carted). Record a DrawingView (dedupe 24h).
- GET /categories; POST /category-requests {name}; admin approve/reject endpoints (approving creates the category).
- GET /cities (distinct cities with published drawings, for the filter).
- GET /architects/:id public profile with their drawings, and GET /architects/top?city= ranked by architectRating (min 3 ratings to qualify).

Flutter:
- Home tab: search bar at top, horizontal category chips (+ "Request a category" chip opening a small sheet), a prominent "Search by plot size" entry (two numeric fields + unit toggle), then a grid of drawing tiles (preview image, title, size e.g. "30×40 ft", city, price or FREE badge, rating). Infinite scroll, pull to refresh, skeleton loaders, empty state.
- Search results screen with a Filters bottom sheet (dimensions, city multi-select, drawing rating, architect rating, free/paid/both, price range slider) and a Sort menu. Active filters shown as removable chips. Filters reflected in the URL/route state.
- Featured tab: top architects by city (city picker) + highest-rated drawings.
- Drawing detail: swipeable zoomable watermarked previews (photo_view), metadata, sheet list with type icons (locked), architect card → architect profile, reviews, sticky bottom bar: "Add to basket" / "Buy now" or "Download free (X of 20 left)" or "Download" if owned.

Tests: backend search tests for size tolerance + rotation, each filter, each sort, pagination stability.
## Phase 5 — Basket, payments, downloads, free quota

Phase 5: purchasing.

Backend:
- Cart: GET/POST/DELETE /cart. Reject own drawings, already-purchased, free drawings (those are downloaded directly).
- POST /checkout → creates Purchase rows (CREATED) + one Razorpay order for the cart total; returns orderId + key for the client.
- POST /payments/razorpay/webhook → verify signature, idempotent by event id. On payment.captured: in ONE DB transaction mark purchases PAID, write balanced ledger entries per purchase (PAYMENT_GATEWAY −total; seller USER_WALLET +net; PLATFORM_REVENUE +fee), increment purchaseCount, clear cart. On failure mark FAILED.
- Also POST /checkout/verify (client-side confirmation using razorpay signature) — but webhook is the source of truth; make both idempotent.
- GET /drawings/:id/download?sheetId= → entitlement check (owner, PAID purchase, or free drawing). Free: if not previously downloaded by this user, consume one from quota atomically (fail with FREE_LIMIT_REACHED at limit). Returns 5-min presigned URL to the buyer-watermarked copy (generate on first request, then cache).
- GET /me/purchases (purchased + free-downloaded drawings).
- Reviews: PUT /drawings/:id/review (only entitled buyers, not the owner); recompute drawing avgRating and architect rating in the same transaction.

Flutter:
- Basket tab: items, totals, remove, Checkout → Razorpay sheet → success/failure screens. Handle app kill mid-payment by refetching purchase status on resume.
- Download: download via the presigned URL to app documents, open with the system viewer, show in "My purchases".
- Prompt to rate after first download; review form on detail screen.
- Free quota indicator in Profile and on free drawings.

Tests: ledger sums to zero per txn; webhook replay does nothing the second time; concurrent free downloads at quota boundary can't exceed the limit; non-buyer cannot download or review.
Use Razorpay test mode keys from .env. Document the webhook setup for local dev (ngrok or Razorpay CLI) in README.
## Phase 6 — Manage drawings, wallet, withdrawals, profile

Phase 6: seller side and profile.

Backend:
- GET /me/drawings with per-drawing stats (views, purchases, avg rating, price, status).
- PATCH /drawings/:id (price, title, description — not size/category once published), DELETE /drawings/:id → status REMOVED (buyers keep access).
- GET /drawings/:id/buyers (owner only: buyer name, city, date, price) and GET /drawings/:id/viewers (owner only, last 30 days, deduped).
- GET /drawings/:id/reviews (paginated).
- Wallet: GET /wallet (balance computed from ledger, pending withdrawals), GET /wallet/ledger (paginated history with human-readable descriptions).
- Bank account: POST /wallet/bank-account (holder name, IFSC — validate format, account number) → create fund account via PayoutProvider, store only last4 + provider id.
- POST /wallet/withdrawals {amount} → check balance ≥ amount ≥ minimum, no other withdrawal in progress; in one transaction write ledger (USER_WALLET −amt, PAYOUT_CLEARING +amt), enqueue payout job. Job calls provider; on failure write reversal entries. Payout webhook updates status. Use a StubPayoutProvider in dev that succeeds after a delay.
- Profile: GET /me, PATCH /me (phone, city, avatar only — reject name/address changes with a clear error), avatar upload via presigned URL + sharp resize to 512px.

Flutter (Profile tab):
- Header: avatar (tap to change), name, city, verified badge, architect rating.
- Sections: My drawings (manage: stats, edit price, remove with confirm, see buyers/viewers/reviews), My purchases, Wallet (balance, ledger list, add bank account, withdraw with amount validation), Edit contact details, Settings (theme, logout), Admin (ADMIN only).
- Name and address shown read-only with a small "contact support to change" note.

Tests: withdrawal can't exceed balance under concurrency; failed payout reverses ledger; name/address immutable.
## Phase 7 — Hardening and release readiness

Phase 7: production readiness. Don't add features.

- Security: helmet, CORS allowlist, request size limits, rate limits on all write endpoints, audit log for admin actions, S3 buckets private except previews, presigned URLs short-lived, verify all ownership checks with a test per endpoint (write an authorization matrix test).
- Observability: structured JSON logs (pino) with request ids, Sentry for backend and Flutter, basic metrics endpoint.
- Performance: check EXPLAIN on the search query with 50k seeded drawings (add a script to seed that many) and fix indexes; image caching in Flutter; paginate everything.
- Flutter polish: loading/empty/error states on every screen, offline banner, accessibility (semantic labels, tap target sizes, text scaling up to 1.3), dark mode check on every screen.
- Deployment: production Dockerfile for backend, docker-compose.prod example, migration step on deploy, env checklist in docs/DEPLOY.md (suggest Render/Railway/Fly or an AWS EC2 + RDS + S3 setup — just document, don't provision).
- App release: app icon + splash (blueprint theme), Android signing config via env, iOS bundle id, privacy policy + terms placeholders linked from signup (terms must cover drawing licensing: buyer gets a usage licence, not resale rights).
- Write docs/TESTING.md with a manual QA checklist covering every user flow.

Acceptance: CI green, authorization matrix test passes, a release APK builds.

## Phase 8 — Future features (after Phase 7 is complete)

Phase 8: future features. Implement in this order, one commit group each, with tests:

1. Favorites: heart toggle on tiles/detail, "Favorites" list in Profile.
2. Express interest: "I'm interested" button for paid drawings; owner sees interested users in the viewers/interest screen; optional push notification later.
3. Contribution rule: an architect must have ≥1 free drawing published before their 2nd paid drawing can be published (make the ratio configurable via env). Show clear guidance in the Upload flow.
4. Plagiarism check at publish time (runs in the processing job):
   a. Compare each preview sheet's pHash against existing sheets with similar plot dimensions (±5%, including rotated) — Hamming distance ≤ threshold (configurable, start at 8) → flag.
   b. Also compare an exact SHA-256 of each original file across the whole platform → hard block.
   c. Flagged drawings go to status UNDER_REVIEW and appear in an admin queue showing both drawings side by side; admin approves or rejects. Notify the uploader.
5. Push notifications (FCM): verification result, sale made, withdrawal status, new review. Stub the FCM sender if no credentials are available.

---

# PART 3 — Business gaps: use these defaults, don't block on them

The original product doc doesn't cover these. Implement the default described, make it configurable where sensible, and list each in `docs/DECISIONS.md` as "needs owner confirmation".

- **Licensing terms:** buyer gets a non-exclusive licence to use the drawing for their own projects; no resale or re-upload. Put this in the placeholder Terms screen and show a one-line licence notice on the checkout screen.
- **Refunds/disputes:** admin-only refund action in the Admin area. Marks the purchase REFUNDED, writes reversing ledger entries (seller wallet debit + platform fee reversal), revokes download access, and calls Razorpay refund via a provider interface (stub in dev). If the seller's wallet would go negative, allow it and block their withdrawals until it's positive.
- **Tax (GST/TCS/TDS):** don't implement tax calculation. Structure the ledger so a TAX entry type and account can be added later, and add a TODO in `docs/DECISIONS.md`.
- **RazorpayX payouts:** use the StubPayoutProvider by default; the real provider activates only when its env keys are set.
- **30-second demo video:** ship a placeholder asset (a short generated clip or a static image fallback if no video file exists) and a TODO to replace it.
