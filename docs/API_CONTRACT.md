# SketchSquare API contract (v1)

Single source of truth shared by `backend/` (NestJS) and `sketch_square/` (Flutter) so both can be built in parallel.
`docs/openapi.yaml` is generated from the backend and must conform to this document. If the backend needs to deviate,
update **this file in the same PR** and note it in `docs/DECISIONS.md`.

## Conventions
- JSON, `camelCase`, no URL prefix (e.g. `POST /auth/login`). Ids are UUID strings. Timestamps are ISO-8601 UTC strings.
- Money is always **integer paise** (`pricePaise`, `amountPaise`, ...). Lengths are stored/returned in **feet** (decimals).
- Auth: `Authorization: Bearer <accessToken>`; access token 15 min, refresh token 30 days (rotating).
- Errors: HTTP status + `{ "error": { "code": "SOME_CODE", "message": "human text", "details": {...}? } }`.
  Codes: `VALIDATION_ERROR` (400), `UNAUTHORIZED` (401), `FORBIDDEN` (403), `VERIFICATION_REQUIRED` (403), `NOT_FOUND` (404),
  `CONFLICT` (409), `FREE_LIMIT_REACHED` (403), `CONTRIBUTION_REQUIRED` (403), `INSUFFICIENT_BALANCE` (400), `BELOW_MIN_WITHDRAWAL` (400),
  `WITHDRAWAL_BLOCKED` (403), `UPLOAD_INVALID` (400), `RATE_LIMITED` (429), `INTERNAL` (500).
- Pagination: cursor-based. Request `?cursor=<opaque>&limit=20` (default 20, max 50). Response `{ "items": [...], "nextCursor": "<opaque>"|null }`.
- Unless stated, endpoints require a logged-in **APPROVED** user. Endpoints marked `[auth]` only need a valid token (any verification status);
  `[public]` need nothing; `[admin]` need role ADMIN.

## Shared object shapes
```jsonc
User {
  "id", "email", "fullName", "address", "phone", "avatarUrl": string|null, "city",
  "role": "ARCHITECT"|"ADMIN", "verificationStatus": "PENDING"|"APPROVED"|"REJECTED",
  "architectRating": number, "freeDownloadsUsed": int, "freeDownloadLimit": int, "createdAt"
}
Tokens { "accessToken", "refreshToken", "expiresIn": 900 }
ArchitectSummary { "id", "fullName", "city", "architectRating": number, "ratingCount": int, "avatarUrl": string|null }
DrawingSummary {                       // tile in lists
  "id", "title", "category": {"id","name","slug"}, "city",
  "plotLengthFt": number, "plotBreadthFt": number, "plotAreaSqft": number, "floors": int, "facing": string|null,
  "pricePaise": int, "isFree": bool, "avgRating": number, "ratingCount": int,
  "previewUrl": string|null, "architect": ArchitectSummary, "status": DrawingStatus, "createdAt",
  "sizeMatch": number|null            // 0..1, only present for size searches (1 = exact)
}
Sheet { "id", "type": "ARCHITECTURAL"|"STRUCTURAL"|"ELECTRICAL"|"SANITARY"|"PLUMBING"|"HVAC"|"OTHER",
        "isPreview": bool, "previewUrl": string|null /* only preview sheets */, "originalMime", "fileName", "sizeBytes": int }
DrawingStatus = "DRAFT"|"PROCESSING"|"PUBLISHED"|"UNDER_REVIEW"|"REMOVED"|"FAILED"
Review { "id", "rating": 1..5, "comment": string|null, "reviewer": {"id","fullName"}, "createdAt", "updatedAt" }
```

## Auth `[public]`
| Method & path | Body | Response |
|---|---|---|
| `POST /auth/signup` | `{email,password(min 8),fullName,phone,address,city}` | `201 {user: User, tokens: Tokens}` (verificationStatus PENDING). 409 `CONFLICT` if email exists. |
| `POST /auth/login` | `{email,password}` | `{user, tokens}` |
| `POST /auth/refresh` | `{refreshToken}` | `{tokens}` (rotates; reuse of an old token revokes the family → 401) |
| `POST /auth/logout` | `{refreshToken}` | `204` |
| `POST /auth/forgot-password` | `{email}` | `204` (always, no user enumeration) |
| `POST /auth/reset-password` | `{token,newPassword}` | `204` |

