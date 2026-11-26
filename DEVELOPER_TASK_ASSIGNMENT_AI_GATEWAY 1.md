# CraftAI Studio — Developer Task Assignment & Implementation Guide
## Multi-Provider AI Gateway with Zero-Redeploy Supabase Key Auto-Adoption

**Document Purpose:** Actionable, ticket-ready task breakdown for **Database/Supabase**, **Backend (FastAPI)**, **Web (Next.js 15)**, and **Mobile (Flutter)** developers.  
**Core Rule (Local-First ➔ Auto-Paid Upgrade):**  
Currently we operate **without paid API keys**, so all workflows run cleanly on **local / free engines** (`Local Diffusion / SDXL`, `Cloudflare Workers AI`, `Groq / Local LLM`, `rembg / LaMa / DDColor`). The moment an admin injects a paid API key (`FAL_API_KEY`, `OPENAI_API_KEY`, `GEMINI_API_KEY`, `OPENROUTER_API_KEY`) in the **Supabase Dashboard**, the backend **hot-reloads within 60 seconds (zero code change, zero redeploy)** and Web + Mobile automatically unlock and route to the paid AI models.

---

## 1. Open Questions — Implemented Industry Defaults & TL Alternative Switch Matrix

All open questions from the TL review are resolved below using **industry-standard defaults** so development is unblocked immediately. Every decision is **config-driven / modular** — if TL prefers their alternative option later, we can switch without rewriting core code:

| Open Question / Area | ✅ What We Implement Now (Industry Best Default) | 🔄 Alternative Solution (If TL Prefers) | How Easy to Switch? |
|---|---|---|---|
| **1. Model Selection UX (User Choice vs. Feature-Based)** | **Hybrid (`Auto (Recommended)` + Manual Choice)** — UI fetches `GET /api/v1/models`, disables incompatible models per task, and never overcharges on fallback. | **Pure Feature/Tier Mode** — Hide model names (`FLUX`, `GPT`, `Gemini`) in UI and show only *Draft / Standard / HD / Edit* tiers. | **1 Config Flag (`ui_config.hide_model_names = true`)** in `app_settings` + `GET /api/v1/models`. |
| **2. Billing Model (Royalty + Unlock vs. Pay-per-Gen)** | **Keep `wallets` + Creator Royalties (`author_royalty_cut`) + Pay-to-Download (`is_download_unlocked`)** with 2-phase credit reservation + TTL reaper. | **Pure Pay-per-Generation** — Include HD download immediately on generation (`is_download_unlocked = true`) and disable download fee. | **Config Flag (`download_cost = 0`, `royalty_config.is_enabled = false`)** already in `ConfigService`. |
| **3. Prompt Intelligence (OpenRouter Forcing)** | **Conditional (`enhance_prompt: bool = False` on Curated Templates)** — Skips LLM on pre-tuned templates; uses OpenRouter (when key exists) or Groq/Local LLM with `2.5s` fallback. | **Always-On OpenRouter** — Force OpenRouter structured JSON enhancement on every freeform and template request. | **1 Flag (`force_prompt_enhancement = true`)** in `ConfigService`. |
| **4. Text LLM User Choice (`ai_model`)** | **Admin/Config Default + Optional User Override** — Uses `OpenRouter` (if key set) or `Groq/Gemini/Local` automatically; manual `ai_model` still supported in Copilot. | **100% Hidden Auto-LLM** — Remove LLM picker from Prompt Copilot and route all text calls via OpenRouter `auto`. | **UI toggle only** (`PromptService` already defaults when `ai_model` is omitted). |
| **5. Template Composition Engine (Playwright vs. Pillow)** | **Phase 3 Dual-Stage (`Client Canvas` + `Pillow/CairoSVG`)** — 60fps preview on Web/Mobile, 300 DPI `<100ms` server export, zero browser OOM/SSRF risk. | **Isolated Playwright Worker** — Separate headless Chromium microservice (outside FastAPI) for complex CSS Grid/Flexbox HTML templates. | **Renderer Adapter Swap** (`HtmlPlaywrightRenderer` implements same `IRenderer` interface behind `/compositions`). |
| **6. Queue & Realtime Infra** | **PostgreSQL `FOR UPDATE SKIP LOCKED` + FastAPI Workers + WebSocket / Supabase Realtime** (zero extra Redis/Celery hosting cost now). | **Redis + Celery Worker Pool** — Dedicated broker for high-concurrency batch bursts. | **Swap `JobDispatcher`** interface (`PGQueueDispatcher` ➔ `CeleryDispatcher`) without changing API/UI. |
| **7. Selfie Privacy & Moderation Refunds** | **24h TTL Auto-Delete** on uploaded selfies (`signed URLs` to providers) + **100% Auto-Refund** if provider blocks on safety filter (with optional fallback retry). | **Permanent User Asset Vault + No Auto-Retry** — Keep selfies in user's private library until manually deleted; fail with refund without fallback retry. | **1 Storage Lifecycle Rule + 1 Boolean (`auto_retry_on_moderation`)** in `ai_models`. |
| **8. Paid Keys Availability (Today vs. Future)** | **Local-First Auto-Fallback** — Runs on `local_sdxl`, `cloudflare`, `Groq/Local LLM`, and `app/infrastructure/tools/` today; auto-unlocks paid APIs within 60s when keys are added to Supabase. | **Strict Paid-Only Mode** — Return `503 Model Unavailable` instead of falling back to local engines when a paid key is missing. | **1 Flag (`allow_local_fallback = false`)** per model in `ai_models`. |

