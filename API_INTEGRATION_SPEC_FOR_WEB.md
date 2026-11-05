# CraftAI Studio — Web & Mobile API Integration Specification

> **Target Audience:** Next.js 15 Web & Flutter Mobile Engineering Teams  
> **Backend Architecture:** FastAPI (Python 3.10+) + Supabase (PostgreSQL, Storage, Auth) + Local Metal MPS / Sidecar  
> **Backend Git Branch:** `feature/multi-llm-configurable-gateway` (Base: `feature/production-clean-architecture`)  
> **Backend Repository:** `git@github.com:RitutoshAeologic/craftai_studio_backend.git`  
> **PR Link:** [Create PR on GitHub](https://github.com/RitutoshAeologic/craftai_studio_backend/pull/new/feature/multi-llm-configurable-gateway)  
> **Mobile Parity:** Flutter Mobile App (iOS / Android)  
> **Local Base URL (Recommended):** `http://127.0.0.1:8000/api/v1` *(or root `http://127.0.0.1:8000`)*  
> **LAN Wi-Fi Base URL (Same Office/Network):** `http://192.168.29.26:8000/api/v1`  
> **Live Backend Base URL:** `http://200.141.14.171:8085`  
> **Live API Base URL:** `http://200.141.14.171:8085/api/v1`  
> **Interactive Swagger UI:** `http://200.141.14.171:8085/docs`  
> **ReDoc Alternative Docs:** `http://200.141.14.171:8085/redoc`  
> **Backend Health Check:** `http://200.141.14.171:8085/health`  
> **Public HTTPS Tunnel (Legacy Fallback):** `https://craftai-backend.loca.lt/api/v1` *(Password/IP: `115.245.193.3` | Header: `Bypass-Tunnel-Reminder: true`)*  
> **Swagger UI (Interactive Playground):** `http://127.0.0.1:8000/docs`  
> **ReDoc Documentation:** `http://127.0.0.1:8000/redoc`  
> **OpenAPI JSON Schema:** `http://127.0.0.1:8000/openapi.json`  
> **Direct Route Aliasing:** All tools, vision, and auth routes support both `/api/v1/prompt-engineering/...` and direct `/api/v1/...` paths to eliminate 404s.  
> **Universal Parameter Compatibility:** All FastAPI endpoints natively accept both `camelCase` (standard JavaScript / TypeScript / Next.js) and `snake_case` (Python / Flutter). You can send either format without 422 schema validation errors.

---

## 1. Authentication & Security Headers

All requests from Next.js (Client Components or Server Actions) and Flutter Mobile should pass the Supabase JWT access token obtained via `@supabase/ssr` / `supabase_flutter`.

```http
Authorization: Bearer <SUPABASE_ACCESS_TOKEN>
Content-Type: application/json
```

---

## 2. Core Operational Endpoints (FastAPI)

### 2.1 Visual Generation Dispatch
- **Endpoint:** `POST /api/v1/prompt-engineering/generation/dispatch` *(or `/api/v1/generation/dispatch`)*
- **Description:** Dispatches a visual image generation task to serverless workers (Local SDXL-Lightning RealVisXL v4.0 on Apple Silicon MPS / Sidecar on Port 8001, Hugging Face FLUX.1-schnell, or InstantID Face-Lock).

#### Request Payload:
```json
{
  "prompt": "An adorable 3D isometric diorama of a cyberpunk gaming room, miniature aesthetic, Octane Render lighting, 8k...",
  "character_id": null,
  "face_reference_urls": null,
  "negative_prompt": "blurry, low quality, distorted artifacts",
  "structured_metadata": null,
  "width": 1024,
  "height": 1024,
  "seed": 42,
  "model": "flux",
  "remixed_from_prompt_id": null
}
```
*Field Notes:*
- `prompt` (string, 1–4000 characters): Supports rich master prompts.
- `negative_prompt` (string, optional): Explicit negative tokens to eliminate unwanted artifacts (used directly by SDXL / compiled engines).
- `structured_metadata` (object, optional): Visual Director metadata (`subject`, `environment`, `lighting`, `camera_optics`, `avoid`). When passed, the backend automatically compiles model-specific prompts for the target engine.
- `model` (string, optional): `"flux"` (default), `"sdxl"`, `"gemini"`, or `"chatgpt"`.
- `width` / `height` (int, 512–2048): `1024x1024` (1:1), `768x1344` (9:16), `1344x768` (16:9).
- `face_reference_urls` (array of strings, optional): If 1–3 photo URLs are passed, engine auto-promotes to **Tier 1 (InstantID Face-Lock)**.
- `remixed_from_prompt_id` (string, optional): Pass original Explore card ID if user is remixing a community prompt for creator royalty split.

#### Response (HTTP 200):
```json
{
  "task_id": "gen_1dca6620",
  "tier": "Tier 0 (SDXL-Lightning RealVisXL Engine)",
  "status": "ready",
  "estimated_seconds": 6,
  "direct_image_url": "https://txiuwtrmfvceddqsjvhk.supabase.co/storage/v1/object/public/user_generations/sdxl_5681d376fa734038960f7d46fe96efaa.png"
}
```
*(Note: If local MPS/sidecar is unavailable, backend seamlessly cascades to `Tier 0 (FLUX.1-schnell via Hugging Face)` or safe gateway)*

---

### 2.2 Realtime Generation Progress (WebSocket & Polling)

#### A. WebSocket Progress Stream:
- **Endpoint:** `ws://127.0.0.1:8000/api/v1/prompt-engineering/generation/ws/generation/{task_id}`
- **Message format:**
```json
{
  "progress": 50,
  "status": "processing",
  "message": "Compiling diffusion prompt tokens..."
}
```

#### B. HTTP Polling Fallback (for disconnected clients):
- **Endpoint:** `GET /api/v1/prompt-engineering/status/{task_id}`
- **Response:**
```json
{
  "task_id": "gen_1dca6620",
  "status": "completed",
  "progress": 100,
  "output_url": "https://.../flux_output.png"
}
```

---

### 2.3 Dynamic Multi-LLM Configuration (Hot-Reloadable)
- **Endpoint:** `GET /api/v1/prompt-engineering/config`
- **Description:** Returns the active LLM provider, configured model mappings, fallback cascade order, and available providers.
- **Admin Hot-Reloading:** The active provider and models can be changed at runtime anytime by modifying the `llm_config` row in Supabase `app_settings` without restarting the server or redeploying code.

#### Response (HTTP 200):
```json
{
  "active_provider": "gemini",
  "fallback_order": ["gemini", "groq", "local"],
  "available_providers": ["gemini", "groq", "openai", "claude", "local"],
  "model_mappings": {
    "gemini": "gemini-2.5-flash",
    "groq": "qwen/qwen3.8-27b",
    "openai": "gpt-4o-mini",
    "claude": "claude-3-5-sonnet-20241022",
    "local": "offline-cinematic-engine"
  }
}
```

---

### 2.4 Prompt Engineering & Expansion (Magic Enhance)
- **Endpoint:** `POST /api/v1/prompt-engineering/expand`
- **Description:** Expands a short user idea into a 700+ character master prompt using the configured LLM with automatic failover cascade (Gemini 2.5 Flash -> Groq Qwen -> Local Offline Engine).
- **Character Limit:** `raw_prompt` supports up to **4,000 characters** (prevents 422 length truncation).
- **Option A Edit Preservation:** If `raw_prompt` contains `"Edit image1 as follows: "`, all LLM adapters preserve the exact prefix while expanding the descriptors.

#### Request:
```json
{
  "raw_prompt": "Makoto Shinkai aesthetic, golden hour clouds, floating islands",
  "starter_chip": "Cinematic",
  "aspect_ratio": "1:1",
  "ai_model": null
}
```
*Note:* Pass `ai_model: null` or omit to use the dynamic default from Supabase `app_settings`, or specify `"gemini"`, `"groq"`, `"openai"`, `"claude"`, or `"local"`.

#### Response (HTTP 200):
```json
{
  "master_prompt": "Breathtaking visual masterpiece in the distinctive anime aesthetic of Makoto Shinkai. Majestic floating islands drift suspended among radiant golden hour cumulonimbus clouds, bathed in amber sunlight, ultra-detailed 8K...",
  "negative_prompt": "blurry, low quality, distorted, extra limbs, watermark, signature",
  "complexity_score": 3,
  "model_used": "google/gemini-2.5-flash",
  "structured_metadata": {
    "subject": "Majestic floating islands suspended in the sky",
    "environment": "Radiant golden hour cumulonimbus clouds",
    "lighting": "Warm amber sunlight, atmospheric glow",
    "camera_optics": "35mm wide-angle, deep focus",
    "art_style": "Makoto Shinkai distinctive anime aesthetic",
    "avoid": ["blurry", "low quality", "distorted", "watermark"],
    "preserved_elements": []
  }
}
```

#### 2.4.1 Multi-Model Structured Prompt Engine (Web Implementation Guide)

The prompt expansion engine now returns both the synthesized **`master_prompt`** and a detailed **`structured_metadata`** object (Visual Director breakdown).

##### A. TypeScript Interfaces for Web:
```typescript
export interface StructuredPromptMetadata {
  subject: string;             // Central character/entity description
  environment: string;         // Background, atmospheric setting
  lighting: string;            // Cinematic lighting, rim lights, shadow dynamics
  camera_optics: string;       // Lens focal length, aperture (e.g. f/1.4), film grain
  art_style: string;           // Overall artistic genre or rendering engine
  avoid: string[];             // Negative visual concepts to suppress
  preserved_elements: string[];// Identity features, faces, or elements locked from modification
}

export interface PromptExpandResponse {
  master_prompt: string;
  negative_prompt: string;
  complexity_score: number;
  model_used: string;
  structured_metadata?: StructuredPromptMetadata;
}
```

##### B. How the Next.js Web UI Should Utilize This:
1. **Interactive Prompt Inspector (Studio UI Parity):**
    - In Studio, clicking the Inspector icon (`Icons.manage_search`) opens a modal displaying:
        - **What You Typed:** The user's clean draft.
        - **AI Visual Breakdown:** Visual director badges for `Subject`, `Environment`, `Lighting`, `Camera Optics`, `Style`.
        - **Preserved Identity Badges:** Green locked pills for anything in `preserved_elements` (e.g., `🔒 Authentic Facial Structure Locked`).
2. **Passing to Generation Dispatch (`/generation/dispatch`):**
    - Forward `structured_metadata` in the POST body to `/generation/dispatch`.
    - The backend's `PromptCompiler` automatically compiles model-specific prompts:
        - **FLUX.1-schnell:** Compiles into a rich natural-language visual narrative (ideal for FLUX text encoders).
        - **SDXL:** Compiles into weighted bracketed tags (`(35mm film grain:1.2), ...`).
3. **Identity & Facial Preservation:**
    - When users enter prompts like *"1985 Bollywood style and keep my face preserved"*, the LLM extracts the identity traits into `preserved_elements`.
    - The Conversational Chat Copilot (`/chat-delta`) locks these elements, preventing subsequent refinement turns from altering facial features.

---

### 2.5 Prompt Chat Copilot (Delta Compiler)
- **Endpoint:** `POST /api/v1/prompt-engineering/chat-delta`
- **Description:** Conversational prompt refiner for natural language tweaks (e.g., *"Make it nighttime and add neon rain"*). Preserves `"Edit image1 as follows: "` during image-to-image refinement. Updates structured metadata while locking preserved elements.

#### Request:
```json
{
  "base_prompt": "Edit image1 as follows: white tiger",
  "user_instruction": "add glowing blue eyes and royal gold crown",
  "session_id": "copilot-sess-456",
  "turn_count": 1,
  "ai_model": null
}
```
*Note:* `session_id` is **optional** (backend auto-generates a unique `sess_<id>` if omitted, preventing 422 errors). `turn_count` defaults to `1`. `ai_model` defaults to active Supabase config.

#### Response (HTTP 200):
```json
{
  "compiled_prompt": "Edit image1 as follows: white tiger with glowing blue eyes, ornate 24k gold crown, cinematic lighting, photorealistic textures",
  "diff": {
    "added": ["with glowing blue eyes", "ornate 24k gold crown"],
    "removed": []
  },
  "suggested_chips": ["Add Rim Light", "35mm Grain", "Bokeh Background"],
  "model_used": "google/gemini-2.5-flash",
  "structured_metadata": {
    "subject": "white tiger with glowing blue eyes, ornate 24k gold crown",
    "environment": "seamless studio background",
    "lighting": "cinematic lighting, rim reflections",
    "camera_optics": "85mm portrait lens, f/1.4",
    "art_style": "photorealistic textures",
    "avoid": ["blurry", "distorted"],
    "preserved_elements": ["white tiger"]
  }
}
```

---

### 2.5 Creative Skills Toolbox (AI Tools Suite)
All tools feature direct root aliasing: can be invoked with `/api/v1/prompt-engineering/tools/<tool>` or `/api/v1/tools/<tool>`.

#### A. AI Background Remover:
- **Endpoint:** `POST /api/v1/prompt-engineering/tools/remove-background` *(or `/api/v1/tools/remove-background`)*
- **Request:** (Supports both HTTPS URL and Base64 Data URL)
```json
{
  "image_url": "https://.../photo.png"
}
```
- **Response:** (Returns both `output_url`, `cutout_url`, and `image_url` for web/mobile compatibility)
```json
{
  "task_id": "tool_rmbg_abc123",
  "status": "completed",
  "output_url": "https://.../photo_transparent.png",
  "cutout_url": "https://.../photo_transparent.png",
  "image_url": "https://.../photo_transparent.png",
  "tokens_consumed": 0,
  "credits_deducted": 0
}
```

#### B. Zero-Token Optical Super-Resolution Upscaler (2X / 4X):
- **Endpoint:** `POST /api/v1/prompt-engineering/tools/upscale` *(or `/api/v1/tools/upscale`)*
- **Description:** Super-resolution optical upscaler. Takes input image and scales resolution up to 4K.
- **Request:**
```json
{
  "image_url": "https://.../photo.png",
  "scale": 2,
  "mode": "photo"
}
```
*Field Notes:*
- `scale` or `scale_factor` (int): `2` (2X HD) or `4` (4X Ultra 4K).
- `mode` (string, optional): `"photo"`, `"portrait"`, `"anime"`, or `"fast"`.
- `image_id` (string, optional): Look up from Supabase `jobs` table if `image_url` is omitted.
- **Response:**
```json
{
  "task_id": "tool_upscale_123",
  "status": "completed",
  "scale": 2,
  "mode": "photo",
  "original_resolution": "1024x1024",
  "upscaled_resolution": "2048x2048",
  "output_url": "https://.../upscaled.png",
  "image_url": "https://.../upscaled.png",
  "is_free": true,
  "engine": "Optical Photo Super-Resolution (CPU)"
}
```

#### C. AI Background Inpainting:
- **Endpoint:** `POST /api/v1/prompt-engineering/tools/ai-background` *(or `/api/v1/tools/ai-background`)*
- **Request:**
```json
{
  "image_url": "https://.../product.png",
  "mode": "studio",
  "custom_backdrop": "minimalist pastel marble pedestal with soft sunlight",
  "aspect_ratio": "1:1"
}
```
- **Response:**
```json
{
  "task_id": "tool_bg_123",
  "status": "completed",
  "output_url": "https://.../studio_backdrop.png",
  "image_url": "https://.../studio_backdrop.png",
  "mode": "studio",
  "is_free": true
}
```

#### D. AI Canvas Expansion (Outpainting):
- **Endpoint:** `POST /api/v1/prompt-engineering/tools/ai-expand` *(or `/api/v1/tools/ai-expand`)*
- **Request:**
```json
{
  "image_url": "https://.../photo.png",
  "target_ratio": "16:9",
  "quality": "1k"
}
```
- **Response:**
```json
{
  "task_id": "tool_expand_123",
  "status": "completed",
  "output_url": "https://.../expanded_16_9.png",
  "image_url": "https://.../expanded_16_9.png",
  "target_ratio": "16:9",
  "is_free": true
}
```

#### E. Commercial Product Detail Showcase:
- **Endpoint:** `POST /api/v1/prompt-engineering/tools/product-detail` *(or `/api/v1/tools/product-detail`)*
- **Request:**
```json
{
  "image_url": "https://.../shoe.png",
  "product_name": "Ultra Velocity Sneaker",
  "aspect_ratio": "4:5",
  "language": "Auto"
}
```
- **Response:**
```json
{
  "task_id": "tool_product_123",
  "status": "completed",
  "output_url": "https://.../product_card.png",
  "image_url": "https://.../product_card.png",
  "product_name": "Ultra Velocity Sneaker",
  "is_free": true
}
```

#### F. Marketing Promotional Poster Composition:
- **Endpoint:** `POST /api/v1/prompt-engineering/tools/marketing-poster` *(or `/api/v1/tools/marketing-poster`)*
- **Request:**
```json
{
  "image_url": "https://.../item.png",
  "topic": "Summer Solstice Special 50% Off",
  "category": "Promotion",
  "aspect_ratio": "4:5",
  "headline": "Limitless Radiance"
}
```
- **Response:**
```json
{
  "task_id": "tool_poster_123",
  "status": "completed",
  "output_url": "https://.../marketing_poster.png",
  "image_url": "https://.../marketing_poster.png",
  "topic": "Summer Solstice Special 50% Off",
  "is_free": true
}
```

#### G. Tool Presets (Relight, Blur, Custom Preset):
- **Endpoint:** `POST /api/v1/prompt-engineering/tools/edit-preset` *(or `/api/v1/tools/edit-preset`)*
- **Request:** (`image_url` is optional; if omitted, backend looks up `image_id` in `jobs` table)
```json
{
  "image_id": "job_123",
  "image_url": "https://.../photo.png (optional - URL or base64)",
  "action": "relight",
  "target_preset": "golden_hour",
  "lock_subject": true
}
```
- **Response:**
```json
{
  "task_id": "tool_job_123_abc",
  "status": "completed",
  "applied_tool": "relight",
  "subject_masked": true,
  "tokens_consumed": 0,
  "output_url": "https://.../transformed.png",
  "image_url": "https://.../transformed.png"
}
```

---


#### H. Magic Object Eraser (Zero-Hallucination LaMa Inpainting):
- **Endpoint:** `POST /api/v1/prompt-engineering/tools/remove-object` *(or `/api/v1/tools/remove-object`)*
- **Description:** Fast Fourier Convolution (FFC) neural inpainting engine. Erases unwanted people, power lines, text, blemishes, or background objects in sub-second latency with authentic texture synthesis.
- **Request:** (Accepts image/mask URLs or Base64 data URLs)
```json
{
  "image_url": "https://.../photo.png",
  "mask_url": "https://.../mask_white_on_black.png",
  "image_base64": "data:image/png;base64,... (optional alternative)",
  "mask_base64": "data:image/png;base64,... (optional alternative)"
}
```
*Mask Specification:* White pixels (`#FFFFFF`) indicate the area to ERASE; Black pixels (`#000000`) indicate pixels to PRESERVE.
- **Response:**
```json
{
  "task_id": "tool_erase_7ca4f0cb",
  "status": "completed",
  "output_url": "https://txiuwtrmfvceddqsjvhk.supabase.co/storage/v1/object/public/user_generations/erased/....png",
  "image_url": "https://txiuwtrmfvceddqsjvhk.supabase.co/storage/v1/object/public/user_generations/erased/....png",
  "url": "https://txiuwtrmfvceddqsjvhk.supabase.co/storage/v1/object/public/user_generations/erased/....png",
  "latency_ms": 967.0,
  "tokens_consumed": 0,
  "credits_deducted": 0,
  "is_free": true
}
```

#### I. Vintage Photo Colorizer (DDColor High-Fidelity Neural Restorer):
- **Endpoint:** `POST /api/v1/prompt-engineering/tools/colorize` *(or `/api/v1/tools/colorize`)*
- **Description:** Dual-Decoder Colorization (DDColor) neural engine. Restores authentic, vivid color to historical B&W photos or faded family portraits while preserving 100% of native luminance, edge micro-contrast, and texture sharpness.
- **Request:**
```json
{
  "image_url": "https://.../vintage_photo.png",
  "image_base64": "data:image/png;base64,... (optional alternative)",
  "saturation": 1.2
}
```
*Field Notes:*
- `saturation` (float, default `1.0`): Multiplier from `0.5` (subtle/moody) to `1.5` (vibrant/rich).
- **Response:**
```json
{
  "task_id": "tool_color_b69bebcf",
  "status": "completed",
  "output_url": "https://txiuwtrmfvceddqsjvhk.supabase.co/storage/v1/object/public/user_generations/colorized/....png",
  "image_url": "https://txiuwtrmfvceddqsjvhk.supabase.co/storage/v1/object/public/user_generations/colorized/....png",
  "url": "https://txiuwtrmfvceddqsjvhk.supabase.co/storage/v1/object/public/user_generations/colorized/....png",
  "latency_ms": 1091.7,
  "tokens_consumed": 0,
  "credits_deducted": 0,
  "is_free": true
}
```

---

### 2.6 Multimodal Aesthetic Vision Scanner
- **Endpoint:** `POST /api/v1/vision-scan` *(or `/api/v1/prompt-engineering/vision-scan`)*
- **Description:** Reverse-engineers aesthetic concepts, style tags, and camera optics from a reference image using Gemini 2.5 Flash.
- **Request:** (Accepts JSON request body or URL query parameter `?photo_url=...`)
```json
{
  "image_url": "https://.../reference_photo.png"
}
```
- **Response (HTTP 200):**
```json
{
  "extracted_prompt": "Close-up, natural light portrait of a beautiful young woman...",
  "detected_style": "Natural Light Portraiture",
  "lighting_optics": "Natural golden hour light, 85mm f/1.8",
  "model_used": "google/gemini-2.5-flash (Live AI)"
}
```

---

### 2.7 Ephemeral Face-Lock Reference Photos
- **Upload Endpoint:** `POST /api/v1/prompt-engineering/upload-reference` (Multipart form-data: `file`)
- **Cleanup Endpoint:** `POST /api/v1/prompt-engineering/cleanup-reference` (JSON: `{"image_url": "https://..."}`)
- *Note:* Backend auto-purges reference photos 30 seconds after generation to enforce the **Zero-Retention Privacy Policy**.

---

### 2.8 System Health Verification
- **Endpoints:** `GET /health` and `GET /api/v1/health`
- **Response (HTTP 200):**
```json
{
  "status": "healthy",
  "service": "CraftAI Studio Backend",
  "version": "1.0.0"
}
```

---

### 2.9 Session Signout & Cache Invalidation
- **Endpoint:** `POST /api/v1/auth/signout` *(or `/api/v1/prompt-engineering/auth/signout`)*
- **Description:** Idempotent endpoint that clears token cache in server memory and revokes Supabase session. Safe for both authenticated users and anonymous sessions.
- **Headers:** `Authorization: Bearer <token>` (optional)
- **Response (HTTP 200):**
```json
{
  "status": "success",
  "message": "Signed out successfully",
  "cache_cleared": true
}
```

---

### 2.10 Local Diffusion Engine & Sidecar Worker (Zero-Cost Inference)
CraftAI Studio supports 100% free, high-performance image generation using **SDXL-Lightning + RealVisXL v4.0** on Apple Silicon Metal Performance Shaders (`mps`).

To prevent heavy model weights (~6.5GB) from slowing down FastAPI development reload cycles (`uvicorn --reload`), the diffusion engine runs in an isolated sidecar microservice:

#### Sidecar Architecture:
- **Port 8001:** `scripts/diffusion_sidecar.py` loads the PyTorch / Diffusers pipeline in a separate process.
- **Port 8000:** FastAPI gateway checks if the sidecar is active at `http://127.0.0.1:8001/generate`.
- **Auto-Failover Hierarchy:**
    1. **Primary:** Diffusion Sidecar Worker (Port 8001) / Local MPS
    2. **Secondary:** Hugging Face FLUX.1-schnell cloud inference
    3. **Tertiary:** Direct safe diffusion gateway

#### Starting the Backend Locally with Sidecar:
```bash
# Terminal 1: Start isolated Diffusion Sidecar (Port 8001)
.venv/bin/python scripts/diffusion_sidecar.py

# Terminal 2: Start Main FastAPI Gateway (Port 8000)
.venv/bin/uvicorn app.main:app --reload --port 8000
```

---

### 2.11 Standardized API Error Response Contract
FastAPI has been enhanced with unified global exception handlers. All errors consistently return JSON formatted for seamless frontend consumption:

#### A. Pydantic Validation Error (HTTP 422):
Returned when a request body fails schema constraints. Includes a clear, human-readable summary in `message`:
```json
{
  "error": "ValidationError",
  "message": "Invalid field 'body -> raw_prompt': String should have at least 1 character",
  "detail": [
    {
      "type": "string_too_short",
      "loc": ["body", "raw_prompt"],
      "msg": "String should have at least 1 character"
    }
  ],
  "details": [...]
}
```

#### B. Domain / Application Exception (HTTP 400, 429, 504):
Returned for rate limits, safety moderation blocks, or provider timeouts:
```json
{
  "error": "RateLimitException",
  "message": "Rate limit reached. Please generate or wait before next refine.",
  "details": { "retry_after": 60 }
}
```

#### C. Unhandled Server Error (HTTP 500):
Returned for unforeseen backend exceptions; logs traceback server-side and shields internal infrastructure:
```json
{
  "error": "InternalServerError",
  "message": "An unexpected server error occurred. Our engineering team has been notified."
}
```

> **Web Implementation Tip (Axios / Fetch):**  
> Always read `err.response?.data?.message || err.response?.data?.detail?.[0]?.msg || err.message` to display user-friendly toast alerts.

---

### 2.12 Conversational Remix Lab (Image-to-Prompt Dialogue)
Allows web users to click "⚡ Remix" on any artwork and iteratively converse with an AI copilot (Groq Llama 3.3 / Gemini 2.5 Flash) to evolve the visual prompt while locking or referencing the anchor image.

#### A. Initialize Remix Session:
- **Endpoint:** `POST /api/v1/prompt-engineering/remix/sessions` *(or `/api/v1/remix/sessions`)*
- **Request Payload:**
```json
{
  "anchor_image_url": "https://.../source_artwork.png",
  "source_type": "explore_card",
  "style_weight": 0.75
}
```
*(Accepts both `camelCase` e.g. `anchorImageUrl`, `sourceType`, `styleWeight` and `snake_case`)*

- **Response (HTTP 200):**
```json
{
  "session_id": "remix_sess_a1b2c3d4",
  "anchor_image_url": "https://.../source_artwork.png",
  "welcome_message": "Anchor image locked! How would you like to remix or transform this artwork? (e.g., 'Change time of day to golden hour', 'Swap aesthetic to cyberpunk neon')",
  "suggested_chips": [
    "Switch lighting to moody cinematic golden hour",
    "Convert art style to Japanese Ukiyo-e woodblock print",
    "Transform into a miniature 3D isometric diorama",
    "Add dramatic volumetric rain reflections"
  ]
}
```

#### B. Conversational Remix Chat Turn:
- **Endpoint:** `POST /api/v1/prompt-engineering/remix/chat` *(or `/api/v1/remix/chat`)*
- **Request Payload:**
```json
{
  "session_id": "remix_sess_a1b2c3d4",
  "user_instruction": "Make the background stormy cyberpunk Tokyo with glowing neon holograms",
  "ai_model": "groq",
  "base_prompt": "A majestic mechanical tiger prowling in a serene garden"
}
```
*(Accepts both `camelCase` e.g. `sessionId`, `userInstruction`, `aiModel`, `basePrompt` and `snake_case`)*

- **Response (HTTP 200):**
```json
{
  "turn_count": 1,
  "refined_prompt": "A majestic mechanical tiger prowling in a storm-drenched cyberpunk Tokyo alleyway, glowing holographic neon kanji reflections, rain droplets on titanium chassis, hyperrealistic 8k...",
  "explanation": "Adapted setting to stormy Neo-Tokyo, infused atmospheric neon puddle reflections, preserved the mechanical tiger subject.",
  "diff_added": "storm-drenched cyberpunk Tokyo alleyway, glowing holographic neon kanji reflections, rain droplets on titanium chassis",
  "diff_removed": "serene garden",
  "suggested_chips": [
    "Add intense lightning flashes in the sky",
    "Change the mechanical tiger's eye glow to crimson",
    "Switch perspective to low-angle dramatic wide shot"
  ],
  "latency_ms": 889
}
```

#### C. Get Session History:
- **Endpoint:** `GET /api/v1/prompt-engineering/remix/sessions/{session_id}` *(or `/api/v1/remix/sessions/{session_id}`)*
- **Response (HTTP 200):** Returns session metadata and chronological conversation turns.

---

### 2.13 Cloud Library Asset Deletion (Database & Storage Purge)
Allows web users to permanently remove creations. In a single atomic call, it deletes the job record from Supabase `jobs` and `collection_items` tables, and purges the image file from the `user_generations` Supabase storage bucket.

- **Endpoint:** `DELETE /api/v1/prompt-engineering/library/{job_id}` *(or `/api/v1/library/{job_id}`)*
- **Headers:** `Authorization: Bearer <SUPABASE_TOKEN>`
- **Response (HTTP 200):**
```json
{
  "success": true,
  "job_id": "f8a7e584-6380-4966-9ef0-1a7008892186",
  "deleted_storage_blobs": 1,
  "message": "Creation and associated storage assets permanently deleted."
}
```

---

### 2.14 Dynamic AI Background Templates Discovery
Fetches the current dynamic catalog of studio backdrop presets, pricing, and prompt recipes directly from the backend rather than hardcoding in frontend bundles.

- **Endpoint:** `GET /api/v1/prompt-engineering/tools/ai-background/templates` *(or `/api/v1/tools/ai-background/templates`)*
- **Response (HTTP 200):**
```json
{
  "templates": [
    {
      "id": "pure_white",
      "name": "Pure White Studio",
      "description": "High-key, shadowless e-commerce white background",
      "credit_cost": 0,
      "prompt_suffix": "clean seamless infinite pure white studio backdrop, soft high-key commercial lighting"
    },
    {
      "id": "smart",
      "name": "Smart Contextual AI",
      "description": "AI automatically analyzes product subject and generates the optimal aesthetic scene",
      "credit_cost": 1,
      "prompt_suffix": "photorealistic studio setting with organic shadows matching product geometry"
    },
    {
      "id": "marble",
      "name": "Luxury Marble Podium",
      "description": "Italian Carrara marble pedestal with soft window illumination",
      "credit_cost": 1,
      "prompt_suffix": "luxurious white Carrara marble pedestal, architectural minimalist interior, soft window dappled sunlight"
    },
    {
      "id": "wood",
      "name": "Rustic Natural Wood",
      "description": "Warm artisanal oak tabletop with morning bokeh",
      "credit_cost": 1,
      "prompt_suffix": "warm rustic oak timber tabletop, warm morning daylight, soft blurred kitchen background"
    },
    {
      "id": "neon",
      "name": "Cyberpunk Neon",
      "description": "Futuristic moody reflections with vibrant edge lighting",
      "credit_cost": 1,
      "prompt_suffix": "dark reflective acrylic floor, vibrant cyan and magenta neon edge rim lighting, futuristic studio"
    },
    {
      "id": "custom",
      "name": "Custom User Prompt",
      "description": "Describe your own custom studio backdrop and lighting",
      "credit_cost": 1,
      "prompt_suffix": ""
    }
  ],
  "total": 6
}
```

---

### 2.15 Universal Search & Similar Artwork Discovery

#### A. Universal Search:
- **Endpoint:** `POST /api/v1/prompt-engineering/search` *(or `/api/v1/search`)*
- **Request Payload:**
```json
{
  "query": "cyberpunk neon city",
  "search_type": "text",
  "aspect_ratios": ["1:1", "16:9"],
  "sort_by": "popular",
  "page_size": 20
}
```
*(Accepts both `camelCase` e.g. `searchType`, `aspectRatios`, `sortBy`, `pageSize` and `snake_case`)*

#### B. Similar Creations Recommendation:
- **Endpoint:** `GET /api/v1/explore/similar/{card_id}` *(or `/api/v1/prompt-engineering/explore/similar/{card_id}`)*
- **Query Params:** `?limit=8`
- **Response (HTTP 200):**
```json
{
  "source_card_id": "card_9921",
  "similar": [
    {
      "id": "card_8812",
      "title": "Neo Tokyo Alleyway",
      "image_url": "https://.../img2.png",
      "category": "Cyberpunk",
      "similarity_score": 0.94
    }
  ]
}
```

---

## 3. Unified Supabase Database Schemas (Web & Mobile Parity)

The Web app and Flutter Mobile app read and write directly to Supabase via `@supabase/ssr` / `@supabase/supabase-js` / `supabase_flutter`. All tables share **identical parameter names and cross-device user sync**.

---

### 3.1 `wallets` (Unified Credits Ledger)
> *Alias View:* `user_wallets` (both queries resolve identically)

| Column | Type | Description |
| :--- | :--- | :--- |
| `user_id` | `UUID PRIMARY KEY REFERENCES auth.users` | Authenticated user ID |
| `credits` | `NUMERIC(10,2)` | Usable balance (`free_daily_balance + purchased_balance`) |
| `free_daily_balance` | `NUMERIC(10,2)` | Daily free tier credits (Default: `500.00`) |
| `purchased_balance` | `NUMERIC(10,2)` | Stripe paid credits (qualifies for creator royalties) |
| `earned_royalty_balance` | `NUMERIC(10,2)` | Accrued earnings from community remixes |
| `total_generations` | `INT4` | Lifetime counter of visual generations |
| `total_royalties_earned` | `NUMERIC(10,2)` | Lifetime creator earnings |
| `updated_at` | `TIMESTAMPTZ` | Timestamp of last wallet transaction |

#### Atomic RPC Calls:
* **Deduct Credits:** `client.rpc('deduct_user_credits', { p_user_id: user.id, p_amount: 2.0, p_reason: 'generation' })`
* **Refund Credits:** `client.rpc('refund_user_credits', { p_user_id: user.id, p_amount: 1.0, p_reason: 'generation_failed' })`

---

### 3.2 `jobs` (Unified Generations & History)
> Tracks all visual generations, tool modifications, and user library history.

| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | `UUID PRIMARY KEY` | Internal UUID |
| `job_id` | `TEXT UNIQUE` | Task tracking ID (e.g., `gen_1dca6620`) |
| `user_id` | `UUID REFERENCES auth.users` | Owner user ID (ensures cross-device sync) |
| `type` | `TEXT` | `'IMAGE_GEN'`, `'TOOL_BG'`, `'TOOL_EXPAND'`, etc. |
| `status` | `TEXT` | `'completed'`, `'failed'`, `'processing'` |
| `prompt` / `prompt_text` | `TEXT` | User-facing display prompt |
| `preview_url` / `image_url` | `TEXT` | High-res image URL in Supabase Storage |
| `master_url` / `master_image_url` | `TEXT` | Uncompressed 4K master asset URL |
| `tool_applied` | `TEXT` | Active mode (e.g., `'text_to_image'`, `'background_change'`) |
| `aspect_ratio` | `VARCHAR(10)` | `'1:1'`, `'16:9'`, `'9:16'`, `'4:5'`, `'3:4'` |
| `dimensions` | `VARCHAR(20)` | Output resolution (e.g., `'1024x1024'`, `'1344x768'`) |
| `seed` | `BIGINT` | Deterministic generation seed |
| `credits_deducted` | `NUMERIC(6,2)` | Fee deducted (e.g., `2.00`) |
| `is_download_unlocked` | `BOOLEAN` | Paywall status (`true` after 2-credit master unlock) |
| `created_at` | `TIMESTAMPTZ` | ISO 8601 creation timestamp |

#### Example Query:
```typescript
// Fetch user library history on Web:
const { data: history } = await supabase
  .from('jobs')
  .select('*')
  .eq('user_id', user.id)
  .order('created_at', { ascending: false });
```

---

### 3.3 `explore_prompts` & `artworks` (Unified Community Feed)
> **Full Parity:** Web team queries `artworks` or `explore_prompts`. A two-way PostgreSQL trigger automatically synchronizes rows and column names across both tables with `user_id` preserved.

| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | `UUID / TEXT PRIMARY KEY` | Artwork unique ID |
| `user_id` / `author_id` | `UUID REFERENCES auth.users` | Creator's user ID (enables Profile sync) |
| `title` | `TEXT NOT NULL` | Artwork title (e.g., `"Cyber Ronin in Rain"`) |
| `prompt` / `masked_summary` | `TEXT NOT NULL` | Public style formula (DRM anti-theft protected) |
| `image_url` / `preview_url` | `TEXT NOT NULL` | CDN/Storage image display URL |
| `category` | `TEXT NOT NULL` | `'Cyberpunk'`, `'Anime'`, `'Photorealism'`, `'Product'`, etc. |
| `model` / `model_used` | `TEXT NOT NULL` | `'FLUX.1 Schnell'`, `'SDXL-Lightning'`, `'RealVisXL v4.0'` |
| `aspect_ratio` | `VARCHAR(10)` | `'1:1'`, `'16:9'`, `'9:16'`, `'4:5'` |
| `remixes_count` / `total_remixes` | `INT4` | Community remixes counter |
| `likes_count` | `INT4` | Total likes counter |
| `author_name` | `TEXT` | Display name (e.g., `"Neo Akira"`) |
| `author_handle` | `TEXT` | Handle (e.g., `"@neo_akira"`) |
| `author_avatar` | `TEXT` | Avatar URL or initials |
| `base_remix_fee` | `NUMERIC(4,2)` | Cost to remix (default: `4.00`) |
| `author_royalty_cut` | `NUMERIC(4,2)` | 40% creator royalty cut (default: `1.60`) |
| `is_marketplace_public` | `BOOLEAN` | Public marketplace visibility |
| `created_at` | `TIMESTAMPTZ` | Publication timestamp |

#### Example Publishing on Web (`/studio`):
```typescript
// Publishing an artwork on Web:
await supabase.from('artworks').insert({
  title: 'Cyber Ronin in Rain',
  prompt: 'Cyber Ronin • Wet Neon Street • 85mm Bokeh',
  image_url: direct_image_url,
  category: 'Cyberpunk',
  model: 'FLUX.1 Schnell',
  user_id: user.id, // Sets user identity for Profile parity
  author_handle: user.email.split('@')[0],
});
```

---

### 3.4 `collections` (Unified Bookmark Folders)
> Enables users to organize creations into named folders across Web and Mobile.

| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | `UUID PRIMARY KEY` | Collection folder UUID |
| `user_id` | `UUID REFERENCES auth.users` | Folder owner |
| `name` | `TEXT NOT NULL` | Folder name (e.g., `'Favorites'`, `'Cyberpunk Ideas'`) |
| `description` | `TEXT` | Optional folder description |
| `cover_image_url` | `TEXT` | Display cover thumbnail |
| `item_count` | `INT4` | Auto-calculated items count (via DB trigger) |
| `is_default` | `BOOLEAN` | `true` for system `'All Saved'` folder |
| `is_private` | `BOOLEAN` | `true` (user-private by default) |
| `updated_at` | `TIMESTAMPTZ` | Last folder modification timestamp |

---

### 3.5 `collection_items` (Unified Saved Items Junction)
> Polymorphic junction table that bookmarks any job, explore card, or artwork into a collection folder.

| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | `UUID PRIMARY KEY` | Bookmark record UUID |
| `collection_id` | `UUID REFERENCES collections` | Parent folder UUID |
| `user_id` | `UUID REFERENCES auth.users` | User who saved the item |
| `job_id` | `UUID REFERENCES jobs` | Optional reference if saving from Library |
| `explore_prompt_id` / `artwork_id` | `TEXT / UUID` | Optional reference if saving from Explore Feed |
| `item_id` | `TEXT` | Generic target ID fallback |
| `image_url` | `TEXT NOT NULL` | Thumbnail image URL |
| `created_at` | `TIMESTAMPTZ` | Bookmark timestamp |

#### Example Save-to-Collection on Web:
```typescript
await supabase.from('collection_items').insert({
  collection_id: folderId,
  user_id: user.id,
  image_url: artwork.image_url,
  artwork_id: artwork.id,
  item_id: artwork.id,
});
```

---

### 3.6 `characters` (Unified AI Avatars & Face-Lock)
> Reusable characters with reference photos for InstantID Face-Lock consistency.

| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | `UUID PRIMARY KEY` | Character profile UUID |
| `user_id` | `UUID REFERENCES auth.users` | Owner user ID |
| `name` | `TEXT NOT NULL` | Character name (e.g., `'Sarah Connor'`) |
| `gender` | `TEXT` | `'female'`, `'male'`, `'non-binary'` |
| `reference_photo_urls` | `TEXT[]` | 1–3 facial reference URLs in Supabase Storage |
| `created_at` | `TIMESTAMPTZ` | Character creation timestamp |

---

## 4. Crucial Business Rules (Match Flutter Flow)

1. **Rule 1: Download Paywall Gate (2 Credits)**
    - Cloud Library shows creations for free.
    - Tapping "Download 4K Master" opens the 2-Credit Paywall modal.
    - Check `job.is_download_unlocked`:
        - If `true`: Re-download is **100% Free** (Idempotent).
        - If `false`: Deduct 2 Credits from wallet, update `is_download_unlocked = true`, and trigger lossless download.

2. **Rule 2: Creator Royalty on Remix**
    - In Explore feed, tapping "Use as Prompt" loads `masked_summary` into the Studio input, and attaches `remixed_from_prompt_id = card.id`.
    - On generation, pass `remixed_from_prompt_id` to `/generation/dispatch` so the backend credits the author their royalty split.

3. **Rule 4: Secret Formula DRM & Anti-Theft**
    - **Never** render or send the raw 700+ character master prompt to public Explore cards or unauthenticated web inspectors.
    - Public cards and previews only expose `masked_summary`.
    - In Studio, the user sees their clean prompt in the input box, while the Gemini-expanded master recipe is dispatched to FLUX under the hood.

---

## 5. Complete Frontend UI & User Flow Parity Guide (Mobile ↔ Web)

The Web application must reflect the **exact same UI structure, screens, user flows, and state behaviors** as the Flutter mobile app.

### 5.1 Design System & Theme Tokens
| Token Name | Hex Code | Purpose |
| :--- | :--- | :--- |
| `AppColors.primary` | `#6366F1` (Indigo) | Primary buttons, active tabs, magic enhance highlights |
| `AppColors.primaryDark` | `#4F46E5` | Hover/Pressed states on primary buttons |
| `AppColors.surface` | `#121218` | Main card backgrounds, modal sheets, studio canvas |
| `AppColors.surfaceLight` | `#1E1E2A` | Input fields, secondary cards, pill badges |
| `AppColors.background` | `#0B0B0F` | Deep dark page background |
| `AppColors.border` | `#2E2E3E` | Card borders, dividers, outlines |
| `AppColors.textPrimary` | `#FFFFFF` | Main headings, active inputs |
| `AppColors.textSecondary` | `#94A3B8` | Subtitles, helper text, inactive chips |
| `AppColors.textMuted` | `#64748B` | Timestamps, counters, placeholder text |
| `AppColors.accentSuccess` | `#10B981` | Unlocked downloads, face-lock active, credits refund |
| `AppColors.accentWarning` | `#F59E0B` | Low credits warning, disarmed status |
| `AppColors.accentError` | `#EF4444` | Server error sheets, validation errors, liked heart |
| `AppColors.copilotAccent` | `#38BDF8` (Sky Blue) | Prompt Chat Copilot icon and badges |
| `AppColors.purpleAccent` | `#A855F7` (Purple) | Subject Lock action icon and badges |

---

### 5.2 Screen 1: Explore Community Feed (`/explore`)
- **Layout:** Masonry grid (Pinterest-style) with category tabs at the top (`All`, `Cyberpunk`, `Photorealism`, `Anime`, `Product`, `Character`, `Architecture`, `3D Render`).
- **Feed Card Elements:**
    - Full-bleed image preview.
    - Category pill in top-left corner.
    - Like heart button & counter in top-right corner.
    - Bottom info: Author avatar, author name/handle, remix counter.
- **Card Detail Drawer / Modal (On Card Click):**
    - High-res image display with like action.
    - Author profile info and **Creator Royalty Badge** (e.g., `40% Royalty`).
    - **Prompt Recipe Box:** Displays `card.masked_summary` (e.g., `"Cyber Ronin • Wet Neon Street • 85mm Bokeh • [Secret Recipe Encrypted]"`).
    - **Dual Action Buttons:**
        1. **`Use as Prompt`**: Copies `masked_summary` to Studio prompt input, records `remixed_from_prompt_id = card.id`, and routes to `/studio`.
        2. **`Use as Ref`**: Injects card's image into Studio reference image slot, and routes to `/studio`.
        3. **`⚡ Remix on My Photo`**: Prompts user to upload a selfie/photo, sets Subject-Lock, and routes to Studio.

---

### 5.3 Screen 2: AI Creation Studio (`/studio`)
- **Consistent Character / Face Lock Bar (Top):**
    - Profile selector with 3-angle face reference chips (Front, 45°, Profile).
    - When selected, automatically activates **InstantID Face-Lock (Tier 1)**.
- **Multi-Reference Photo Slots (`+ Add reference images`):**
    - Up to 3 reference photo chips for style/pose transfer.
- **Interactive Prompt Box:**
    - **Engine Selector Chip:** Dropdown allowing user to select between Gemini 2.5 Flash, Groq Llama 3.3, Claude 3.5 Sonnet.
    - **Prompt Textarea:** Clean user prompt draft with live character counter.
    - **Action Toolbar (Bottom Right of Box):**
        - `Icons.chat_bubble_outline` → Opens **Prompt Chat Copilot** drawer for conversational prompt tweaks.
        - `Icons.copy_rounded` → Copies the prompt text to clipboard.
        - `Icons.manage_search_rounded` → Opens **Prompt Lifecycle Inspector** modal (What you typed vs Gemini refined vs Sent to FLUX).
        - **`✨ Enhance` Button:** Calls `/api/v1/prompt-engineering/expand`.
- **Option A: "AI Master Formula Armed" Indicator:**
    - When enhanced, the input box keeps the user's clean prompt, while a sleek pill badge appears underneath:
      `✨ AI Master Formula Armed • Ready for FLUX generation [✕]`
    - Clicking `[✕]` disarms the enhancement and reverts to raw prompt mode.
- **Studio Controls Bar:**
    - **Aspect Ratio Selector:** `Auto`, `1:1` (Square), `9:16` (Story/Reel), `16:9` (Widescreen), `4:5` (Portrait).
    - **Model Selector:** `FLUX.1-schnell`, `Gemini Imagen 3`, `ChatGPT DALL-E 3`.
    - **Dynamic Credit Generate Button:** Displays calculated cost (e.g., `Generate ✨ 2 Cr`).
- **Robust Loading Lifecycle & Task Lockdown (Web Parity):**
    - **Task Mutual Exclusion (`isBusy`):**
        - While generation (`isGenerating`), prompt enhance (`isEnhancing`), or background removal is running, all creative configuration inputs (prompt textarea, template chips, reference photo slots, face-lock bar, model pills) are **locked & dimmed (opacity 0.6)**.
        - Secondary task actions are blocked to prevent duplicate credit deduction or concurrency race conditions.
    - **Live Generation Progress Card:**
        - Live progress bar (0% to 100%) showing real-time phase updates from WebSocket (e.g., *"Preparing creative canvas..."*, *"Compiling diffusion latents..."*, *"FLUX.1-schnell denoising 1024x1024 latents..."*, *"✨ Masterpiece ready! Opening Library..."*).
        - Status pill indicates: `Studio locked • Diffusion process in progress`.
    - **Clean Loading Reset:**
        - On success: progress bar hits 100%, displays brief completion confirmation (400ms), and then **resets progress to 0% and phase to empty** before routing to `/library`.
        - On failure (422, 500, network, timeout): loading states **immediately reset to 0%**, credits are auto-refunded, and a clean, user-friendly error sheet displays with plain-language explanations (no raw traceback) and a 1-tap `Retry` button.

---

### 5.4 Screen 3: Cloud Library & Paywall Gate (`/library`)
- **Layout:** Grid/List of the user's personal creations (`myCreations`).
- **Creation Card:**
    - Image preview.
    - User's clean prompt text.
    - Status pill:
        - `Cloud Saved (Free)`: Image is saved in personal cloud storage.
        - `Unlocked (4K Ready)`: Image has been unlocked for lossless 4K export.
    - **Action Button:**
        - If unlocked: **`Re-Download (Free $0.00)`**.
        - If locked: **`Download 4K (2 Cr)`** → Launches **Download Paywall Modal**.
- **Download Paywall Modal:**
    - Displays: Lossless 4K Master Export badge, explanation of 2 Credits ($0.20) fee, and idempotent re-download guarantee.
    - **`Confirm & Unlock (2 Credits)`** button: Deducts 2 Credits from wallet, updates `jobs.is_download_unlocked = true`, and downloads lossless PNG.

#### 5.4.1 MeiGen Creation Detail View (`/library/[jobId]`)
Clicking any creation card in the Library (or Explore feed) opens the **Creation Detail View**:
- **Top Navigation Bar:**
    - Back button (`<`) on top-left.
    - **`+ Publish`** button on top-right: Allows author to publish their creation to the public Explore community feed with creator remix royalties.
- **Hero Image Viewer:** Full-bleed, high-resolution preview with zoom/pan.
- **Actions Row:**
    - Heart / Like toggle button with live count.
    - Download icon (triggers 4K paywall or direct export).
    - Copy prompt button (`📋 Copy`).
    - Three-dot overflow menu (`⋮`).
- **Creator Attribution:** Avatar, author username/handle, creation timestamp.
- **Prompt Description:** Clean user prompt text with expandable `More` / `Less` toggle.
- **Floating Bottom Pill Button:**
    - **`✏️ Edit image`**: Floating bottom action button (rounded pill, high contrast) that triggers the **Edit Actions Sheet**.

#### 5.4.2 Edit Actions Sheet (MeiGen 5-Action Modal)
Triggered by tapping `✏️ Edit image`:
1. **`✨ Describe edits`**:
    - Routes to `/studio`.
    - Injects the selected image into reference slot **`image1`** with remove (`✕`) and add (`+`) controls.
    - Pre-fills the prompt textarea with **`"Edit image1 as follows: "`**.
    - Displays the **`[AI Edit]`** badge in the prompt toolbar.
2. **`✂️ Remove Background`**:
    - Routes to `/tools` with the image pre-loaded into the Zero-Token CPU Background Remover tool.
3. **`🔄 Use prompt`**:
    - Routes to `/studio` with the raw prompt loaded into the textarea (without image attachment).
4. **`🎬 Make Video`**:
    - Routes to Image-to-Video generation tool.
5. **`4K+ Upscale 4K`**:
    - Opens the Lossless 4K Master Export paywall modal.
6. **`Cancel` Button**: Dismisses modal.

---

### 5.5 Screen 4: Wallet & Top-Up (`/wallet`)
- **Balance Card:**
    - Total Credits available.
    - Breakdown: `Purchased Credits` (qualifies for creator remix royalties) vs `Earned Royalty Balance` (creator earnings).
- **Top-Up Packages:**
    - Starter: 50 Credits ($4.99)
    - Pro Creator: 200 Credits ($14.99)
    - Studio Master: 500 Credits ($29.99)
- **Stripe Checkout Webhook:**
    - Handled via `POST /api/v1/wallet/stripe-webhook` which credits `wallets.purchased_balance`.
- **Transaction History:**
    - List of recent credit debits (generations, downloads) and credits (purchases, remix royalties).

---

### 5.6 Screen 5: Creative Skills Toolbox (`/tools`)
The Creative Skills Toolbox hosts zero-token, sub-second generative utility micro-services:

1. **AI Background Remover (`/tools/remove-background`):**
    - Upload image or select from library.
    - 1-tap transparent PNG cutout preview with interactive Before/After wipe slider.
2. **Zero-Token Optical Super-Resolution Upscaler (`/tools/upscale`):**
    - 2X HD and 4X Ultra detail synthesis without AI hallucinations.
3. **AI Background Inpainting (`/tools/ai-background`):**
    - Studio backdrop replacement (pure white, marble, minimalist studio).
4. **AI Canvas Expansion (`/tools/ai-expand`):**
    - Outpainting to target ratios (`16:9`, `9:16`, `4:5`).
5. **Portrait Relighting & Depth Bokeh (`/tools/edit-preset`):**
    - Studio lighting presets (Golden Hour, Cyberpunk Neon, Studio Softbox).
6. **Magic Object Eraser (`/tools/remove-object`):**
    - Sub-second neural inpainting (LaMa FFC engine).
    - Erases unwanted people, wires, text, or objects seamlessly.
7. **Vintage Photo Colorizer (`/tools/colorize`):**
    - Dual-Decoder (DDColor) neural color restoration.
    - Converts B&W or historical photos to full vibrant color while preserving 100% native sharpness.

---

### 5.7 Detailed UI/UX Specification for New Creative Tools

#### 5.7.1 Magic Object Eraser UI Component (`MagicObjectEraser`)
```
+-----------------------------------------------------------+
| [< Back]              Magic Object Eraser        [Save ⬇] |
+-----------------------------------------------------------+
|                                                           |
|             +-------------------------------+             |
|             |                               |             |
|             |          [ Image ]            |             |
|             |       ~ ~ ~ ~ ~ ~ ~ ~         |             |
|             |      ( Neon Mask Path )       |             |
|             |       ~ ~ ~ ~ ~ ~ ~ ~         |             |
|             |                               |             |
|             +-------------------------------+             |
|                                                           |
+-----------------------------------------------------------+
|  Brush Size:  ( - ) =====[ O ]====== ( + )  [ 35px ]      |
+-----------------------------------------------------------+
|  [ ↶ Undo ]   [ ↷ Redo ]   [ ✕ Clear Mask ]               |
+-----------------------------------------------------------+
|              [ ⚡ ERASE OBJECT (Sub-Second) ]              |
+-----------------------------------------------------------+
```

##### Step-by-Step Frontend Workflow:
1. **Interactive Gesture Canvas:**
    - Render the target image inside an HTML5 `<canvas>` (Next.js) or `CustomPaint` / `GestureDetector` (Flutter).
    - As the user drags across the image, draw smooth quadratic bezier curves in semi-transparent violet (`rgba(139, 92, 246, 0.5)`).
    - Display a circular cursor indicator matching the exact brush diameter.
2. **Toolbar Controls:**
    - **Brush Slider:** Dynamic range from `10px` to `80px`.
    - **Undo / Redo:** Maintain a stack of stroke paths.
    - **Clear:** Empties the stroke stack.
3. **Generating the Mask for Backend:**
    - Create an offscreen canvas at the exact **`naturalWidth` x `naturalHeight`** of the original image.
    - Fill background with solid black: `#000000`.
    - Draw all user strokes with solid white: `#FFFFFF`.
    - Export mask as PNG base64: `data:image/png;base64,...`.
4. **API Dispatch:**
    - Send `POST /api/v1/tools/remove-object` with `{ image_url: "...", mask_base64: "data:image/png;base64,..." }`.
    - Shows loading shimmer overlay (~900ms).
5. **Interactive Before / After Wipe Slider:**
    - Upon completion, replace image with an interactive split comparison widget:
        - Left side: Original Image.
        - Right side: Inpainted Result.
        - Draggable vertical divider handle.

---

#### 5.7.2 Vintage Photo Colorizer UI Component (`PhotoColorizer`)
```
+-----------------------------------------------------------+
| [< Back]            Vintage Photo Colorizer       [Save ⬇] |
+-----------------------------------------------------------+
|                                                           |
|             +-------------------------------+             |
|             |           |                   |             |
|             |  Original |   Vibrant Color   |             |
|             |   (B & W) |    (Restored)     |             |
|             |           |<||>               |             |
|             |           |                   |             |
|             +-------------------------------+             |
|                   < Drag to Compare >                     |
|                                                           |
+-----------------------------------------------------------+
|  Saturation:  [ 0.8x Muted ]  [ 1.0x Natural ]  [ 1.2x Rich ★ ] |
+-----------------------------------------------------------+
|             [ 🎨 RESTORE NATURAL COLORS ]                 |
+-----------------------------------------------------------+
```

##### Step-by-Step Frontend Workflow:
1. **Initial State:** Display input B&W image.
2. **Action Trigger:** User taps **`[ 🎨 Restore Natural Colors ]`**.
3. **API Dispatch:**
    - Call `POST /api/v1/tools/colorize` with `{ image_url: "...", saturation: 1.2 }`.
    - Server processes in ~1,090ms.
4. **Interactive Comparison Slider:**
    - Renders a two-layer split view with an interactive center divider handle.
    - Dragging the handle reveals the transformation from historical monochrome to full lifelike color.
5. **Saturation Fine-Tuning:**
    - User can tap presets (`0.8x`, `1.0x`, `1.2x`, `1.4x`) to instantly re-render or tweak intensity.
6. **Export:** 1-tap download lossless PNG or save directly to user collections.

---

## 6. Frontend Developer Integration Code Snippets

### 6.1 Next.js 15 (TypeScript) Example Helper

```typescript
// lib/api/tools.ts
const BACKEND_BASE = process.env.NEXT_PUBLIC_BACKEND_URL || "http://192.168.29.26:8000/api/v1";

interface ToolResponse {
  task_id: string;
  status: string;
  output_url: string;
  image_url: string;
  latency_ms?: number;
}

// 1. Magic Object Eraser
export async function eraseObject(
  imageUrl: string,
  maskBase64: string,
  token?: string
): Promise<ToolResponse> {
  const res = await fetch(`${BACKEND_BASE}/tools/remove-object`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Bypass-Tunnel-Reminder": "true",
      ...(token ? { Authorization: `Bearer ${token}` } : {})
    },
    body: JSON.stringify({
      image_url: imageUrl,
      mask_base64: maskBase64
    })
  });
  if (!res.ok) throw new Error(`Object eraser failed: ${res.statusText}`);
  return res.json();
}

// 2. Photo Colorizer
export async function colorizePhoto(
  imageUrl: string,
  saturation: number = 1.2,
  token?: string
): Promise<ToolResponse> {
  const res = await fetch(`${BACKEND_BASE}/tools/colorize`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Bypass-Tunnel-Reminder": "true",
      ...(token ? { Authorization: `Bearer ${token}` } : {})
    },
    body: JSON.stringify({
      image_url: imageUrl,
      saturation: saturation
    })
  });
  if (!res.ok) throw new Error(`Colorizer failed: ${res.statusText}`);
  return res.json();
}
```

---

### 6.2 Frontend Environment Configuration Guide

#### For Web (Next.js / Vite / React) in `.env.local`:
```env
# Live Production / Staging Server:
NEXT_PUBLIC_BACKEND_URL=http://200.141.14.171:8085/api/v1

# LAN Wi-Fi (Optional for local testing):
# NEXT_PUBLIC_BACKEND_URL=http://192.168.29.26:8000/api/v1
```

#### For Mobile (Flutter) in `.env`:
```env
# Live Production / Staging Server:
BACKEND_URL=http://200.141.14.171:8085/api/v1
API_BASE_URL=http://200.141.14.171:8085/api/v1

# Optional LAN Wi-Fi:
# BACKEND_URL=http://192.168.29.26:8000/api/v1
# API_BASE_URL=http://192.168.29.26:8000/api/v1
```