## Verification `[auth]`
- `POST /verification` multipart (`coaRegistrationNumber`, `document` PDF/JPG/PNG ≤10MB) → `201 VerificationRequest`. Resubmit allowed when REJECTED (or still PENDING: replaces).
- `GET /verification/me` → `{ "verification": VerificationRequest|null }`
- `VerificationRequest { id, coaRegistrationNumber, status: "PENDING"|"APPROVED"|"REJECTED", reviewNote: string|null, submittedAt, reviewedAt: string|null }`

## Admin `[admin]`
- `GET /admin/verifications?status=PENDING&cursor&limit` → page of `{ id, status, coaRegistrationNumber, submittedAt, user: {id,fullName,email,phone,city,address} }`
- `GET /admin/verifications/:id` → same + `documentUrl` (presigned, 5 min) + `reviewNote`
- `POST /admin/verifications/:id/approve` → `{ok:true}`; `POST /admin/verifications/:id/reject` body `{note}` → `{ok:true}`
- `GET /admin/category-requests?status=PENDING` → page of `{id, requestedName, status, user:{id,fullName}, createdAt}`;
  oldest first, cursor-paged. `POST /admin/category-requests/:id/approve` (creates or re-activates the Category) → `{ok:true, category:{id,name,slug}}` / `.../reject` → `{ok:true}`; 409 `CONFLICT` if the request was already decided.
- `GET /admin/purchases?q&status=CREATED|PAID|FAILED|REFUNDED&buyerId&drawingId&cursor&limit` → page of
  `AdminPurchase { id, status, pricePaise, platformFeePaise, sellerNetPaise, razorpayOrderId, razorpayPaymentId, createdAt, paidAt, buyer:{id,fullName,email}, seller:{id,fullName,email}, drawing:{id,title}, refund: AdminRefund|null }`,
  newest first (`createdAt desc, id desc`), all statuses when `status` is omitted. `q` is a case-insensitive match on purchase id (UUID), Razorpay order/payment id, buyer/seller name or email, drawing title.
