# CraftAI Studio — Phased Development Plan (AI-Tool-Assisted)
**Scope:** Flutter mobile app + FastAPI/Supabase backend integration
**Format:** Each phase lists deliverables, exit criteria, and how to use AI coding tools responsibly (not just "faster")

---

## 0. How AI Tools Fit Into This Plan

The original 8-week/4-sprint plan assumes human-only velocity. With AI-assisted development (Claude Code / Cursor / GitHub Copilot for implementation, an LLM for test-case generation, Claude/Figma AI for UI scaffolding), timelines compress — but three things must be added that pure "generate the app" workflows tend to skip:

1. **A spec-first workflow.** AI tools produce plausible-looking code fast; without `prod.md`, `architecture.md`, and `rules.md` as grounding context fed into every session, they will happily invent inconsistent state management, naming, or pricing logic across features. Treat these docs as the system prompt for every AI coding session.
2. **A review gate that assumes AI code is a first draft.** Every AI-generated PR still needs human review against `rules.md` — especially around money (wallet/credits), security (DRM, secrets), and concurrency (double-spend).
3. **Continuous test generation, not just feature generation.** Ask the AI tool to generate widget/unit tests *alongside* each feature, not after, or coverage silently rots.

Recommended toolchain:
- **Claude Code** — scaffolding Flutter feature modules, writing repository/service layers against the FastAPI contract, generating Dart tests.
- **Cursor / Copilot** — inline completion during manual refinement.
- **Figma + AI plugin or Claude** — screen mockups translated into Flutter widget trees (still hand-verified against `flutter_screenutil` rules).
- **LLM-based code review bot in CI** — flags obvious issues (hardcoded secrets, missing error handling) before human review.

---

## Phase 0 — Foundations (Week 0, pre-Sprint 1)

*Not in the original plan — skipping this is the #1 cause of AI-assisted projects becoming unmaintainable.*

**Deliverables**
- Flutter project scaffold with clean-architecture folder structure (`architecture.md` §2) and build flavors (dev/staging/prod).
- CI pipeline stub (lint + format + test) running on every PR from day one.
- Design tokens & theme (colors, typography, spacing) implemented as a `ThemeData` extension — not scattered magic values.
- `.env`/secret management strategy in place (e.g., `--dart-define`, Supabase config per flavor) so no AI tool ever hardcodes a key into source.
- Analytics SDK wired with the event schema from `prod.md` §8 (even if events are stubs).
- Crash reporting (Sentry/Crashlytics) wired before any feature code ships.
- **Lightweight secrets setup on day one** (GitHub Actions Secrets or a git-ignored `.env.local`) — no AI tool should ever hardcode a key into source. Full secrets-vault/rotation process can wait until the backend developer joins and real money is flowing.
- **Agree on the API contract format with the backend developer before either of you writes integration code** — even a rough OpenAPI draft beats building against assumed JSON shapes that later turn out wrong on both sides (`architecture.md` §11.7).

**Exit criteria:** empty app boots on all 3 flavors, CI green, crash reporting confirmed with a test crash, one dummy analytics event visible in the dashboard.

---

## Phase 1 (Weeks 1–2) — Auth, Wallet & Download Paywall

**Deliverables**
- Supabase Auth integration (Google/Apple/Email/Anonymous) + secure token storage (`flutter_secure_storage`, never SharedPreferences for tokens).
- Cloud Library screen (paginated, offline-cached thumbnails).
- Wallet UI + credit balance display, wired to backend ACID-locked ledger.
- 2-credit idempotent download-unlock flow, including the **IAP compliance decision from `prod.md` §9** — this must be resolved here, not deferred, since it changes the wallet purchase flow's shape.
- Native DRM: `FLAG_SECURE` (Android), screen-capture notification handling (iOS).
- Signed URL download manager with resumable/chunked download and 900s TTL handling.

**Testing requirements:** unit tests on wallet deduction logic (including race-condition simulation), widget tests on paywall sheet, integration test for full download flow against a staging backend.

