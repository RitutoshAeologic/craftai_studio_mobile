# CraftAI Studio — Technical Architecture
**Scope:** Flutter mobile client architecture in depth; backend architecture summarized (see original blueprint for GPU/model specifics, retained here where still relevant).

---

## 1. System Overview

```
[ Flutter Mobile App ]  ── HTTPS/WSS ──▶ [ FastAPI Gateway (Python 3.11) ]
                                                │
                              ┌─────────────────┴─────────────────┐
                              ▼                                   ▼
                  [ Supabase Platform ]                [ Redis Queue → GPU Workers ]
                  • PostgreSQL (ACID, RLS)              • RunPod/Modal T4 workers
                  • Auth (JWT, SSO)                      • Flux/SDXL/LivePortrait
                  • Realtime (WebSocket CDC)             • Pollinations fallback
                  • Storage (previews CDN / masters)     • Circuit breaker + DLQ
                  • pgvector (semantic search)
```

Backend responsibilities are unchanged from the original blueprint (§9–14 there); this document focuses on the Flutter client architecture, which the original doc under-specifies for a production build.

---

## 2. Flutter App Architecture (Clean Architecture, 3 Layers)

```
lib/
├── core/                     # cross-cutting: theming, routing, error types, network client, env config
│   ├── network/               # Dio client, interceptors, retry/backoff, failure mapping
│   ├── errors/                 # Failure types, exception→failure mapping
│   ├── router/                 # GetX route table, middleware guards
│   ├── theme/                  # ThemeData, design tokens, ScreenUtil bootstrap
│   ├── constants/               # app_strings.dart, app_colors.dart, text_styles.dart, dimens.dart, enums/
│   └── di/                     # dependency injection (GetX Bindings)
├── features/
│   ├── auth/
│   │   ├── data/                # DTOs, Supabase auth repository impl
│   │   ├── domain/               # entities, repository interfaces, use cases
│   │   └── presentation/         # controllers (GetX), screens, feature-specific widgets
│   ├── studio/                  # generation studio (prompt, chips, batch/seed/res controls)
│   ├── library/                 # cloud library, download/unlock flow
│   ├── wallet/                  # credits, purchases, royalty ledger view
│   ├── explore/                 # marketplace feed, remix
│   └── video/                   # I2V/T2V, LivePortrait
└── shared/
    ├── widgets/                  # reusable, feature-agnostic widgets (see §2.1)
    ├── extensions/                # context/string/num extensions
    └── utils/                     # formatters, validators (shared across features)
```

### 2.1 Constants & No-Magic-Values Rule

- **`app_strings.dart`** — every user-facing string is a named constant (or ARB entry once localization is wired, per `rules.md` §11). No string literals typed directly inside a widget's `Text()` call.
- **`app_colors.dart`** — every color used as a named constant matching the design tokens (`#0B0F19` → `AppColors.background`, etc.). No raw hex codes inline in widget code.
- **`text_styles.dart`** — every `TextStyle` defined once (heading1, heading2, body, caption, button) and reused via `Theme.of(context).textTheme` or a dedicated `AppTextStyles` class. No ad-hoc `TextStyle(fontSize: 16, ...)` scattered across screens.
- **`dimens.dart`** — common spacing/radius values as named constants (`AppDimens.spacingMd = 12.w`) layered on top of ScreenUtil, so spacing stays consistent without every developer picking arbitrary numbers.
- **Enums, not raw strings/ints, for anything with a fixed set of states** — e.g., `enum GenerationStatus { queued, processing, completed, failed }`, `enum ModelTier { basic, standard, pro, ultra }`, `enum CreditSource { purchased, promo, referral }` (the last one is directly tied to the royalty anti-Sybil rule in `rules.md` §1 — using a raw string like `"purchased"` anywhere in that logic is a bug waiting to happen; an enum makes it a compile-time error to typo it).
- CI lint rule: flag any `Color(0x...)`, raw hex string, or inline `TextStyle(` found inside `features/**/presentation/` — these belong in `core/constants/` or `core/theme/` only.

### 2.2 Reusable Widget Library (`shared/widgets/`)

Before writing a new widget inside a feature, check `shared/widgets/` first — and if a UI pattern appears in 2+ features, it belongs there, not duplicated. Minimum set to build early (Phase 0/1, per `phase.md`):

