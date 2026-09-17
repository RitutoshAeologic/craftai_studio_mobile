# CraftAI Studio — Product Requirements Document (PRD)
**Platform:** Flutter Mobile (iOS 15+ / Android SDK 21–36)
**Companion Backend:** FastAPI + Supabase + Redis + Serverless GPU Workers
**Doc Owner:** Product / Engineering
**Status:** Draft for Sign-off

---

## 1. Product Vision

CraftAI Studio is an AI image & video creation studio combined with a curated, DRM-protected prompt marketplace. Users create for free; they pay only at the moment of real intent (exporting a finished asset), and creators earn passive royalties when their published prompts are remixed. This document defines *what* to build and *why*. See `architecture.md` for *how*, `phase.md` for *when*, and `rules.md` for the guardrails every contributor (human or AI) must follow.

## 2. Goals & Success Metrics

| Goal | Metric | Target (90 days post-launch) |
| :--- | :--- | :--- |
| Reduce onboarding friction | % of new users who generate ≥1 image in session 1 | ≥ 70% |
| Convert intent to revenue | Free-to-paid conversion (download unlock) | ≥ 8% of active generators |
| Creator flywheel adoption | % of published prompts remixed ≥1x within 14 days | ≥ 25% |
| Reliability | Generation success rate (excl. moderation blocks) | ≥ 99% |
| Perf | P95 time-to-first-preview | ≤ 4s |
| Retention | D7 retention | ≥ 20% |
| App quality | Crash-free sessions | ≥ 99.5% |

Every metric above needs an analytics event defined **before** Sprint 1 (see §8). AI-generated code that doesn't emit the corresponding event is treated as incomplete, not "done."

## 3. Target Users

- **Casual Creator ("Explorer")** — browses Explore feed, remixes existing prompts, rarely writes prompts from scratch.
- **Power Creator ("Studio User")** — builds characters with face-lock, uses batch generation, publishes prompts, cares about royalties.
- **Video Creator** — uses I2V/T2V, LivePortrait, camera controls; higher credit spend, lower volume.

Personas should be validated with 5–8 user interviews before Sprint 3 (marketplace); the original doc assumes marketplace demand without qualitative validation — flag this as a real product risk, not just an engineering task.

## 4. Core Business Rules (Product-Level)

1. **Pay-to-Download:** Free unlimited in-app creation and cloud storage. Exporting an unwatermarked 4K master to device costs a flat 2 credits ($0.20) on first unlock; re-downloads are free (idempotent).
2. **Creator Royalties:** Creators earn a configurable share of remix revenue, funded only from *purchased* credits (never free/promo credits) to prevent Sybil farming.
3. **Range-Bound Dynamic Pricing:** Compute cost scales with prompt complexity but is always clamped to a published min–max bracket per model tier — no surprise bills.
4. **Encrypted Prompt DRM:** Published prompts are server-side encrypted; clients only ever see an aesthetic summary, never the raw recipe.

Full technical enforcement of these rules is in `rules.md` §1; do not let engineering deviate from the wording above without a product sign-off, since each rule is also a legal/trust commitment to users.

## 5. Feature Scope

### 5.1 MVP (must ship for launch)
- Auth (Google/Apple/Email/Anonymous) via Supabase
- AI Image Creation Studio: prompt input, Magic Expander, batch (1–4), seed lock, aspect ratio, 2K/4K toggle
- Cloud Library with pagination, folders
- Pay-to-download paywall (2-credit flow, idempotent re-download)
- Wallet + credit packs + Stripe/PayPal integration
- Basic content moderation (input + output)
- Core DRM: FLAG_SECURE (Android), screen-capture detection (iOS)

### 5.2 Fast-follow (Sprint 3–4 equivalent)
- Explore/Marketplace feed with pgvector "more like this"
- Publish-to-Explore + AES-256 prompt DRM + remix flow
- Creator royalty ledger + payout requests
- Consistent Characters / Face Lock (InstantID)
- AI Video Suite (I2V/T2V, LivePortrait)
- Creative Skills Toolbox (bg remover, upscaler, face swap)

### 5.3 Explicitly out of scope for v1
- Web platform parity (tracked separately; not a Flutter concern)
- Multi-language UI (plan for it structurally — see `rules.md` §9 — but don't localize all copy at v1)
- In-app chat / social messaging between creators

## 6. Key User Flows (product-level, technical detail in `architecture.md`)

- **Flow A — Free Creation:** prompt → optional Magic Expander → cost preview shown *before* generation (transparency requirement, not in original doc) → generate → auto-save to Library.
- **Flow B — Paid Download:** Library → "Download 4K Master" → cost confirmation sheet → wallet deduction → signed URL → save to device with a visible progress indicator and resumable download.
- **Flow C — Publish:** select generation → toggle "Publish to Explore" → mandatory NSFW/IP self-check prompt shown to user before publish (new — reduces moderation load) → confirmation.
- **Flow D — Remix:** browse Explore → tap Remix → customize exposed chips only → generate → creator royalty posted to ledger with a visible receipt in-app (trust requirement).

## 7. Non-Functional Requirements (frequently missing from AI-generated app plans — do not skip)

- **Performance:** cold start ≤ 2.5s on a mid-tier Android device; scroll jank-free (60fps) on Explore masonry grid.
- **Offline behavior:** Library must be viewable offline (cached thumbnails); generation/publish gracefully queue-and-retry or clearly disable with messaging — never silently fail.
- **Accessibility:** WCAG-equivalent contrast, dynamic text scaling support, semantic labels on all interactive controls, screen-reader-usable checkout flow (App Store review risk if skipped).
- **Localization-readiness:** all user-facing strings externalized to ARB files from day one, even if only English ships.
- **Privacy & compliance:** GDPR/CCPA data export & delete flows, App Tracking Transparency (iOS) if any tracking SDK is used, age rating appropriate to AI image generation (16+/17+ typical), clear in-app disclosure that content is AI-generated.
- **Payments compliance:** Apple/Google in-app purchase rules — **credits sold for AI generation must go through native IAP on iOS/Android, not Stripe directly**, unless the "reader app"/external-purchase exception genuinely applies. This is a launch-blocking legal/compliance item the original doc does not address and must be resolved before Sprint 1, not discovered at App Store review.
- **Content safety:** documented moderation policy, user reporting/flagging mechanism, and a support/appeal path — required by both app stores for UGC platforms.

## 8. Analytics & Instrumentation Requirements

Define and instrument before feature work begins:
- `generation_started`, `generation_completed`, `generation_failed` (with reason)
- `download_unlock_purchased`, `download_redownload_free`
- `prompt_published`, `prompt_remixed`, `royalty_credited`
- `paywall_shown`, `paywall_abandoned` (funnel visibility into the 85% drop-off problem the product claims to solve — must be measurable, not assumed solved)

## 9. Open Decisions Requiring Sign-off

1. Royalty model: confirm Tiered Gamified Split (Model 1) as default.
2. IAP compliance path for credit purchases (native IAP vs. justified external payment).
3. Minimum supported OS versions and device tiers (affects GPU-worker cold-start UX expectations).
4. Content moderation vendor/approach (self-hosted classifier vs. third-party, e.g., AWS Rekognition/Azure Content Safety).
5. Data residency requirements if targeting EU/India users specifically (Supabase region selection).