- `GET /admin/purchases/:id` → `AdminPurchase` + `sellerBalancePaise` (the seller's current wallet balance, may be negative); 404 `NOT_FOUND`.
- `POST /admin/purchases/:id/refund` body `{reason}` (trimmed, 3–500 chars) → `200 {ok:true, alreadyRefunded:boolean, refund: AdminRefund}`.
  `AdminRefund { id, reason, amountPaise, refundedAt, refundedBy:{id,fullName}, providerStatus:"PENDING"|"SUCCEEDED"|"FAILED", providerRefundId:string|null, providerError:string|null }`.
  Full refunds only. One DB transaction (row-locked, idempotent): purchase `PAID→REFUNDED`, reversing `REFUND` ledger entries
  (`PAYMENT_GATEWAY +price`, seller `USER_WALLET −net`, `PLATFORM_REVENUE −fee`; zero-sum), `purchaseCount −1`, `AuditLog`. The gateway call runs after the commit; if it fails the refund stays booked with `providerStatus:"FAILED"` and calling again retries only the gateway (`alreadyRefunded:true`).
  Errors: 400 `VALIDATION_ERROR` (missing/short reason), 403 `FORBIDDEN` (non-admin), 404 `NOT_FOUND`, 409 `CONFLICT` (purchase is not PAID/REFUNDED).
  Effects: the refunded purchase no longer entitles the buyer (download → 403 `FORBIDDEN`, gone from `/me/purchases`, cannot review/edit a review). The seller's wallet may go negative; `POST /wallet/withdrawals` then returns 403 `WITHDRAWAL_BLOCKED` until the balance is ≥ 0 (`GET /wallet` `withdrawalBlocked:true`).
- Phase 8: `GET /admin/review-queue` → page of `{ drawing: DrawingSummary, flaggedAgainst: DrawingSummary[], reason }`, `POST /admin/review-queue/:drawingId/approve|reject`

## Profile
- `GET /me` `[auth]` → `User`
- `PATCH /me` `[auth]` body `{phone?,city?}` → `User` (sending `fullName` or `address` → 400 `VALIDATION_ERROR` "cannot be changed")
- `POST /me/avatar/upload-url` body `{contentType}` → `{uploadUrl, objectKey, headers}` (PUT the image with that `Content-Type`; jpeg/png/webp, ≤ 5 MB); then `POST /me/avatar/confirm` body `{objectKey}` → `User` (backend resizes to 512px)

## Categories, cities, architects
- `GET /categories` → `[{id,name,slug}]` (active only). `POST /category-requests` body `{name}` (2–60 chars) → `201 {id,requestedName,status}`; 409 `CONFLICT` if an active category already has that name; repeating your own pending request returns it unchanged.
- `GET /cities` → `[{city, count}]` (cities with searchable drawings, most drawings first; spellings differing only by case are merged)
- `GET /architects/top?city=` → `[ArchitectSummary & {drawingCount}]` (APPROVED architects with ≥3 ratings, sorted by rating desc then rating count; max 20; `city` is the architect's city, case-insensitive)
- `GET /architects/:id` → `{ architect: ArchitectSummary, drawings: page of DrawingSummary }` (first page, newest first; `GET /architects/:id/drawings?cursor&limit` for more; 404 unless the architect is APPROVED)

## Drawings — seller side
- `POST /drawings` body `{title,description,categoryId,city,plotLength,plotBreadth,unit:"ft"|"m",floors,facing?,bedrooms?:int(0-20),tags?:string[](≤8, each ≤24 chars),pricePaise,isFree?}` → `201 DrawingDetail` (DRAFT).
  `bedrooms`/`tags` are optional additions requested by the Flutter upload form; `DrawingDetail` returns them as `bedrooms: int|null`, `tags: string[]`.
  The app sends them by default (`--dart-define=UPLOAD_SEND_EXTENDED_METADATA=false` disables it for an older backend).
  `isFree=true` forces `pricePaise=0`.
- `PATCH /drawings/:id` owner; draft: any field; published: only `{title,description,pricePaise}`.
- `DELETE /drawings/:id` owner → `204`, status REMOVED (past buyers keep access).
- `POST /drawings/:id/sheets/upload-url` body `{fileName,contentType,sizeBytes}` → `{uploadUrl, objectKey, headers: {...}}` (client PUTs the file with those headers; ≤50MB; PDF/PNG/JPG/DWG/DXF)
- `POST /drawings/:id/sheets` body `{type,objectKey,isPreview,fileName,sizeBytes}` → `201 Sheet` (server verifies object exists + magic bytes)
- `PATCH /drawings/:id/sheets/:sheetId` body `{type?,isPreview?}`; `DELETE /drawings/:id/sheets/:sheetId` → `204`
- `POST /drawings/:id/publish` → `202 {status:"PROCESSING"}` (needs ≥1 sheet and 1–2 preview sheets, else 400 `VALIDATION_ERROR`). Poll `GET /drawings/:id` until `status` is `PUBLISHED`, `UNDER_REVIEW` or `FAILED` (`failureReason` set). `FAILED` also covers the plagiarism hard block (a file identical to one already published by another architect; fix by replacing the sheet and publishing again). `UNDER_REVIEW` means a preview looks like another architect's drawing on a similar plot and an admin must approve it (the uploader is emailed; the drawing is invisible to others meanwhile).
- `POST /drawings/:id/publish` on a **paid** drawing (`pricePaise > 0`) additionally enforces the contribution rule: the architect needs `CONTRIBUTION_FREE_PER_PAID` (env, default 1, `0` = off) PUBLISHED free drawings per paid drawing they already have (published, processing or under review) — so the 1st paid drawing is always allowed, the 2nd needs 1 free one. Otherwise `403 CONTRIBUTION_REQUIRED` with `details {freePublished, paidPublished, paidPending, freePerPaid, freeNeeded}` and a human `message`; the drawing stays DRAFT/FAILED.
- `GET /me/contribution-status` → `{ freePublished, paidPublished, paidPending, freePerPaid, freeNeeded, canPublishPaid: bool, guidance: string }` (`canPublishPaid` = may publish another paid drawing now; `freeNeeded` = extra free drawings required; show `guidance` in the upload flow).
- `GET /me/drawings?status=&cursor&limit` → page of `{ drawing: DrawingSummary, stats: {viewCount,purchaseCount,avgRating,ratingCount} }`
- `GET /drawings/:id/buyers` owner → page of `{buyer:{id,fullName,city}, pricePaise, purchasedAt}`
- `GET /drawings/:id/viewers` owner (last 30 days, deduped) → page of `{viewer:{id,fullName,city}, lastViewedAt}`
- `GET /drawings/:id/reviews?cursor&limit` → page of `Review`

## Discovery
`GET /drawings/search` → page of `DrawingSummary` (PUBLISHED drawings of APPROVED architects only). Query params:
`q` (full-text, English stemming), `categoryId`, `architectId`, `length` + `breadth` (**both or neither**, else 400), `unit` (`ft`|`m`, default ft),
`tolerancePct` (0–50, default 10; relative to each requested dimension, inclusive; both dimensions must be in tolerance in the *same* orientation, and the rotated plot (length↔breadth) also matches),
`city` (repeatable, case-insensitive), `minDrawingRating`, `minArchitectRating`, `priceType` (`free`|`paid`|`all`), `minPricePaise`, `maxPricePaise`, `floors` (repeatable), `bedrooms` (repeatable, 0–20), `tag` (repeatable, ≤5; a drawing must have all of them, case-insensitive), `facing` (repeatable),
`sort` (`relevance`|`price_asc`|`price_desc`|`drawing_rating`|`architect_rating`|`newest`|`popularity`|`size_match`), `cursor`, `limit`.
`sizeMatch` = `1 - worstRelativeDeviation / tolerance` for the better orientation (1 = exact, 0 = on the tolerance edge, still a match). `size_match` sort requires a size (400 otherwise).
`relevance` = `ts_rank` of `q` + `sizeMatch`; with neither it behaves like `newest`. Every sort has an `id` tiebreaker. The cursor is opaque, bound to the sort it was issued for (400 `VALIDATION_ERROR` if reused with another sort), and stable under concurrent inserts.

`GET /drawings/:id` → `DrawingDetail`:
```jsonc
DrawingDetail = DrawingSummary & {
  "description", "floors", "viewCount", "purchaseCount", "failureReason": string|null,
  "sheets": [Sheet],                       // never includes original keys/urls
  "reviews": { "items": [Review], "nextCursor" },   // first page
  "viewer": { "isOwner": bool, "isPurchased": bool, "inCart": bool, "canDownload": bool,
              "freeDownloadsRemaining": int|null, "myReview": Review|null }
}
```
Also includes `bedrooms: int|null` and `tags: string[]`. Records a DrawingView (deduped per viewer per 24 h; the returned `viewCount` includes it) except for the owner, admins and non-published drawings. Non-published drawings (and published ones of non-APPROVED architects) are visible only to the owner/admin and 404 for everyone else; `failureReason` is only returned to them. `sheets` lists every sheet's metadata but only preview sheets carry a watermarked `previewUrl`. `viewer.canDownload` mirrors the download entitlement (owner, PAID purchase, or a free drawing that is already claimed / within the free quota); `viewer.freeDownloadsRemaining` is the caller's remaining free quota on free drawings (else null).
`GET /drawings/:id/reviews?cursor&limit` → page of `Review`, newest first (same visibility as the detail).

## Cart, checkout, payments, downloads
- `GET /cart` → `{ items: [DrawingSummary], totalPaise }`; `POST /cart` body `{drawingId}` → cart; `DELETE /cart/:drawingId` → cart.
  Rejects own, already-purchased and free drawings (400 `VALIDATION_ERROR` with a clear message).
- `POST /checkout` → `{ orderId, razorpayKeyId, amountPaise, currency:"INR", purchaseIds:[...] }`. `razorpayKeyId == "stub"` means stub mode.
- `POST /checkout/verify` body `{razorpayOrderId,razorpayPaymentId,razorpaySignature}` → `{status:"PAID"|"FAILED"}` (idempotent; webhook is source of truth)
- `POST /checkout/stub-complete` body `{orderId}` → `{status:"PAID"}`; only available when Razorpay keys are not configured (stub mode), simulates the captured-payment webhook.
- `GET /checkout/status?orderId=` → `{status:"CREATED"|"PAID"|"FAILED"}` (client polls after app resume)
- `POST /payments/razorpay/webhook` `[public]` signature-verified, idempotent by event id.
- `GET /drawings/:id/download?sheetId=` → `{ url, expiresInSeconds: 300, fileName }` (entitlement: owner, PAID purchase, or free within quota; else 403 `FORBIDDEN` / `FREE_LIMIT_REACHED`)
- `GET /me/purchases?cursor&limit` → page of `{ kind:"PAID"|"FREE", purchasedAt, pricePaise, purchaseId: string|null, drawing: DrawingSummary & {sheets:[Sheet]} }`
- `PUT /drawings/:id/review` body `{rating,comment?}` → `Review` (entitled non-owner only)

## Wallet `[approved]`
- `GET /wallet` → `{ balancePaise, pendingWithdrawalPaise, minWithdrawalPaise, withdrawalBlocked: bool, bankAccount: {holderName,ifsc,accountNumberLast4}|null }`
- `GET /wallet/ledger?cursor&limit` → page of `{ id, entryType, amountPaise, description, referenceId, createdAt }`
- `POST /wallet/bank-account` body `{holderName (2–100), ifsc (^[A-Z]{4}0[A-Z0-9]{6}$, case-insensitive), accountNumber (9–18 digits)}` → `200 {holderName,ifsc,accountNumberLast4}` (create or replace; only the last 4 digits are stored; `409 CONFLICT` while a withdrawal is in flight)
- `POST /wallet/withdrawals` body `{amountPaise}` → `201 Withdrawal`; `GET /wallet/withdrawals` → page of `Withdrawal`. Errors: `400 VALIDATION_ERROR` (no bank account), `400 BELOW_MIN_WITHDRAWAL`, `400 INSUFFICIENT_BALANCE`, `403 WITHDRAWAL_BLOCKED` (negative balance), `409 CONFLICT` (another withdrawal in flight). The amount leaves the wallet immediately; a failed payout returns it.
- `Withdrawal { id, amountPaise, status: "REQUESTED"|"PROCESSING"|"PAID"|"FAILED", failureReason: string|null, createdAt, updatedAt }`
- `POST /payments/razorpayx/webhook` `[public]` RazorpayX payout events (`payout.processed|failed|rejected|cancelled|reversed`), signature-verified, idempotent by event id.

## Phase 8 additions
- `PUT /drawings/:id/favorite`, `DELETE /drawings/:id/favorite` → `204`; `GET /me/favorites` → page of `DrawingSummary`.
  Both writes are idempotent (repeating them is a `204` no-op). `PUT` only works on PUBLISHED drawings of APPROVED architects (else 404 `NOT_FOUND`; your own drawing is allowed); `DELETE` always `204`.
  `GET /me/favorites` is newest-favourited first and omits drawings that are no longer listable (removed/unpublished); it is not an extra `isFavorite` field on search tiles — use `viewer.isFavorite` on the detail, or treat every item of the favourites list as a favourite.
- `PUT /drawings/:id/interest`, `DELETE /drawings/:id/interest` → `204` (both idempotent); `GET /drawings/:id/interests` owner only → page of `{user:{id,fullName,city}, createdAt}`, newest first (`GET /drawings/:id/interested` is an alias).
  `PUT` rules: drawing must be PUBLISHED by an APPROVED architect (else 404 `NOT_FOUND`), must be **paid** (free → 400 `VALIDATION_ERROR`), must not be your own (403 `FORBIDDEN`). `DELETE` is always `204`. The list is 403 `FORBIDDEN` for non-owners (admins included) and 404 for unknown drawings; it still works for the owner after the drawing is removed.
- `DrawingDetail.viewer` additionally gets `isFavorite: bool`, `isInterested: bool`
- `POST /me/device-tokens` body `{token, platform}` → `204` (FCM)

## Ops
- `GET /health` `[public]` → `{ status:"ok", checks: { db, redis, s3 } }`; `GET /docs` Swagger UI.