- `AppButton` (primary/secondary/destructive variants, built-in loading state, built-in double-tap debounce — directly enforces the double-tap protection rule in `rules.md` §6)
- `AppTextField` (built-in validation error display, consistent styling)
- `AppLoadingIndicator`, `AppErrorView` (with retry callback), `AppEmptyState` (with configurable icon/message/action) — these three alone eliminate most of the "blank screen on error" UX gaps flagged in `rules.md` §6
- `CreditCostChip` (used in Studio, paywall sheet, and remix drawer — same widget, three places, must not be reimplemented three times)
- `AppNetworkImage` (wraps `cached_network_image` with a standard placeholder/error builder, so every image in the app fails gracefully the same way)

Rule of thumb for AI-assisted development: when asking an AI tool to build a new screen, explicitly instruct it to reuse these shared widgets rather than generating new one-off equivalents — this is the single biggest source of UI inconsistency when different AI sessions scaffold different screens independently.

### 2.3 Auth Architecture — Direct Supabase (Firebase-style), Backend Only for Business Logic

*Confirming this explicitly now so you and the backend developer build against the same assumption — this is a common split but easy to get wrong if undocumented.*

- **Auth flow is 100% direct between Flutter and Supabase**, using the `supabase_flutter` SDK — exactly the pattern you'd use with `firebase_auth`. Sign up, sign in (Google/Apple/Email), anonymous sessions, session refresh, and `authStateChanges` listening all happen client-side via the SDK. **The FastAPI backend is never called for login/signup/token-refresh** — it has no auth endpoints of its own.
- Once Supabase returns a session, the Flutter app holds the `access_token` (JWT) via the SDK's session management (backed by `flutter_secure_storage` under the hood) — no separate custom token handling needed.
- **Every call to the FastAPI backend** (generation, pricing preview, wallet, library, marketplace, publish/remix) attaches that same Supabase JWT as a Bearer token via the Dio auth interceptor (§3). FastAPI verifies it against Supabase's JWT secret/JWKS — it does not issue its own separate session, it trusts Supabase's.
- **What to confirm with the backend developer once their doc arrives:** exactly how FastAPI validates the Supabase JWT (shared JWT secret vs. fetching Supabase's public JWKS), what claims it expects (`sub` for user id, any custom claims for role/tier), and what a 401 from FastAPI means for you (usually: Supabase session expired locally — trigger `supabase.auth.refreshSession()` via the SDK, not a custom refresh-token endpoint).
- Practical implication for your Dio interceptor (§3): on a 401 from the FastAPI backend, first try `supabase_flutter`'s built-in session refresh (it usually already auto-refreshes in the background) before treating it as a real "session expired, go to login" case — don't build a custom refresh flow that duplicates what the SDK already does.

### 2.4 State Management, Navigation & Dependency Injection

**State management: GetX (chosen).** No `setState` anywhere in feature code except for truly local, ephemeral UI state that never leaves a single widget (e.g., a toggle animation) — anything tied to business logic, API data, or shared across widgets goes through a GetX controller. Do not let AI-generated PRs fall back to `setState` "for simplicity"; this is the most common way GetX projects silently degenerate into unmaintainable mixed-pattern code.

**GetX-specific rules (to prevent lag & memory leaks):**
- Use `Get.lazyPut()` for controllers by default, not `Get.put()` — controllers should only be instantiated when their screen is actually pushed, not eagerly at app start.
- Every controller that opens a `StreamSubscription` (e.g., Supabase Realtime job-status listener) **must** cancel it in `onClose()`. This is the single most common GetX memory leak — an AI-generated controller will happily open a subscription and never close it unless explicitly told to.
- Use `GetBuilder` (not `Obx`/`GetX` widget) for large, infrequently-changing sections (e.g., Explore masonry grid) to avoid rebuilding the entire subtree on every reactive variable change — this is the primary cause of UI jank in GetX apps when `.obs` variables are overused on big widget trees.
- Scope controllers with `Get.delete<T>()` or `Bindings` per route, so navigating away from a screen actually frees its controller — never rely on a global singleton controller for screen-specific state.
- Avoid nesting `Obx()` widgets more than 2 levels deep; flatten reactive state into a single controller-level computed getter instead, or rebuild scope becomes unpredictable and hard to profile for jank.
- No business logic inside `.obs` variable declarations or getters with side effects — keep controllers testable by keeping side effects inside explicit methods, not reactive getters.

**Navigation:** `GetX` named routes (`GetPage` + `Get.toNamed`) with auth/paywall middleware (`GetMiddleware`) for route guards, defined declaratively in one route table — not scattered `Get.to()`/`Navigator.push` calls sprinkled through widget code.

**Dependency injection:** all repositories/services injected, never instantiated inline in widgets — required for the testing strategy in §6 to work at all.

---

## 3. Networking Layer

- Single `Dio` instance (via a `DioClient` singleton, GetX-injected) with interceptors for: JWT attach/refresh, request/response logging (stripped in release builds), automatic retry with exponential backoff on 5xx/timeout, and a global 401 handler that triggers re-auth rather than crashing.
- All API responses parsed into typed models (`freezed`/`json_serializable`) — never raw `Map<String, dynamic>` passed up into UI layers.
- Explicit `Failure` types (network, server, validation, insufficient-credits, moderation-blocked) mapped from exceptions at the repository boundary, so the UI layer never has to interpret raw HTTP status codes.

### 3.1 Dio Error Handling — Concrete Mapping (do not skip this table)

Every repository method wraps its Dio call and maps `DioException` to a typed `Failure` before it ever reaches a controller. AI-generated repository code frequently forgets this and lets a raw `DioException` propagate — treat that as a review-blocking defect.

| `DioException.type` / status | Mapped `Failure` | UI Behavior |
| :--- | :--- | :--- |
| `connectionTimeout`, `receiveTimeout` | `NetworkFailure.timeout` | Show `AppErrorView` with "Check your connection" + Retry |
| `connectionError` (no internet) | `NetworkFailure.noConnection` | Offline banner (see §5), disable action, no destructive retry loop |
| `400` Bad Request | `ValidationFailure(fieldErrors)` | Inline field errors, preserve entered form data (per `rules.md` §6) |
| `401` Unauthorized | `AuthFailure.sessionExpired` | Silent token refresh attempt once; if that fails, route to login — never show a raw 401 to the user |
| `402` / custom `insufficient_credits` code | `WalletFailure.insufficientCredits` | Route directly to top-up sheet, not a generic error |
| `403` Forbidden | `AuthFailure.forbidden` | Generic "not allowed" state — do not leak *why* (avoid revealing moderation/ban reasons that aid abuse) |
| `409` Conflict (e.g., double-spend rejected, idempotency clash) | `WalletFailure.conflict` | Silently retry the read (e.g., refetch balance/status) rather than showing an error — this is often a race the server correctly rejected |
| `422` (moderation-blocked generation) | `ModerationFailure(reason)` | Clear, non-judgmental message + link to content policy |
| `429` Too Many Requests | `RateLimitFailure(retryAfter)` | Disable action, show countdown using `retryAfter` if provided |
| `5xx` | `ServerFailure` | `AppErrorView` with Retry; auto-retried via interceptor backoff before ever reaching this state |
| `DioException.cancel` | *(swallowed, not shown)* | User navigated away — not an error, don't surface it |

- Every one of these paths needs a widget test asserting the correct `AppErrorView`/UI state renders for the corresponding mocked Dio response — not just a unit test on the mapping function in isolation.
- Never display `dioException.message` or a raw stack trace to the end user — always the mapped, human-readable message from the `Failure`.

## 4. Realtime & State Sync

- Supabase Realtime channel subscription per active generation job; UI reflects `queued → processing → complete/failed` states.
- **Explicit fallback required (missing from the original doc):** if the WebSocket disconnects, fall back to short-interval polling (e.g., every 3s, capped at 5 attempts) rather than leaving the UI stuck on "processing" indefinitely.
- Library list uses optimistic UI updates on publish/unlock actions, reconciled against server state on next fetch.

## 5. Offline & Caching Strategy

- Local persistence via `Drift` (SQLite) or `Hive` for: cached library metadata + thumbnail URLs, wallet balance (last-known, clearly marked "may be stale" if offline), and draft prompts.
- Network-aware UI: explicit offline banner; generation/publish actions disabled (not silently queued, to avoid confusing double-charge scenarios) when offline.
- Image caching via `cached_network_image` with disk cache size limits to bound app storage growth.

## 6. Security Architecture (Client-Side)

- **Secrets:** no API keys in source; environment injected via `--dart-define` per build flavor; Supabase anon key is public by design but RLS policies are the real boundary — verify server-side, not client-side.
- **Secure storage:** JWTs/refresh tokens in `flutter_secure_storage` (Keychain/Keystore-backed), never plain SharedPreferences.
- **DRM (screen protection):** `FLAG_SECURE` on Android for studio/explore screens; iOS `UIScreen.capturedDidChangeNotification` to detect (not prevent) screen recording and blur content reactively. Document this limitation explicitly in `rules.md` — iOS cannot hard-block recording, so don't market it as guaranteed prevention.
- **Certificate pinning:** recommended for the FastAPI gateway connection given the payment/wallet surface area; evaluate `dio_certificate_pinning` or platform-native pinning.
- **Obfuscation:** ship release builds with `--obfuscate --split-debug-info` to raise the bar against reverse-engineering the DRM/paywall client logic.
- **Root/jailbreak detection:** optional but recommended given real-money wallet features; degrade gracefully (warn, don't hard-block, to avoid false positives from legitimate power users).

## 7. Backend Architecture Notes (retained from source blueprint, still applicable)

- FastAPI gateway: JWT verification, Stripe webhook (`POST /api/v1/wallet/stripe-webhook`), paginated library API, complexity tokenizer with `round_half_up` clamping, AES-256-GCM prompt encryption, EXIF stripping, 15-min signed URL TTL.
- PostgreSQL: ACID transactions with `SELECT ... FOR UPDATE` row locking, RLS policies per table, `pgvector` for semantic discovery.
- Resilience: circuit breaker around GPU providers (trip after 5 consecutive failures), multi-engine fallback (self-hosted → Pollinations → hosted SDXL), DLQ with 3x exponential-backoff retry before auto-refund.
- Rate limiting: Redis token-bucket (max 5 concurrent jobs/free user), global worker autoscale cap (20 concurrent).

**Gap in the original doc to close before Sprint 1:** the IAP-vs-Stripe decision (see `prod.md` §9) changes whether Stripe webhooks are the *only* credit-fulfillment path or whether App Store/Play Billing server notifications need equivalent webhook handlers. Architect the wallet-credit ledger to accept fulfillment events from multiple payment sources from day one, even if only one is live at launch.

## 8. Testing Architecture

| Layer | Tool | Target |
| :--- | :--- | :--- |
| Unit (domain/use cases, pricing math, wallet logic) | `flutter_test` + `mocktail` | ≥ 85% coverage on `domain/` |
| Widget | `flutter_test` | Every screen has at least a smoke test |
| Golden | `golden_toolkit` | Studio Bar, paywall sheet, Explore card — across 3 viewport sizes |
| Integration | `integration_test` (Patrol optional) | Full generate→download and publish→remix flows against a staging backend |
| Security/contract | custom CI step | Assert raw prompts never appear in client-bound responses |
| Load (backend) | k6/Locust | Confirm rate-limit and autoscale caps under simulated spike |

CI gate: PRs blocked below coverage threshold; AI-generated PRs are **not exempt** — if anything, hold them to a stricter standard since they're more likely to omit edge cases silently.

## 9. Observability

- Crash reporting: Sentry or Firebase Crashlytics, symbolicated release builds.
- Structured logging with correlation IDs passed from client request → FastAPI → GPU worker, so a failed generation can be traced end-to-end.
- Analytics: event schema from `prod.md` §8, funnel dashboards for paywall and publish/remix conversion.
- Alerting: GPU worker failure rate, wallet-deduction failure rate, and signed-URL expiry-related download failures should page engineering, not just log.

## 10. CI/CD & Release Engineering

- GitHub Actions: `flutter analyze` + `dart format --set-exit-if-changed` + `flutter test --coverage` on every PR.
- Build flavors (dev/staging/prod) with distinct Supabase projects and API base URLs — never test against production data.
- Fastlane (or Codemagic) for automated TestFlight/Play Internal builds on merge to `develop`, production builds gated behind manual approval on `main`.
- Semantic versioning + changelog generation; staged rollout (e.g., 10% → 50% → 100% on Play Store) for every production release.
- Dependency vulnerability scanning (`dependabot` or similar) on both Flutter packages and backend Python dependencies.
- Backend infra changes (Terraform, migrations) go through their own CI pipeline with `plan` shown in PR and `apply` gated behind approval — see §11.1. Mobile CI and infra CI are separate pipelines with separate approval gates; a mobile-only PR should never be able to trigger a database migration.

## 11. DevOps & Infrastructure (Right-Sized for Solo Flutter Dev + a Future Backend Dev)

*The original version of this section assumed a multi-person team. Since it's you alone on Flutter (Android/iOS) with a backend/web developer joining later, here's the realistic version — same underlying risks, lighter process.*

### 11.1 Infrastructure — lightweight, not full Terraform (yet)
- You don't need to own this — it's the backend developer's domain once they join. Your job as the Flutter dev: **never hardcode a backend URL or key**; always read `API_BASE_URL` and the Supabase anon key from `--dart-define` per flavor, so whoever owns infra can change environments without touching your code.
- If you're standing up the backend yourself before that developer joins, keep it simple: Supabase CLI migrations (versioned, checked into git) instead of manual dashboard edits — this alone prevents 90% of "staging works, prod doesn't" problems, without needing full Terraform on day one.

### 11.2 Secrets Management (solo-appropriate version)
- GitHub Actions Secrets (or a `.env.local` that's git-ignored) is enough for now — you don't need a full secrets vault as a solo dev. The one rule that still matters at any team size: **secrets never get committed to git**, even in an old commit. Run a quick scan (`gitleaks` or `trufflehog`, both free CLI tools) before your first public/production push.
- Rotation: informal is fine solo — just actually rotate a key immediately if you ever suspect it leaked (e.g., accidentally pasted into an AI chat, screen-shared, etc.), don't wait for a "policy."

### 11.3 Environments
- Minimum viable: **dev** (your machine, mock or shared dev backend) and **prod**. Add a real **staging** once the backend developer joins and you have two people who could otherwise clash testing against the same environment. Don't over-build this alone — it's genuinely fine to ship v1 with dev+prod only.

### 11.4 Backup & Disaster Recovery
- This is backend/Supabase's responsibility, not yours as the Flutter dev — but confirm with the backend developer once they're on board that automated backups + a tested restore actually exist before real user money flows through the wallet. Flag it, don't own it.

### 11.5 Incident Handling (solo version)
- No formal on-call rotation needed for one person — but do keep a simple personal runbook: what do you check first if generation is failing for everyone (GPU worker status → Supabase status page → your own API logs)? Five minutes writing this down now saves a panicked half hour later.
- Crash reporting (Sentry/Crashlytics) alerts should go to your phone/email directly, not just sit in a dashboard nobody checks.

### 11.6 Cost Monitoring
- Set billing alerts (Supabase, GPU provider, Gemini API) yourself, today, even before Sprint 1 code exists — a runaway loop bug hitting a paid API is the single most common "surprise bill" story for solo/small-team AI apps, and a $10 alert threshold costs nothing to set up.

### 11.7 API Contract — the most important thing once a second developer joins
- The moment the backend developer starts, agree on an **OpenAPI/Swagger spec as the source of truth** for every endpoint — request/response shape, error codes, status meanings. Don't let the contract live only in Slack messages or a shared doc that drifts.
- Generate your Dart models from that spec (or at minimum, manually mirror it exactly) instead of guessing response shapes from example JSON — this is the #1 cause of Flutter-vs-backend integration bugs when two people build in parallel.
- Version the API (`/api/v1/...`) from day one so the backend developer can evolve it without silently breaking your already-shipped app builds.
- Use a mock server (e.g., Prism against the OpenAPI spec, or a simple JSON-server) so you can keep building Flutter screens even on days the backend developer hasn't deployed the real endpoint yet — don't block your own progress waiting on theirs.

## 12. Push Notifications & Deep Linking

*Not addressed anywhere in the original blueprint — needed for re-engagement (generation-complete notification) and for the remix/explore sharing loop the business model depends on.*

- Push provider: Firebase Cloud Messaging (FCM) is standard for Flutter even though auth/backend is Supabase — these are unrelated concerns; using FCM for push does not reintroduce Firebase for auth.
- Use cases: generation-complete (critical — this is the async job notification the Realtime channel handles in-app, but push covers the backgrounded/closed-app case), royalty-earned, credit-pack-purchase-confirmed.
- Deep linking (`app_links` or Firebase Dynamic Links successor) for: Explore prompt shares (opening a specific prompt card from an external link), and referral links if/when a referral program is added — plan the URL scheme now even if referral isn't in MVP, since retrofitting deep-link routes later is disruptive.
- Notification payloads never include the raw prompt (same DRM boundary as the API — a push notification is just another client-bound channel).

## 13. Third-Party SDK & Store Compliance Review

- iOS 17+ requires a **Privacy Manifest** (`PrivacyInfo.xcprivacy`) declaring data collection and "required reason" API usage for every SDK bundled (Supabase client, Stripe/IAP, Sentry/Crashlytics, FCM, analytics SDK) — audit this per SDK before each App Store submission, since SDK updates can silently add new required-reason APIs.
- Android Play Console **Data Safety** form must match what's actually collected — keep a single source-of-truth data-inventory doc (what's collected, why, retention period) that both the privacy policy and the Data Safety form are generated from, so they can't drift out of sync.
- License audit (already flagged in `rules.md` §7) extends here: any new SDK pulled in by an AI coding tool gets a license + privacy-manifest check before merge, not after a store rejection.

## 14. Performance Budgets

- Cold start: ≤ 2.5s to interactive on a mid-tier device (e.g., Pixel 6a/iPhone 12 class).
- Explore feed scroll: sustained 60fps; use `AutomaticKeepAliveClientMixin` sparingly and prefer `ListView.builder`/`SliverGrid` with cache extents tuned, not naive `Column` of images.
- App binary size budget: track and alert if a release grows >10% without a corresponding feature justification (common AI-generated-dependency bloat risk).
