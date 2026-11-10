# Phase 0 — Accounts the CEO must open (only he can: they are in his name / his business)

The backend code is finished and tested with fake keys. These 3 accounts are
the only thing between us and real sandbox top-ups. Total time ~30 minutes.
**Never send passwords or secret keys in chat** — keys go into the backend
`.env` file via the secure vault when we deploy.

## 1. Reloadly (the top-ups themselves) — ~10 min
1. Sign up at reloadly.com (business email).
2. In the dashboard, turn ON the **Sandbox** toggle (top-right) — this switches
   the whole portal to test mode. Sandbox comes with a free test balance;
   nothing here is real money.
3. Go to **Developers → API settings** and copy the TEST `client_id` and
   `client_secret` (different from the live ones — mixing them up is the #1
   cause of auth errors).
4. Later, for launch: switch the toggle OFF, complete their business
   verification, and load the **float** (prepaid balance — start with a few
   hundred €). Top-ups are deducted from this float instantly, while Stripe
   pays out days later, so the float must never hit zero. The backend has a
   balance endpoint (`GET /catalog/balance`) so we can watch it.

## 2. Stripe (card payments) — ~15 min
1. Sign up at stripe.com. Test mode works immediately, no verification needed
   to start testing.
2. **Developers → API keys**: copy the TEST secret key (`sk_test_...`).
3. We add the webhook endpoint when the backend has a public URL
   (Developers → Webhooks → endpoint `/webhooks/stripe`, event
   `payment_intent.succeeded` + `payment_intent.payment_failed`) and copy the
   webhook signing secret (`whsec_...`).
4. For launch: complete Stripe's business verification (identity + business
   details) so live payments and payouts are enabled.

## 3. Firebase (login / OTP for the app) — ~5 min, Phase 2
1. console.firebase.google.com → create a project (any name, e.g. "Topup").
2. We connect it when the Flutter app starts (Phase 2) — not needed for
   Phase 1 backend testing.

## Where the keys go
Backend `.env` (template: `backend/.env.example`):
`RELOADLY_CLIENT_ID`, `RELOADLY_CLIENT_SECRET`, `RELOADLY_SANDBOX=true`,
`STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`.
