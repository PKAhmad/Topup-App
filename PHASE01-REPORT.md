# Phase 0+1 Report — Mobile Balance Topup App (2026-11-10)

## What was ordered
Reloadly as aggregator; build Phase 0 (accounts/setup) + Phase 1 (backend core).

## Phase 0 — setup pack DONE (accounts themselves are CEO-only)
- Project scaffold at `~/workspace/topup-app/` (backend NestJS + TS).
- `backend/.env.example` — every key the backend needs, with where to find it.
- `docs/ACCOUNT-SETUP.md` — step-by-step: Reloadly signup + Sandbox toggle +
  Developers → API settings for TEST client_id/secret; Stripe test keys +
  webhook; Firebase (Phase 2). ~30 min of CEO time, the only blocker to
  live sandbox tests.
- `backend/docker-compose.yml` — PostgreSQL 16 + Redis 7 for local/prod.

## Phase 1 — backend core DONE, 29/29 tests pass, build + boot verified
Verified live before coding: Reloadly uses OAuth2 client-credentials
(POST auth.reloadly.com/oauth/token, audience = base URL), sandbox base
`topups-sandbox.reloadly.com`, header `Accept: application/com.reloadly.topups-v1+json`,
`customIdentifier` must be unique per top-up (we send our transaction UUID).

Components (all under `backend/src/`):
- `domain/transaction-state.ts` — state machine: CREATED → AWAITING_PAYMENT →
  PAID → SENDING → DELIVERED, failure path → FAILED → REFUND_PENDING →
  REFUNDED / REFUND_FAILED. Illegal transitions throw; an unpaid top-up can
  never be sent.
- `domain/pricing.ts` — integer minor units only. Total = Reloadly cost +
  fee; fee = max(€0.49, 8% + €0.35) with the shipped defaults (configurable).
- `domain/phone.ts` — E.164 parsing, country by dial code, Afghan operator
  prefix hints (UI help only; Reloadly auto-detect is the truth).
- `ledger/ledger.service.ts` — double-entry ledger; journals must balance or
  they throw. Payment, delivery (cost + fee split) and refund journals.
- `reloadly/reloadly.client.ts` — token caching, balance, countries,
  operators by country, auto-detect, FX rate, send top-up (sync + async),
  status polling; typed `ReloadlyError` on API failures.
- `payments/` — Stripe provider behind an interface: create PaymentIntent
  (idempotent), refunds, signature-verified webhooks.
- `topups/topups.service.ts` — orchestration: idempotent create (safe
  retries), operator auto-detect + amount validation (FIXED lists / RANGE
  min-max), FX cost quote, Stripe intent, webhook → send to Reloadly →
  delivered or **automatic refund**; refund failure parks the transaction in
  REFUND_FAILED for manual review — never silent. `reconcile()` settles
  PROCESSING transactions. Webhook replays do not double-post the ledger.
- `catalog/` — syncs operators from Reloadly (Afghanistan first, then core
  diaspora countries), plus a balance endpoint for float monitoring.
- `prisma/schema.prisma` — production PostgreSQL model (users, transactions,
  ledger entries, catalog). Phase 1 services run on repository interfaces
  with in-memory implementations (same pattern the tests use); Prisma is the
  production drop-in.
- `auth/` — dev guard now; Firebase ID-token verification slots into the
  same guard in Phase 2 (fails closed when enabled before wiring).

Verification:
- `npx tsc --noEmit` clean; `npm run build` OK.
- Jest: 6 suites, **29/29 tests pass** (state machine, pricing, ledger,
  phone, Reloadly client with mocked HTTP, full orchestration incl. refund
  and reconcile paths). One real bug caught by tests: Afghan prefix hints
  used trunk-0 prefixes (079) against national numbers (79) — fixed.
- Boot smoke test: server starts, unauthenticated request → 401,
  dev-auth request → 200.

## Honest limitations / next verifications
- No real Reloadly/Stripe call has been made yet — that needs the CEO's
  sandbox keys (Phase 0). First sandbox session must pin two field mappings
  against the real API: the FX-rate response field for our cost, and the
  operator list shape for Afghanistan (AWCC, Roshan, MTN, Etisalat, Salaam
  availability + fixed denominations come from the API at runtime).
- Persistence is in-memory until Prisma is wired (Phase 1.5, with the
  deployment). Nothing money-related goes live before that.
- Redis/BullMQ queue: reconcile currently runs by call; the queue wiring
  lands with deployment (docker-compose already carries Redis).

## Next phases
- Phase 1.5: Prisma persistence + deployment + webhook public URL.
- Phase 2: Flutter app — 5-step voice-first flow (Pashto voice prompts
  pre-recorded + bundled, number read-back confirmation), Stripe payment
  sheet, history. Dari as second Afghan language.
- Phase 4 (test pass): sandbox top-ups to real AF numbers, forced-failure
  and refund drills.
