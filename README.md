# Mobile Balance Topup App

Voice-first mobile top-up app for Afghan users + international.
Afghans get Pashto text + Pashto voice guidance (many users cannot read
text); everyone pays per top-up by card — **no wallet** (by CEO decision,
2026-11-10, which also keeps us out of EU e-money regulation).

- Aggregator: **Reloadly** (sandbox first; Ding/DT One possible later as 2nd supplier)
- Payments: **Stripe** (PaymentIntents + webhooks; the app never touches card data)
- Backend: NestJS + PostgreSQL + Redis (queue) — `backend/`
- App (Phase 2): Flutter, same stack as Karyab

Decisions log:
- 2026-11-10: target = Afghan + international; voice-first Pashto for Afghans;
  pay-per-topup only; aggregator = Reloadly; Phase 0+1 build ordered.

Status: Phase 0+1 backend core DONE — see `PHASE01-REPORT.md`.
Phase 2 Flutter app (voice-first flow) DONE — see `PHASE2-REPORT.md`.
Accounts the CEO must open: `docs/ACCOUNT-SETUP.md`.
