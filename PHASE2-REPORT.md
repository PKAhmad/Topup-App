# Phase 2 Report — Flutter App with Voice Flow (2026-11-10)

## What was ordered
Phase 2: the Flutter app with the voice-first flow for Afghan users
(Pashto text + Pashto voice, because many users cannot read text),
pay-per-topup, Afghan + international. Backend addition needed by the app
(operator auto-detect endpoint) was included.

## The voice design (as built)
- **Pre-recorded clips, not TTS.** Pashto TTS is unreliable (Karyab lesson).
  Fixed sentences are single clips; dynamic content is *composed*:
  `SpeechComposer` builds phone read-backs digit by digit and speaks any
  amount 0–999,999 from ~40 small clips per language (digits, teens, tens
  incl. the Pashto suffix forms — 75 = پنځه اویا — hundred/thousand, "and",
  "point", currency words), with correct word order per language
  (ps unit-first, fa tens+و+unit, en tens+unit).
- **The safety step:** after typing a number, the app reads it back aloud
  digit by digit; the user confirms with the big GREEN button or rejects
  with the RED one. Instructions are spoken in colours, not words alone.
- Every screen auto-plays its prompt and carries a big speaker replay button.
- Full recording script: `docs/VOICE-SCRIPT.md` — 17 prompts + number pieces,
  in Pashto, Dari and English, with exact file names. The bundle ships with
  198 silent placeholder clips (66 keys × 3 languages); recording over a
  file is the only step needed — no code change.

## App (~/workspace/topup-app/app)
- Screens: Language (first run) → Home (voice toggle + language, persisted)
  → Country (flag grid, Afghanistan first) → Number (big input, any format
  — 079…, +93…, 0049… — normalized to E.164; operator auto-detect via the
  new backend endpoint) → read-back confirm → Amount (big chips: operator's
  fixed denominations or range presets + custom amount; every tap speaks
  the amount) → Review (creates the top-up via the Phase 1 backend with an
  idempotency key; speaks amount + number + total price) → Stripe payment
  sheet → Processing (polls until DELIVERED/REFUNDED) → Result (voice
  success, or failure + spoken refund promise) → History (status list).
- Languages: Pashto (default, RTL), Dari (RTL), English — 54 UI strings,
  parity-tested in all three.
- Stripe: flutter_stripe wired; Android uses FlutterFragmentActivity +
  MaterialComponents theme as the plugin requires. Without the Phase 0
  publishable key the pay button says so honestly instead of faking success.
- Provisional package id `app.topup.topup_app` — final name/keystore at
  name-day, same as Karyab. GitHub Actions workflow (analyze + test + debug
  APK artifact) ready at `.github/workflows/build-apk.yml`.

## Backend change (Phase 1 extension)
- `GET /topups/detect-operator?phone=` added (route declared before `:id`),
  returning the app-facing operator shape. Backend suite now **30/30 tests**
  (new detect test), tsc clean.

## Verification (honest scope)
- No Flutter SDK exists in this VM, so the APK itself was NOT built here —
  the Actions workflow is the build route (same as Karyab).
- Pure-Dart core verified with a standalone Dart SDK: `dart analyze` on
  speech composer / phone input / strings = **no issues**; assertion harness
  `tool/verify_pure.dart` = **21/21 checks pass** (read-back sequence,
  Pashto/Dari/English number composition incl. 1250 and 100000, money
  speech, E.164 building, display grouping, 162-cell string parity).
  The same assertions exist as flutter tests in `app/test/` for CI.
- All 18 Dart files parse cleanly (dart format). Flutter-dependent files
  are parse-verified only until the first Actions run.
- Placeholder-audio bug caught and fixed during the build: /tmp filled up
  mid-generation leaving 0-byte clips; regenerated to disk and ffprobe-
  verified (0.35 s, 0 empty files).

## What is needed next (in order)
1. **First APK:** push `~/workspace/topup-app` to a GitHub repo → Actions
   builds the debug APK (needs the CEO's GitHub, like Karyab).
2. **Voice recordings:** a Pashto speaker records `docs/VOICE-SCRIPT.md`
   (one session, ~66 short clips). Until then the app is silent by design.
3. **Phase 0 keys** (Reloadly sandbox + Stripe test) → first end-to-end
   sandbox top-up with a real Afghan number, then the Phase 4 failure/refund
   drills.
4. Phase 2.5: Firebase login replaces the dev `x-user-id` auth; Prisma
   persistence + deployment (Phase 1.5) gives the app a public backend URL.
