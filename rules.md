# CraftAI Studio — Rules of the Road
**Purpose:** Non-negotiable business rules + engineering standards. Every contributor — human or AI coding assistant — must be pointed at this file as grounding context before writing any code.

**Quick Reference — Section Index:**
- [§1 Core Business Rules](#1-core-business-rules)
- [§2 Money & Concurrency Rules](#2-money--concurrency-rules)
- [§3 Security Rules](#3-security-rules)
- [§4 Content & Trust Rules](#4-content--trust-rules)
- [§5 Flutter Engineering Standards](#5-flutter-engineering-standards)
- [§6 Input Validation & Error-Handling Rules](#6-input-validation--error-handling-rules-field--ux-level)
- [§7 Common Developer Loopholes](#7-common-developer-loopholes--mistakes-to-actively-guard-against)
- [§8 Testing Rules](#8-testing-rules)
- [§9 AI-Tool Usage Rules](#9-ai-tool-usage-rules)
- [§10 Accessibility Rules](#10-accessibility-rules)
- [§11 Localization Rules](#11-localization-rules)
- [§12 Release & Versioning Rules](#12-release--versioning-rules)
- [§13 CI/CD & Toolchain Standards](#13-cicd--toolchain-standards)
- [§14 Engineering Process & Review Standards](#14-engineering-process--review-standards)
- [§15 Documentation Hygiene](#15-documentation-hygiene)

---

## 1. Core Business Rules (must be enforced server-side; client is UI only)

1. **Pay-to-Download:** In-app creation and cloud storage are free forever. First export of an unwatermarked 4K master costs a flat 2 credits. Re-downloads of an already-unlocked asset are always free — enforced via an `is_download_unlocked` idempotency check on the server, never trusted from the client.
2. **Creator Royalties:** Royalties are paid only when the triggering credit spend came from `purchased_balance`, never from free/promo/signup credits. This is the single most important anti-fraud rule in the product — any code path that credits a royalty must be traceable to a real payment. Use `CreditSource` enum (not raw string `"purchased"`) to make this compile-time safe.
3. **Range-Bound Dynamic Pricing:** `Final Charge = Clamp(RoundHalfUp(RawScore), MinRange, MaxRange)` per model tier. The clamp brackets are remote configuration (Supabase `app_settings`), not hardcoded — changing them must not require an app store release. The client displays an estimated cost; the server **always recomputes** the final charge independently.
4. **Encrypted Prompt DRM:** Published prompts are AES-256-GCM encrypted at rest using an envelope key stored in the designated secret manager. Decryption happens server-side, in memory, only at generation time. No API response — ever — includes the raw prompt for a prompt the requesting user does not own.

> **PR Rule:** Any PR (AI-generated or human) that touches wallet, royalty, pricing, or prompt-storage code **must cite** which of these 4 rules it affects in the PR description. PRs with no citation on money-related code are review-blocked.

---

## 2. Money & Concurrency Rules

- All balance mutations happen inside a `SELECT ... FOR UPDATE` transaction (or equivalent row lock). No "read balance, then write" pattern outside a lock, ever.
- **Idempotency keys are required on every purchase/unlock endpoint.** Flutter client responsibility: generate a `UUIDv4` key per transaction attempt in the repository layer, persist it locally (e.g., `Hive` or `SharedPreferences`), and reuse the same key on retry — do not generate a new key per retry. This ensures the server deduplicates retries caused by flaky mobile networks without double-charging.
- Refunds (from the DLQ auto-retry-then-refund flow) must be logged with a `reason_code` and `error_code`, visible to the user in their wallet history — never a silent balance change.
- Webhook handlers (Stripe, App Store server notifications, Play Billing server notifications) must verify signatures and be idempotent against replay — the same event ID must never trigger two credit fulfillments.
- Client must never display a balance figure that came from its own optimistic calculation alone — always reconcile against the server-returned balance on every wallet-mutating response.

---

## 3. Security Rules

- **No secrets, API keys, or credentials in source control — ever.** All environment values (Supabase URL, anon key, API base URL) are injected via `--dart-define` per build flavor. AI coding assistants frequently suggest hardcoding a key "for now"; reject this in review every single time, no exceptions.
- All PII and payment data access goes through Supabase RLS policies, not just application-layer checks — assume the application layer will eventually have a bug; RLS is the last line of defense.
- EXIF/metadata stripped from every public-facing preview image before it leaves the server — diffusion models frequently embed prompt data in image metadata headers.
- Client-side DRM (`FLAG_SECURE`, screen-capture detection, copy-blocking) is **best-effort deterrence, not a security guarantee** — never represent it to users or in marketing as unbreakable, especially on iOS and web where OS-level recording cannot be hard-blocked.
- JWTs and refresh tokens stored exclusively in `flutter_secure_storage` (Keychain on iOS, Keystore on Android). Never in `SharedPreferences` or plain local storage.
- Dependency and container vulnerability scanning (`dependabot` or `trivy`) is a **merge-blocking CI step**, not an occasional manual task.
- Run `gitleaks` or `trufflehog` on the full git history before the first production push and on any PR that adds a new file to `android/`, `ios/`, or CI config — secrets leaked in old commits stay leaked.

---

## 4. Content & Trust Rules

- Every AI-generated image/video carries a clear in-app disclosure badge that it is AI-generated — this is both a regulatory trend across multiple jurisdictions and an App Store review item.
- Moderation is **multi-layered**: (1) input prompt filtering, (2) post-generation output classifier, (3) user-reporting and appeal path. No single layer is sufficient on its own; all three must be active before Explore/Marketplace goes live.
- Users publishing to Explore must pass through an explicit self-certification step: *"I confirm this content does not infringe third-party IP and is not NSFW"* — reduces legal exposure and moderation queue volume.
- Content moderation vendor/approach: **[Decision required — see `prod.md §9` item #4].** Sprint 3 (Marketplace) cannot begin until this is resolved. In the interim, Gemini Safety Settings on the Magic Expander + a server-side keyword blocklist serve as Sprint 1/2 input guards only.

---

## 5. Flutter Engineering Standards

- **Responsive layout:** baseline canvas 390×844dp via `flutter_screenutil` (`.w`, `.h`, `.r`, `.sp`). No unconstrained `Row`/`Column` around variable-length content — use `Wrap`, `Flexible`, or `Expanded` with `TextOverflow.ellipsis`. Every form screen wrapped in `SingleChildScrollView` to survive keyboard resize. **Zero RenderFlex overflow is a merge gate** — verified by golden tests across ≥ 3 screen sizes (small phone ~360dp, standard ~390dp, large phone ~430dp) run in CI. "Looked fine on my simulator" is not a pass condition.

- **State management:** GetX only, no exceptions. No `setState` for anything beyond a single-widget, purely cosmetic animation. See `architecture.md §2.4` for GetX-specific lifecycle, scoping, and rebuild-scope rules — memory leaks and UI jank in GetX apps come almost entirely from ignoring those, not from GetX itself.

- **Null safety & typed models:** No raw `dynamic`/`Map<String,dynamic>` crossing from the data layer into presentation. All API response models use `freezed` + `json_serializable`. Code-generated files (`.g.dart`, `.freezed.dart`) are not manually edited.

- **Error handling:** Every repository call returns a typed `Result`/`Either<Failure, T>` — no unhandled exceptions bubbling into widget build methods. No empty `catch (e) {}` blocks; if you're not handling it, log it with a correlation ID and rethrow a typed `Failure`.

- **Const correctness:** Prefer `const` constructors everywhere to limit rebuild scope, especially on the Explore masonry grid. Non-const widgets in a list of hundreds cause frame drops.

- **No magic values:** No raw hex colors, inline `TextStyle(...)`, hardcoded user-facing strings, or raw pixel values inside `features/**/presentation/`. All of these live in `core/constants/` (`app_colors.dart`, `text_styles.dart`, `app_strings.dart`, `app_dimens.dart`) per `architecture.md §2.1`. This is a **CI-lintable, merge-blocking rule** enforced by the analyzer config — not a suggestion.

- **Enums over raw strings/ints** for any fixed set of states: `GenerationStatus`, `ModelTier`, `CreditSource`, `FailureType`. This is load-bearing for the anti-Sybil royalty rule in §1 — `CreditSource.purchased` cannot be typo'd the way the string `"purchased"` can.

- **Widget reuse:** Check `shared/widgets/` before creating a new widget. If a UI pattern is used in 2+ features, it belongs in `shared/widgets/`, not duplicated. AI-generated screens **must** be explicitly instructed to reuse: `AppButton`, `AppTextField`, `AppErrorView`, `AppEmptyState`, `AppNetworkImage`, `CreditCostChip`. A PR that reimplements any of these inline is review-blocked.

- **API/Dio error handling:** Every repository method maps `DioException` to a typed `Failure` per the table in `architecture.md §3.1` before it reaches a controller. A raw `DioException` or its `.message` reaching the UI layer is a **review-blocking defect**, not a style nitpick.

- **Linting:** `very_good_analysis` is the enforced analyzer package (configured in `analysis_options.yaml`). Zero analyzer warnings or hints are allowed to merge — not suppressed, resolved. If a lint rule is genuinely inapplicable for a specific line, it may be suppressed with a `// ignore:` comment that includes an inline explanation of why.

---

## 6. Input Validation & Error-Handling Rules (Field & UX Level)

*General error-handling architecture is in §5 / `architecture.md §3`. This section covers the specific things developers and AI tools skip in practice.*

**Validation — enforce on both client (UX) and server (source of truth):**
- **Prompt text:** non-empty after trimming, max 500 characters enforced — show a visible character counter; never silently truncate.
- **Numeric inputs** (batch count 1–4, credit amounts): bounds-checked client-side (disable `+`/`-` beyond limits) and server-side (never trust client-sent batch count/resolution for pricing — always recompute server-side).
- **Image uploads** (reference photos, face-lock angles): file size cap (max 10 MB), allowed formats (`jpg`/`png`/`heic`), corrupt-file MIME check before upload begins — not just a file picker with no validation.
- **Email/auth fields:** real-time inline format validation before submit; not a generic "invalid input" toast after the request already failed.
- Never rely on a disabled button alone to prevent invalid submission — always re-validate on submit too; disabled state can be bypassed by rapid taps or race conditions.

**Error UX — every error state needs three things, not just a toast:**
1. **What happened** — plain language; never a raw exception message or HTTP status code shown to the user.
2. **What to do next** — retry button, "check your connection," "insufficient credits — top up," etc. Never a dead-end error with no action.
3. **A way out** — user must never be stuck on a loading spinner or blank screen with no back/retry/dismiss option.

**Specific UX gaps to explicitly test for:**
- Double-tap protection on all pay/generate/publish buttons — disable immediately on first tap, re-enable only on server response. Prevents double-spend risk (§2) and bad UX.
- Network drop mid-action (during download, during payment) must resume or clearly fail — never leave a credit deducted with no asset delivered, and never leave the UI frozen on "processing" indefinitely.
- Empty states designed intentionally — empty Library, empty Explore, zero search results — never a blank white screen.
- Form fields must preserve entered data on validation failure — never clear the entire form because one field was invalid.

---

## 7. Common Developer Loopholes & Mistakes to Actively Guard Against

*These are the specific mistakes that slip through in fast-moving / AI-assisted Flutter builds. Call these out explicitly in code review — don't assume "good practices" catches them implicitly.*

- **Trusting client-sent values for money-relevant fields** (price, credit cost, resolution, batch count used for pricing) — always recompute server-side; the client value is a UI hint only.
- **Using `BuildContext` after `dispose()`** — guard every async gap with `if (!context.mounted) return;` or check `controller.isClosed` before using context post-`await`.
- **Unbounded lists/streams held in memory** — paginated Library appended into one growing in-memory list without eviction causes memory growth on long scroll sessions; implement a windowed list or eviction strategy.
- **Firing analytics or side-effect calls inside `build()`** — `build()` runs many times; side effects belong in lifecycle methods or user-action callbacks, never in widget build methods.
- **Copy-pasted API keys/secrets in example or test files** — treat test config with the same secret-handling rules as production; AI tools commonly suggest this when writing "quick" test scripts.
- **Assuming a signed URL or session token never expires mid-flow** — always handle the 401/expired-URL case explicitly (re-auth, regenerate signed URL); not just on first load.
- **Silent catch blocks that swallow errors "to prevent crashes"** — this hides real bugs and generates confusing support tickets; always log with correlation ID and surface a typed `Failure`.
- **Race conditions from rapid repeated taps** — not only on pay/generate buttons but also on toggle actions like "Publish to Explore" or "Like" — debounce or lock the action for the duration of the in-flight request.
- **Hardcoded pixel values instead of ScreenUtil units** — reintroduces the overflow bugs §5 is meant to prevent; AI tools commonly slip these in when generating screens from a Figma export.
- **GetX controllers not scoped per-route** — leads to stale state when a user revisits a screen, or memory leaks from controllers never disposed. See `architecture.md §2.4`.
- **Improper GetX `Obx` wrapping over lazy builders (`ListView.builder`, `ListView.separated`, `GridView.builder`)** — never wrap a lazy list/grid builder with an outer `Obx`. The builder returns a `ListView` instance without executing `itemBuilder` during the `Obx` build pass, causing GetX to throw `[Get] the improper use of a GetX has been detected`. Always wrap the specific leaf widget returned *inside* `itemBuilder` with `Obx`, or construct eagerly using `ListView(children: ...)`.
- **Supabase anonymous session UUID changes on sign-up** — when an anonymous user converts to a full account via `auth.linkUser()`, their UUID changes. Any `jobs` or `library` rows keyed to the old UUID must be migrated atomically in the same transaction, or the user silently loses their cloud library on sign-up.

---

## 8. Testing Rules

- No feature PR merges without accompanying tests at the appropriate layer: **unit** for domain/use-case logic, **widget** for UI rendering and interactions, **integration** for cross-feature flows (generate → realtime update → library save). This applies equally — if not more strictly — to AI-generated code, which tends to omit edge cases (empty states, network failure, race conditions) unless explicitly instructed to cover them.
- **Mandatory Widget Smoke Tests for All Views:** Every screen/view (`*view.dart`) MUST have an automated widget smoke test (`testWidgets`) that mounts the view with `ScreenUtilInit` and standard mobile viewport dimensions (`390x844`). This ensures that GetX runtime assertions (`Improper use of GetX`), rendering flex overflows, and missing dependencies are caught and resolved **at development time** via `flutter test` before device deployment.
- **Coverage gate — `domain/` and money-handling code: minimum 85%.** Enforced in CI via:
  ```bash
  flutter test --coverage
  lcov --summary coverage/lcov.info --fail-under-functions 85
  ```
  PRs that drop `domain/` coverage below 85% are blocked. Coverage on `presentation/` is best-effort, but every screen must have at minimum one smoke test.
- **Golden tests** for overflow validation run across 3 viewport widths (360dp, 390dp, 430dp) as a CI gate — not optional. Use `golden_toolkit` or Flutter's built-in `matchesGoldenFile`.
- Any bug fix must ship with a regression test that reproduces the original bug. "Fixed, no test needed" is not a valid PR state.
- Security contract test: an automated CI test explicitly asserts that no API response to a non-owner ever contains a decrypted `prompt_cipher` field — run on every PR touching `explore_prompts` or remix endpoints.

---

## 9. AI-Tool Usage Rules

**Before starting any AI-assisted coding session:**
- Feed the relevant sections of `prod.md`, `architecture.md`, and this file as context. Do not rely on the AI inferring business rules from a vague one-line prompt.
- Explicitly instruct the AI to use the existing shared widgets (`AppButton`, `AppTextField`, `AppErrorView`, `AppEmptyState`, `AppNetworkImage`) — AI tools generate new one-off widgets by default.
- Explicitly instruct the AI to follow the GetX controller scoping rules (`architecture.md §2.4`) — AI tools default to global singletons.

**During review of AI-generated code — mandatory checks:**
- [ ] Money/concurrency correctness (§2) — no raw balance reads without a lock, idempotency key present
- [ ] No hardcoded secrets, API keys, or `--dart-define` values in source (§3)
- [ ] State management is GetX only — no `setState` for business logic (§5)
- [ ] No raw `DioException` reaching the UI layer (§5)
- [ ] Typed models only — no `Map<String, dynamic>` in controllers or widgets (§5)
- [ ] New third-party dependency: license verified (Apache-2.0 or commercial-equivalent for any face/ID/AI model)
- [ ] Analytics events emitted per `prod.md §8` for the new feature
- [ ] **UI-Backend Feature & Engine Parity:** Every AI model, tool, engine, or pipeline supported on the backend (e.g. LLMs for prompt expansion, diffusion models for generation) MUST have an explicit, user-facing control/selector on the frontend UI. Never hide multi-model capabilities behind an invisible server-side default or black box.
- [ ] **AI Engine Transparency:** The UI must visibly indicate which AI model/tool is currently active (e.g., model badges, latency chips, credit cost tags) so the user has full clarity and control.

**Standing rules:**
- AI-generated code is an unreviewed first draft — "the AI wrote it" is never a valid explanation for a production bug.
- Never auto-merge or auto-deploy AI-generated PRs without all CI gates passing (`architecture.md §10`).
- Do not paste real user data, production API keys, wallet balances, or any credentials into AI tool chat context, even for debugging purposes.

---

## 10. Accessibility Rules

- All interactive controls have semantic labels (`Semantics` widget or `semanticLabel` param) — no icon-only buttons without a label. This is an App Store review criterion for UGC platforms.
- Support OS-level dynamic text scaling without layout breakage — tested at **1.0x, 1.3x, and 2.0x** text scale factors. Overflow at 2.0x is a bug, not a design limitation.
- Minimum contrast ratio **4.5:1** for body text against the dark theme background tokens (`#0B0F19` background) — WCAG 2.1 AA standard.
- The entire checkout/paywall flow (credit top-up, download unlock) must be fully operable via screen reader (VoiceOver on iOS, TalkBack on Android) — both an ethical baseline and an App Store review criterion for payment flows.
- Never use color alone to convey state (e.g., green = success, red = error) — always pair with a label, icon, or pattern for color-blind users.

---

## 11. Localization Rules

- **All user-facing strings externalized to ARB files from the first commit**, even if only `en` ships at launch. Setup:
  1. Add `flutter_localizations` and `intl` to `pubspec.yaml`
  2. Create `l10n.yaml` at the project root with `arb-dir: lib/l10n`
  3. Run `flutter gen-l10n` to generate the `AppLocalizations` class
  4. Use `AppLocalizations.of(context)!.stringKey` — never a string literal in a `Text()` widget inside `features/`
- No string concatenation for user-facing text — use ICU message format placeholders: `{name} earned {amount} credits` not `name + " earned " + amount + " credits"`. Concatenation breaks translation for languages with different word orders.
- Credit/currency amounts formatted via `NumberFormat` (the `intl` package) — never `"$${amount.toStringAsFixed(2)}"` inline, which breaks for non-USD locales.

---

## 12. Release & Versioning Rules

- Semantic versioning (`MAJOR.MINOR.PATCH`) — every production release has a `CHANGELOG.md` entry summarizing user-visible changes, bug fixes, and any breaking API changes.
- **Staged rollout on both stores: 10% → 50% → 100%** — never 100% on first push of any non-hotfix release. Monitor crash-free session rate and wallet-deduction error rate before advancing each stage.
- Feature flags (via Supabase `app_settings` or a dedicated flag service) for anything that changes pricing brackets, royalty splits, or moderation thresholds — these must be remotely adjustable without an app store release cycle.
- A rollback procedure is documented and rehearsed at least once before the first production release. Minimum rollback plan:
  1. Play Store: revert to previous release via "Rollout to previous release" in Play Console
  2. App Store: submit an expedited review for the previous build version
  3. Backend: FastAPI is deployed via versioned container — `docker pull craftai-api:previous-tag && docker-compose up -d`
  4. Supabase migrations: keep migration scripts reversible (`down.sql`) for every `up.sql`
- Release builds always include: `--obfuscate --split-debug-info=build/debug-info/`. The generated `.symbols` directory must be uploaded to the crash reporter (Sentry/Crashlytics) immediately after each release build — without uploading symbols, production stack traces are unreadable.

---

## 13. CI/CD & Toolchain Standards

*This section defines what "CI green" actually means — a vague "tests pass" bar is not a CI gate.*

### 13.1 Toolchain Decisions (resolved)

| Tool | Decision | Notes |
| :--- | :--- | :--- |
| **Analyzer / Linter** | `very_good_analysis` | Configured in `analysis_options.yaml` at project root |
| **Crash Reporting** | Sentry | Symbolicated builds; alerts to dev's phone/email directly |
| **Offline Cache** | Hive | Lightweight, no codegen for cache; `Drift` used only if SQL queries are needed |
| **State Management** | GetX | No exceptions; see `architecture.md §2.4` |
| **Dependency Scanning** | `dependabot` | Auto-PRs for patch updates; manual review for minor/major |
| **Secrets Scanning** | `gitleaks` | Run before first production push and on any PR touching CI/env files |

### 13.2 Required CI Steps (all must pass to merge)

```yaml
# Every PR gate — runs on GitHub Actions
steps:
  - dart format --set-exit-if-changed .        # Format check
  - flutter analyze --fatal-infos              # Zero warnings/hints (very_good_analysis)
  - flutter test --coverage                    # All tests
  - lcov --summary coverage/lcov.info \
         --fail-under-functions 85             # Coverage gate on domain/
  - flutter test --update-goldens=false        # Golden tests (3 viewports)
  - trivy fs . --exit-code 1 --severity HIGH   # Dependency vulnerability scan
```

### 13.3 Release Build Steps (additional, on merge to `main`)

```bash
flutter build apk --release \
  --obfuscate \
  --split-debug-info=build/debug-info/ \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --dart-define=API_BASE_URL=$API_BASE_URL \
  --flavor prod

# Upload debug symbols to Sentry immediately after build
sentry-cli upload-dif build/debug-info/
```

### 13.4 Performance Budget Enforcement

| Budget | Threshold | Measurement |
| :--- | :--- | :--- |
| Cold start to interactive | ≤ 2.5s | Firebase Performance Monitoring — `app_start` trace |
| Explore feed scroll | 60fps sustained | Flutter DevTools `PerformanceOverlay` in profile mode |
| Release APK size growth | < 10% per release | `flutter build apk --analyze-size` output diff between releases |

A release that exceeds any budget without a documented justification is not promoted beyond 10% rollout.

### 13.5 Billing Alerts (set immediately, not when billing starts)

| Service | Alert Threshold | Channel |
| :--- | :--- | :--- |
| Supabase | $20/month | Email to dev |
| RunPod / GPU provider | $30/month | Email to dev |
| Google Gemini API | $15/month | Email to dev |
| Stripe / IAP | Abnormal spike (>2× 7-day avg) | Email to dev |

---

## 14. Engineering Process & Review Standards (Right-Sized: Solo Flutter Dev + a Future Backend Dev)

*Full team process (CODEOWNERS, mandatory second-reviewer approval, on-call rotations) doesn't apply to a solo developer — but a few disciplines still matter alone, and one becomes critical the moment a second developer joins.*

- **Self-review discipline:** Any commit touching wallet display logic, credit deduction UI, or DRM screens gets a deliberate second pass — re-read the diff an hour later or the next morning, not immediately after writing it. This is the practical substitute for peer review when working alone.

- **Branching:** `main` is always in a working, deployable state. Feature work happens on short-lived branches (`feature/`, `fix/`, `chore/`) merged via PR — even solo, this prevents a broken `main` from blocking an urgent hotfix.

- **Once the backend developer joins — the one rule that matters most:** Neither developer changes the API contract (request/response shape, status codes, pricing fields) without updating the shared OpenAPI spec first and notifying the other person. This single habit prevents the majority of two-person integration bugs. See `architecture.md §11.7`.

- **Mandatory Flow Change & Architecture Optimization Protocol:**
  If at any point there is an observation, recommendation, or need to modify, optimize, or adjust any user flow or architecture:
  1. **Observe & Deep Dive:** Audit existing specifications across all markdown files (`rules.md`, `prod.md`, `architecture.md`, `craftai_studio_platform_flow_and_architecture.md`) and running codebase to understand the exact design intent and constraints.
  2. **Structured Analysis & Impact Brief:** Prepare a concrete analysis stating: (a) Why the improvement is proposed, (b) Tradeoffs and user impact, (c) Proposed UI layout/controls, and (d) API contract & data model adjustments.
  3. **Inform & Await Explicit Approval:** Present the proposal to the user / Tech Lead. **DO NOT write code or make unilateral decisions** until explicit feedback and approval are granted.
  4. **Document Before / In Lockstep with Execution:** Upon approval, immediately update the affected markdown specifications so documentation remains the ground truth.

- **Definition of Done** for any feature:
  - [ ] Unit + widget tests written and passing
  - [ ] Analytics events from `prod.md §8` are firing (verified in debug dashboard)
  - [ ] All error states handled per §6 (no blank screens, no stuck spinners)
  - [ ] AI-tool review checklist from §9 completed
  - [ ] **UI-Backend Parity Verified:** User has visible, selectable controls for all active AI models and prompt tools (no hidden black boxes)
  - [ ] Spec-alignment check completed against `craftai_studio_platform_flow_and_architecture.md` and `rules.md`
  - [ ] Manually tested on a **real device** (not only a simulator) — simulators hide `FLAG_SECURE` behavior, real camera/gallery permissions, and real network conditions
  - [ ] `flutter analyze` clean (0 errors, 0 warnings) and `flutter test --coverage` passing CI gate
  - [ ] No hardcoded secrets, pixel values, or string literals in `features/` (all from `AppStrings`, `AppColors`, `AppDimens`)
  - [ ] Markdown documents updated to reflect any approved flow changes

- **AI-tool output ownership:** You own everything an AI tool generates, fully. "The AI wrote it" is never a valid explanation for a production bug. Treat AI-generated code as a fast first draft that you personally verify against this file before merging.

- **When the team grows beyond two people:** Revisit this section — `CODEOWNERS`, mandatory reviews on money/DRM code, and a basic incident severity matrix (`architecture.md §11.5`) become worth the overhead at that point, not before.

---

## 15. Documentation Hygiene

- `prod.md`, `phase.md`, `architecture.md`, and this file (`rules.md`) are **living documents**. Any decision that overrides them — a scoped-down feature, a changed pricing bracket, a newly selected vendor — must be reflected here **within the same sprint it was decided**, not left to drift from what is actually shipped.
- When an open decision in `prod.md §9` is resolved, the decision owner updates `prod.md` to replace the open item with the decided outcome (including date and rationale), then updates any affected section in `architecture.md` or this file.
- Never delete a rule from this file without a PR comment explaining why it was removed — a missing rule with no explanation looks like an accidental omission, not an intentional decision.
- Outdated sections get an `> ⚠️ **Stale:** This section reflects the state as of [date]. Updated in [link].` notice at the top of the section rather than silent deletion — preserves history while signaling staleness.
- Any new third-party SDK added via `pubspec.yaml` triggers an update to: (1) `architecture.md §13` privacy manifest audit note, (2) the `prod.md §7` data collection inventory, and (3) this file's §3 security rules if the SDK introduces a new data-access surface.
