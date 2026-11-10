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

## First APK — BUILT 2026-11-10 evening
- Repo created: https://github.com/PKAhmad/Topup-App (public, PKAhmad) — pushed
  via the workspace SSH key, same route as Karyab.
- Run #1 failed at Analyze: only 6 info lints, all in the local harness
  tool/verify_pure.dart (lib/ + test/ were clean) → harness excluded from
  analysis. Run #2: Analyze + Test PASSED, APK build failed on Gradle 8.7 <
  Flutter 3.47's minimum 8.14 → Gradle 8.14 wrapper, AGP 8.13.0, Kotlin
  2.2.20, launcher icons added. Run #3 (42860191610, commit 908d18f):
  SUCCESS — analyze, all flutter tests, debug APK build, artifact upload.
- Artifact: topup-app-debug-apk, zip sha256
  7c7ccf6ee86277e5a2a0c44f4a3d2b7fcb6f1b513dc41c50138a4deff4e1680b (verified
  byte-identical after download). APK verified with aapt: package
  app.topup.topup_app, versionName 0.1.0 / code 1, minSdk 24, targetSdk 34,
  INTERNET permission, all 198 audio placeholder clips bundled.
  Local copy: ~/workspace/topup-app/Topup-App-v0.1-debug.apk (~171 MB debug).
- Note: debug APK is large (all ABIs + debug). The app opens and runs the
  full flow on-device; live top-ups still need the Phase 0 keys + a running
  backend, and voice is silent until the script is recorded.

## v0.2 — Expense Tracker design + instant detection (2026-11-10 evening)
- CEO feedback on v0.1: (1) use the Expense Tracker's design; (2) number
  detection hung on "searching" — root cause: the app waited on the backend
  (unreachable from a real phone, emulator address) with NO timeout.
- Detection is now LOCAL-FIRST in the app: country from the dial code,
  operator from the number prefix (AF fully mapped: 70/71 AWCC, 79/72 Roshan,
  77/76 MTN, 78/73 Etisalat, 74 Salaam; PK/IR/TR broad families in national
  form). Live preview while typing; Continue is instant; backend confirm
  runs in background with a 5 s timeout and only refines. All API calls
  time-boxed (5–15 s). If the typed number's country differs from the tapped
  country, the flow follows the number.
- Design: Expense Tracker language ported to Flutter — cream gradient
  (#FCF9F2→#F6F0E2) + blue radial glows, white glass cards (22px radius,
  navy shadow), neon-blue gradient primary buttons (#3FC1FF→#0091FF),
  ink #182740 text, blue launcher icon. No live blur (scroll performance).
- Build lesson: android/app/build.gradle had versionCode/Name HARDCODED
  (0.1.0/1) — run #4 shipped new code with the old label. Now wired to
  pubspec via local.properties. Run #5 (42880599233, ff0cc67) verified by
  aapt: versionName 0.2.0 / code 2, artifact sha256 ef526e3f… matched.
  Local copy: ~/workspace/topup-app/Topup-App-v0.2-debug.apk.
- Pure checks 30/30 (verify_pure); CI analyze + flutter tests passed.

## v0.3 — modern design + local-first review (2026-11-10 night)
- CEO verdicts on v0.2: voice absent (placeholders — generation started,
  then CEO STOPPED it himself: he is training a NEW ElevenLabs voice and
  clips will be generated with that voice when ready); design 'really poor'
  vs modern top-up apps; amount step dead-ended on 'problem occurred'.
- Fixes shipped (commit f02f85a, run 42889494651 SUCCESS): hero home +
  quick country chips, searchable country list, 4-step progress bar,
  operator header card, Popular amount badge; review is local-first
  (instant render, server only adds total/enables Pay, plain-language
  offline notice + retry, 10 s create timeout).
- Verified by aapt: 0.3.0 / code 3; artifact sha256 2f052ae2… matched.
  Local copy: ~/workspace/topup-app/Topup-App-v0.3-debug.apk.

## v0.4 — REAL VOICE (delivered 2026-11-10 night)

- All 198 clips are now REAL speech (placeholders gone). Whole voice set = 1.16 MB total.
- Voice: CEO's new ElevenLabs Professional clone — exact account name "Kamran Ahmad" (34 min training, created 2026-11-10) — for Pashto AND Dari; English in library voice "Rachel". Model: Eleven v4 for every generation (never Multilingual), stability 55, similarity 75, style/clone-strength 0, auto-tag on; Pashto/Persian language overrides.
- Method: number words generated grouped and silence-sliced (verified: all clips 0.39–0.96 s, even pacing); sentence prompts generated ONE BY ONE (51 files) because the grouped v4 takes had in-sentence dramatic pauses that made slicing misalign sentences (caught by duration-vs-text-length checks — prompt_welcome sliced at 0.83 s vs real 7.19 s). Every final clip verified: present, non-silent (mean volume ≈ −18…−22 dB), duration consistent with its text.
- Clips edge-trimmed and compressed to mono 24 kHz / 32 kbps MP3; same file names as placeholders, zero code change. verify_pure 30/30.
- Build: commit fe96103, CI run 42910619074 success; artifact zip sha256 d304278950934fa979aa1e8dc276cf86f1aebb5b3f4de22dfeabbae479354103; aapt: versionName 0.4.0 / code 4, targetSdk 34, minSdk 24, 198 audio assets inside the APK. Local copy: Topup-App-v0.4-debug.apk. Fresh debug key — uninstall v0.3 first.
- Audio tooling kept in repo: audio-tools/slice_clips.py + key lists + grouped generation masters (gens/).