**Exit criteria:** a user can sign up, generate (mocked backend if GPU pipeline isn't ready), pay to download, and re-download for free — with crash-free telemetry confirming it in staging.

---

## Phase 2 (Weeks 3–4) — AI Generation Engine & Pricing UI

**Deliverables**
- Studio screen: prompt input, Magic Expander call, batch/seed/aspect/resolution controls (all built with `Wrap`/`Flexible` per `rules.md` §5 zero-overflow rules).
- **Pre-generation cost preview** (new vs. original doc — required for the trust/transparency NFR in `prod.md`).
- Real-time job status via Supabase Realtime subscription with a documented reconnect/backoff strategy (the original doc claims <50ms updates but never specifies fallback if the socket drops — add polling fallback here).
- Graceful UI states for: cold-start delay, moderation rejection, generation failure with auto-refund confirmation.

**Testing requirements:** golden tests for Studio Bar across 3 screen sizes (small phone, large phone, tablet), integration test for the full generate→realtime-update→library-save loop, chaos test simulating a dropped realtime connection.

**Exit criteria:** generation success rate ≥ 99% in staging load test; UI never leaves the user in an ambiguous "is it still working?" state.

---

## Phase 3 (Weeks 5–6) — Marketplace, DRM & Royalties

**Deliverables**
- Explore masonry grid with lazy-loading and pgvector-backed "more like this."
- Publish-to-Explore flow, including the self-check moderation prompt from `prod.md` §6.
- Remix drawer exposing only variable chips (server never sends raw prompt to client — verify via network-traffic test, not just code review, since this is a hard security requirement).
- Royalty receipt UI in Wallet history.
- Client-side copy-blocking (best-effort; document its limitations per `rules.md` §7 rather than overclaiming security).

**Testing requirements:** security test explicitly asserting the decrypted prompt never appears in any client-bound API response (automated, run in CI against a contract test, not just manual QA).

**Exit criteria:** a creator can publish, a second test account can remix, and a royalty appears correctly only when funded by a purchased-credit transaction (verify the Sybil-gating rule with an automated test using free/promo credits that must NOT generate a royalty).

---

## Phase 4 (Weeks 7–8) — Video Suite, Face Tools & Hardening

**Deliverables**
- I2V/T2V UI, LivePortrait presets, camera controls.
- Face Lock onboarding (3-angle capture) with clear on-device guidance and retake flow.
- Face swap / re-aging via InstantID/ReActor (confirm Apache-2.0 licensing is still accurate at implementation time — licenses change).
- Full regression pass, performance profiling (startup time, memory on generation-heavy sessions), accessibility audit.
- Store listing assets, privacy nutrition labels (App Store) / Data safety form (Play Store), age rating finalization.

**Exit criteria (production launch gate — expand beyond the original doc's "CI/CD pipelines & launch"):**
- [ ] Crash-free sessions ≥ 99.5% across a 2-week internal beta (TestFlight/Play Internal Testing)
- [ ] All P0/P1 bugs from beta resolved
- [ ] Accessibility audit passed (screen reader can complete signup → generate → download)
- [ ] Security review sign-off (DRM boundary test, secrets scan, dependency vulnerability scan)
- [ ] Load test confirms Redis rate-limiting and GPU worker autoscale caps hold under simulated viral traffic
- [ ] Legal sign-off on IAP compliance, content moderation policy, and Terms/Privacy Policy in-app links
- [ ] Rollback plan documented for the first production release

**Additional Senior Dev / DevOps sign-off (right-sized for solo Flutter dev + a separate backend developer — not a full team checklist):**
- [ ] You've confirmed with the backend developer, directly, that: Supabase backups are automated and a restore has actually been tested at least once, secrets are not committed anywhere in the backend repo's git history, and billing alerts are live on GPU/Supabase/Gemini spend
- [ ] The OpenAPI contract (`architecture.md` §11.7) reflects the exact backend version being deployed to production — not a stale spec from a few weeks ago
- [ ] Your Flutter build reads all backend URLs/keys from `--dart-define` per flavor — zero hardcoded prod values anywhere in your codebase, verified with a quick grep before submission
- [ ] You've personally run a secrets scan (`gitleaks`) on the Flutter repo before the first production build
- [ ] Privacy Manifest (iOS) and Data Safety form (Android) reflect the actual current SDK list in your `pubspec.yaml` — check this yourself even if backend/legal handles the policy text
- [ ] You know, in one sentence each, what you'd check first if: generation stops working for everyone, downloads start failing, or a payment doesn't credit — your personal runbook from `architecture.md` §11.5

---

## Phase 5 (Post-launch, ongoing) — Monitor, Iterate, Harden

Not present in the original roadmap at all — a production app doesn't end at "launch."

- Weekly review of crash reports, funnel drop-off (paywall_shown → purchased), and moderation false-positive/negative rates.
- Feature-flag rollout process for new model tiers or pricing changes (no forced app update needed for pricing bracket adjustments, per `rules.md` §3).
- Quarterly dependency and license audit (Flutter packages, AI model licenses).
- Ongoing A/B testing infrastructure for royalty model tuning (the source doc treats Model 1 as final; plan to actually test it against Model 2/3 with real cohorts).
