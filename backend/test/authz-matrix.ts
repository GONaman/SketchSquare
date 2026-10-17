import type { AccessLevel } from './helpers/routes';

/**
 * AUTHORIZATION MATRIX — one entry per HTTP route registered in the Nest container.
 *
 * `authz-matrix.e2e-spec.ts` fails when a route exists without an entry here (and when an entry has no route),
 * and cross-checks `access` against the decorators the global guards actually read:
 *   public   @Public()               — no token needed
 *   authed   @AllowUnverified()      — valid token, any verification status
 *   approved (default)               — valid token + APPROVED architect (admins pass)
 *   admin    @Roles('ADMIN')         — ADMIN only
 * `owner: true` additionally marks routes scoped to the drawing's owner; they MUST have a scenario in the spec's
 * OWNER_SCENARIOS (non-owner → 403/404, owner → allowed).
 *
 * Keys are `METHOD /path` exactly as declared (controller path + handler path, no global prefix).
 */
export interface MatrixEntry {
  access: AccessLevel;
  owner?: true;
}

export const AUTHZ_MATRIX: Record<string, MatrixEntry> = {
  // --- auth (public; protected by the stricter auth throttles) ---
  'POST /auth/signup': { access: 'public' },
  'POST /auth/login': { access: 'public' },
  'POST /auth/refresh': { access: 'public' },
  'POST /auth/logout': { access: 'public' },
  'POST /auth/forgot-password': { access: 'public' },
  'POST /auth/reset-password': { access: 'public' },
  'GET /health': { access: 'public' },
  // Webhooks authenticate via HMAC signature, not JWT.
  'POST /payments/razorpay/webhook': { access: 'public' },
  'POST /payments/razorpayx/webhook': { access: 'public' },

  // --- own account / verification (token only) ---
  'GET /me': { access: 'authed' },
  'PATCH /me': { access: 'authed' },
  'POST /me/avatar/upload-url': { access: 'authed' },
  'POST /me/avatar/confirm': { access: 'authed' },
  'GET /verification/me': { access: 'authed' },
  'POST /verification': { access: 'authed' },

  // --- approved architects ---
  'GET /me/contribution-status': { access: 'approved' },
  'GET /me/drawings': { access: 'approved' },
  'GET /me/favorites': { access: 'approved' },
  'GET /me/purchases': { access: 'approved' },
  'GET /architects/top': { access: 'approved' },
  'GET /architects/:id': { access: 'approved' },
  'GET /architects/:id/drawings': { access: 'approved' },
  'GET /categories': { access: 'approved' },
  'GET /cities': { access: 'approved' },
  'POST /category-requests': { access: 'approved' },
  'GET /drawings/search': { access: 'approved' },
  'GET /drawings/:id': { access: 'approved' },
  'GET /drawings/:id/reviews': { access: 'approved' },
  'GET /drawings/:id/download': { access: 'approved' },
  'PUT /drawings/:id/review': { access: 'approved' },
  'PUT /drawings/:id/favorite': { access: 'approved' },
  'DELETE /drawings/:id/favorite': { access: 'approved' },
  'PUT /drawings/:id/interest': { access: 'approved' },
  'DELETE /drawings/:id/interest': { access: 'approved' },
  'GET /cart': { access: 'approved' },
  'POST /cart': { access: 'approved' },
  'DELETE /cart/:drawingId': { access: 'approved' },
  'POST /checkout': { access: 'approved' },
  'POST /checkout/verify': { access: 'approved' },
  'POST /checkout/stub-complete': { access: 'approved' },
  'GET /checkout/status': { access: 'approved' },
  'GET /wallet': { access: 'approved' },
  'GET /wallet/ledger': { access: 'approved' },
  'GET /wallet/withdrawals': { access: 'approved' },
  'POST /wallet/bank-account': { access: 'approved' },
  'POST /wallet/withdrawals': { access: 'approved' },

  // --- approved + drawing owner ---
  'POST /drawings': { access: 'approved' },
  'PATCH /drawings/:id': { access: 'approved', owner: true },
  'DELETE /drawings/:id': { access: 'approved', owner: true },
  'POST /drawings/:id/publish': { access: 'approved', owner: true },
  'POST /drawings/:drawingId/sheets/upload-url': {
    access: 'approved',
    owner: true,
  },
  'POST /drawings/:drawingId/sheets': { access: 'approved', owner: true },
  'PATCH /drawings/:drawingId/sheets/:sheetId': {
    access: 'approved',
    owner: true,
  },
  'DELETE /drawings/:drawingId/sheets/:sheetId': {
    access: 'approved',
    owner: true,
  },
  'GET /drawings/:id/buyers': { access: 'approved', owner: true },
  'GET /drawings/:id/viewers': { access: 'approved', owner: true },
  'GET /drawings/:id/interests': { access: 'approved', owner: true },
  'GET /drawings/:id/interested': { access: 'approved', owner: true },

  // --- admin ---
  'GET /admin/verifications': { access: 'admin' },
  'GET /admin/verifications/:id': { access: 'admin' },
  'POST /admin/verifications/:id/approve': { access: 'admin' },
  'POST /admin/verifications/:id/reject': { access: 'admin' },
  'GET /admin/category-requests': { access: 'admin' },
  'POST /admin/category-requests/:id/approve': { access: 'admin' },
  'POST /admin/category-requests/:id/reject': { access: 'admin' },
  'GET /admin/plagiarism-flags': { access: 'admin' },
  'POST /admin/plagiarism-flags/:id/approve': { access: 'admin' },
  'POST /admin/plagiarism-flags/:id/reject': { access: 'admin' },
  'GET /admin/purchases': { access: 'admin' },
  'GET /admin/purchases/:id': { access: 'admin' },
  'POST /admin/purchases/:id/refund': { access: 'admin' },
};