---

## 2. How Zero-Redeploy Supabase Key Auto-Adoption Works

```
┌─────────────────────────────────────────────────────────────────────────┐
│ 1. Admin opens Supabase Dashboard ──> Inserts/Updates API key in        │
│    `public.ai_provider_secrets` (service_role ONLY, never exposed!)     │
└───────────────────────────────────┬─────────────────────────────────────┘
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ 2. Backend `ConfigService` (60s TTL cache) reads active providers +     │
│    secrets via `get_supabase_admin()`                                   │
│    • Key missing/empty ──> `is_configured = false` (Routes to Local)    │
│    • Key present       ──> `is_configured = true`  (Unlocks Paid API)   │
└───────────────────────────────────┬─────────────────────────────────────┘
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ 3. `GET /api/v1/models` returns live catalog to Web & Mobile:           │
│    { id, display_name, tasks, tier, credit_cost, is_available, mode }   │
│    • Web & Mobile automatically enable paid model chips & badges!       │
└─────────────────────────────────────────────────────────────────────────┘
```

> [!CAUTION]
> **Security Rule:** Never put raw API keys in `ai_providers` or `app_settings` if `anon`/`authenticated` roles have `SELECT` access! Store secrets in **`public.ai_provider_secrets`** with **RLS enabled and ZERO public/authenticated policies** (readable ONLY by FastAPI's `service_role` client).

---

## 3. Developer Task Assignments

---

### TRACK 1: Supabase / Database Engineer (`craftai_studio_backend/supabase/`)

#### Task DB-1: Create Incremental Migration `010_ai_gateway_and_usage_logs.sql`
* **Do NOT drop or rename** `wallets`, `wallet_ledger`, `jobs`, `explore_prompts`, `artworks`, `remix_sessions`.
* **Create 4 new tables:**
  1. `public.ai_providers`:
     * `id (UUID PK)`, `provider_key (TEXT UNIQUE: 'fal', 'openai', 'google', 'openrouter', 'local', 'cloudflare')`, `display_name (TEXT)`, `base_url (TEXT)`, `is_active (BOOLEAN DEFAULT true)`, `priority (INT DEFAULT 100)`, `updated_at (TIMESTAMPTZ)`.
     * RLS: Public/authenticated `SELECT` allowed (no secrets here!).
  2. `public.ai_provider_secrets`:
     * `provider_key (TEXT PK REFERENCES ai_providers(provider_key) ON DELETE CASCADE)`, `api_key (TEXT NOT NULL)`, `extra_config (JSONB DEFAULT '{}')`, `updated_at (TIMESTAMPTZ)`.
     * **RLS:** `ALTER TABLE public.ai_provider_secrets ENABLE ROW LEVEL SECURITY;` with **NO `SELECT` policies** for `anon` or `authenticated` (`service_role` bypasses RLS).
  3. `public.ai_models`:
     * `id (UUID PK)`, `model_key (TEXT UNIQUE: 'flux_schnell', 'flux_pulid_facelock', 'gpt_image_1', 'gemini_flash_image', 'local_sdxl')`, `provider_key (TEXT REFERENCES ai_providers(provider_key))`, `external_model_id (TEXT NOT NULL)`, `display_name (TEXT)`, `tasks (TEXT[] — e.g. {'text_to_image', 'image_edit', 'face_lock_remix'})`, `tier (TEXT: 'economy'|'standard'|'premium'|'editing')`, `credit_cost (NUMERIC(10,2))`, `fallback_model_key (TEXT)`, `capabilities (JSONB — supports_facelock, supports_negative_prompt, supports_transparency, aspect_ratio_map)`, `is_active (BOOLEAN DEFAULT true)`, `sort_order (INT DEFAULT 0)`.
  4. `public.ai_usage_logs`:
     * `id (UUID PK)`, `user_id (UUID REFERENCES auth.users(id))`, `job_id (UUID REFERENCES public.jobs(id))`, `provider_key (TEXT)`, `model_key (TEXT)`, `operation (TEXT)`, `input_tokens (INT DEFAULT 0)`, `output_tokens (INT DEFAULT 0)`, `image_count (INT DEFAULT 1)`, `resolution (TEXT)`, `provider_cost_usd (NUMERIC(10,6) DEFAULT 0)`, `credits_charged (NUMERIC(10,2) DEFAULT 0)`, `latency_ms (INT DEFAULT 0)`, `created_at (TIMESTAMPTZ DEFAULT NOW())`.
* **Extend `public.jobs`:**
  * Add `idempotency_key TEXT`, `provider_key TEXT`, `model_key TEXT`, `provider_job_id TEXT`, `estimated_cost NUMERIC(10,2)`, `actual_cost NUMERIC(10,2)`, `reserved_until TIMESTAMPTZ`, `parent_job_id UUID REFERENCES public.jobs(id)`, `version INT DEFAULT 1`.
  * Add `CREATE UNIQUE INDEX IF NOT EXISTS idx_jobs_user_idempotency ON public.jobs (user_id, idempotency_key) WHERE idempotency_key IS NOT NULL;`.
* **Seed initial rows:** Seed `local`, `cloudflare`, `fal`, `openai`, `google`, `openrouter` in `ai_providers` and seed `ai_models` with `fallback_model_key = 'local_sdxl'` (or `'cloudflare_flux'`).
* **Acceptance Criteria:** Migration runs cleanly on Supabase SQL Editor; `anon` role gets `0` rows / permission denied if querying `ai_provider_secrets`.

#### Task DB-2: Atomic 2-Phase Credit Reservation & Reaper RPCs
* Create PostgreSQL RPC `reserve_user_credits(p_user_id UUID, p_job_id UUID, p_amount NUMERIC, p_idempotency_key TEXT)`:
  * Uses `SELECT ... FOR UPDATE` on `wallets`.
  * Checks idempotency first; deducts/holds into `reserved` state; writes `wallet_ledger` entry.
* Create PostgreSQL RPC `settle_or_refund_credits(p_job_id UUID, p_actual_cost NUMERIC, p_status TEXT)`:
  * On `'failed'` or moderation rejection: auto-refunds 100% of reserved credits.
  * On `'completed'`: settles actual cost (and credits `author_royalty_cut` if `remixed_from_prompt_id` is set).
* Create a cleanup function/cron `reap_stale_reserved_jobs()` to auto-fail & refund jobs stuck in `pending`/`processing` past `reserved_until` (5 mins).

---

### TRACK 2: Backend Engineer (`craftai_studio_backend` — FastAPI)

#### Task BE-1: Dynamic Secret & Model Catalog Loader (`app/services/config_service.py`)
* Extend `ConfigService` (keep 60s TTL cache + add `POST /api/v1/admin/config/refresh` optional cache-buster):
  * Fetch `ai_providers`, `ai_provider_secrets` (via `get_supabase_admin()`), and `ai_models`.
  * Compute `is_configured = bool(secret.api_key.strip())` per provider (never log or return raw keys!).
  * Fallback to `.env` keys (`settings.OPENAI_API_KEY`, etc.) **only if** Supabase `ai_provider_secrets` has no row for that provider.
  * **Acceptance Criteria:** Adding a key in Supabase `ai_provider_secrets` makes `ConfigService.get_provider_key("fal")` return the new key within 60s without restarting FastAPI.

#### Task BE-2: Provider Interface & Registry (`app/infrastructure/clients/`)
* Create `app/infrastructure/clients/image_provider.py` (`ImageProvider` ABC: `generate`, `edit`, `facelock_remix`, `get_job_status`, `supports(task)`).
* Create `app/infrastructure/clients/provider_registry.py` (`ProviderRegistry` + `CapabilityResolver`):
  * Resolves requested `model_key` (or `"auto"`).
  * **Auto-Fallback Rule:** If the requested paid provider has `is_configured == False`, automatically route to `model.fallback_model_key` (e.g., `local_sdxl` / `huggingface` / `cloudflare`) and log `is_fallback_used = True` in `jobs.metadata`.
  * **Parameter Normalization:** Strip `negative_prompt` when `capabilities.supports_negative_prompt == False`; map `aspect_ratio` using `capabilities.aspect_ratio_map`.
* Implement/wrap adapters using dynamically injected API keys (instantiated per key hash, not module-level singletons!):
  * `LocalImageAdapter` (wraps existing `local_diffusion_client.py` / `local_sdxl_client.py` / `huggingface_client.py` / `cloudflare_client.py`).
  * `FalImageAdapter` (`fal-ai/flux/schnell`, `fal-ai/flux-pulid` for Face-Lock).
  * `OpenAIImageAdapter` (`gpt-image-1`).
  * `GeminiImageAdapter` (`gemini-2.5-flash-image` for editing).
  * `OpenRouterTextAdapter` (for `PromptService` when `OPENROUTER_API_KEY` is configured in Supabase; `2.5s` timeout + automatic fallback to Groq/Gemini/Local LLM).

#### Task BE-3: Request Schema, Public Models API & Generation Flow
* Update `GenerationDispatchRequest` (`app/schemas/generation.py`):
  * Add optional `quality: Optional[str] = "standard"` (`economy|standard|premium`), `enhance_prompt: bool = False`, and `idempotency_key: Optional[str] = None`.
  * Keep all existing camelCase/snake_case fields (`face_reference_urls`, `remixed_from_prompt_id`, `anchor_image_url`, `edit_instruction`) intact.
* Add `GET /api/v1/models` (mounted on `api_v1_router` in `app/api/v1/router.py`):
  * Returns active models from `ai_models` with: `model_key`, `display_name`, `provider_key`, `tasks`, `tier`, `credit_cost`, `is_available` (`true` if local OR paid key exists in Supabase), `active_mode` (`"paid_api"` vs `"local_fallback"`), `capabilities`.
* Update `generation_service.py`:
  * Preserve `_optimize_prompt_for_diffusion`.
  * Skip LLM enhancement when `enhance_prompt == False` or `remixed_from_prompt_id` is present.
  * Reserve credits via `reserve_user_credits` before dispatch; settle/refund via `settle_or_refund_credits` on completion/failure; write `ai_usage_logs`.
  * Generate a lightweight **WebP `preview_url`** alongside `master_url` on upload to Supabase Storage.
  * Keep `app/infrastructure/tools/` (`bg_remover_engine.py`, `lama_inpaint_service.py`, `upscaler_engine.py`, `ddcolor_service.py`) wired for tool endpoints.
* Add webhook signature verification (e.g., `fal.ai` Ed25519/JWKS check) for async provider callbacks.

#### Task BE-4: Privacy TTL & Phase 3 Composition Export
* Schedule/run a 24h cleanup job for temporary user selfie uploads (`face_reference_urls` bucket) and pass short-lived signed URLs to external providers.
* *(Phase 3)* Upgrade `tool_service._render_marketing_poster` to read normalized `0.0–1.0` JSONB templates and export 300 DPI PNG/PDF via **Pillow + CairoSVG** + face-aware smart crop using existing saliency/vision bounding boxes.

---

### TRACK 3: Web Frontend Engineer (`craftai_studio_web` — Next.js 15 / React 19)

#### Task WEB-1: Dynamic Model Catalog & Offline Fallback
* Fetch `GET /api/v1/models` on Studio mount (cache cleanly with short revalidation so newly added Supabase keys reflect automatically without a Web redeploy).
* **Offline Seed List:** Ship a hardcoded static fallback array (`local_sdxl`, `flux_schnell`) in `studio/page.tsx` so the picker never renders empty offline or during backend cold-start.
* Update Studio model selector:
  * Support `"Auto (Recommended)"` + manual model cards showing `display_name`, `credit_cost`, and live status (`"Local Engine"` badge when running locally vs `"HD Cloud"` when Supabase key is active).
  * Automatically disable models where `is_available == false` or that don't support the current task (`text_to_image` vs `image_edit` vs `face_lock_remix`).

#### Task WEB-2: Dispatch Payload, Error Handling & Selfie Remix Contract
* Update `src/lib/api/backend-client.ts` / Studio submit handler:
  * Generate a unique `idempotency_key` (`crypto.randomUUID()`) per click and reuse it on retries so double-clicks never double-charge.
  * Set `enhance_prompt: false` automatically when dispatching a Trending Template Selfie Remix (`remixed_from_prompt_id` set); expose an "Enhance Prompt" toggle for custom freeform prompts.
  * **Selfie Remix Contract:** Upload user selfie to Supabase Storage first (public/signed `https://` URL — never `localhost`/blob URLs, as SSRF guard blocks local IPs) and pass `face_reference_urls: [selfieUrl]` without setting `structured_metadata.style_only`.
  * **HTTP `400` / `402` Handling:** On `402 Insufficient credits`, open the Wallet Top-Up modal; on `400 Model unavailable`, show toast and prompt switching to `auto`.
  * Keep existing WebSocket progress listener + `jobs` polling fallback.

#### Task WEB-3: Next.js Image Domains & Phase 3 Canvas Editor
* Whitelist `fal.media`, `v3.fal.media`, `oaidalleapiprodscus.blob.core.windows.net`, and Supabase Storage domains in `next.config.ts`.
* *(Phase 3)* Build interactive `'use client'` template editor using **HTML5 Canvas / `Konva.js`** with `next/font` + shared `.ttf` font files and normalized `0.0–1.0` coordinates matching backend Pillow export.

---

### TRACK 4: Mobile Frontend Engineer (`craftai_studio_mobile` — Flutter / GetX / Dio)

#### Task MOB-1: Dynamic Model Selector Sheet (`studio_model_sheet.dart`)
* Fetch `GET /api/v1/models` in `StudioController`, seeded with a hardcoded static fallback list (`local_sdxl`, `flux_schnell`) so the picker never renders empty offline or during ngrok reconnect.
* Render model chips dynamically with capability tags (`Fast`, `Face-Lock`, `Edit`, `HD`), credit cost, and live active mode badge.
* Disable chips where `is_available == false` or incompatible with the active mode (Text-to-Image, Face-Lock Remix, Image Editing).

#### Task MOB-2: Idempotent Dispatch, Error Handling & Selfie Remix (`studio_controller.dart`)
* Generate a UUID `idempotency_key` before calling dispatch; ensure Dio retry interceptor preserves the same `idempotency_key` on network retries.
* In `startTemplateRemixGeneration` (from `TrendingTemplatesView` ➔ `TemplatePhotoRemixBottomSheet`), pass `enhance_prompt: false` and upload the selfie to Supabase Storage (`https://` URL) before passing `face_reference_urls: [selfieUrl]` (never local file paths or `localhost` URLs, which SSRF guard rejects).
* **HTTP `400` / `402` Handling:** On `402`, open the Wallet Top-Up sheet; on `400`, display snackbar prompting user to select `auto` or an available local model.

#### Task MOB-3: Prompt Metadata & Background Resilience
* Update `prompt_expand_model.dart` to parse optional structured fields (`subject`, `environment`, `lighting`, `camera`, `negative_prompt`) while remaining backward-compatible with `master_prompt`.
* Add **Supabase Realtime / FCM Push Notification** listener on `jobs` so if a user backgrounds the app during a 20s+ HD or Face-Lock generation, the completed image syncs immediately on resume.
* *(Phase 3)* Update `marketing_poster_sheet.dart` to render remote normalized `0.0–1.0` JSONB layouts via Flutter `CustomPainter` / `InteractiveViewer` and call backend Pillow export for final master download.

---

## 5. Critical Production Loophole Fixes (Added from Peer Review)

1. **Localhost Webhook Trap (BE-2 / BE-3):** `FalImageAdapter` uses bounded synchronous polling (`https://fal.run`, 45–60s timeout) during local development (`http://127.0.0.1:8000`). Async webhooks with Ed25519 signature verification are enabled **only** when `WEBHOOK_BASE_URL` is configured as a public `https://` domain.
2. **Dev / Guest UUID Foreign Key Crash (DB-1 / DB-2):** `ai_usage_logs.user_id` omits the hard `auth.users(id)` FK, and `reserve_user_credits` / `settle_or_refund_credits` RPCs include an early bypass when `p_user_id IS NULL OR p_user_id = '00000000-0000-0000-0000-000000000000'::uuid`.
3. **Explicit Paid Model vs. `auto` Fallback (BE-2 / WEB-1 / MOB-1):**
   * `GET /api/v1/models` returns `is_available: false` for paid models whose key is missing so the UI disables those chips.
   * Local fallback applies **only** to `model="auto"` (and legacy `"flux"`/`"local"` aliases). Explicitly requesting an unavailable paid model (e.g., `"gpt_image_1"`) returns **`400 Bad Request`** instead of silently downgrading.
4. **Multi-Worker Cache Sync (BE-1):** `POST /api/v1/models/refresh` clears the current worker's cache (dev convenience only); in multi-worker production (`uvicorn --workers N`), all workers automatically adopt new Supabase keys within **60 seconds** via `CACHE_DURATION = 60` TTL.
5. **Offline / First-Launch Seed Catalog (WEB-1 / MOB-1):** Both Web (`studio/page.tsx`) and Mobile (`StudioController`) must ship a hardcoded static fallback list (`local_sdxl`, `flux_schnell`) so the model picker never renders empty if `GET /api/v1/models` fails offline.
6. **Public / Signed WebP `preview_url` (BE-3):** Upload WebP previews to a public bucket (`generations` / `marketing_posters`) OR generate `storage.create_signed_url(path, 86400)` so Next.js `<Image />` and Flutter `CachedNetworkImage` never fail with `403 Forbidden`.

---

## 6. End-to-End Verification Checklist (Before Production Release)


1. **No Paid Keys Test (Day-1 Default):** With `ai_provider_secrets` empty, generate an image, run Face-Lock Selfie Remix, and run Background Removal — verify 100% succeed via local/free engines with `active_mode: "local_fallback"` and zero 401/500 errors.
2. **Hot-Swap Key Injection Test (Zero Redeploy):** Insert `FAL_API_KEY` into Supabase `ai_provider_secrets` ➔ wait 60s ➔ call `GET /api/v1/models` ➔ verify `fal-ai/flux/schnell` and `fal-ai/flux-pulid` flip to `is_available: true, active_mode: "paid_api"` and Web/Mobile pick them up automatically.
3. **Double-Click & Crash Refund Test:** Send two identical requests with the same `idempotency_key` (only 1 credit deduction happens); simulate worker timeout and verify Reaper RPC refunds 100% of reserved credits.
4. **Security Check:** Query `ai_provider_secrets` using Supabase `anon` key and `authenticated` user JWT — verify access is strictly denied.

