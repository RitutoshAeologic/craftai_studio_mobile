# CraftAI Studio — Web & Mobile Feature Parity Sync Update

> **Date:** November 13, 2026  
> **Target Audience:** Next.js 15 Web Engineering Team & Mobile Engineering Team  
> **Master Reference Spec:** [`API_INTEGRATION_SPEC_FOR_WEB.md`](./API_INTEGRATION_SPEC_FOR_WEB.md)  
> **Mobile Reference Branch:** `bugfix/ui-ux-refinements`

---

## ⚡ Executive Summary of Recent UI/UX & Flow Updates

This document summarizes the latest user flows, UI/UX architecture refinements, and newly introduced features in the CraftAI Studio ecosystem to ensure **100% feature and visual parity** between the **Web (Next.js 15)** and **Mobile (Flutter)** apps.

| # | Feature / Flow | Mobile Status | Web Parity Action Required | Reference Section |
| :--- | :--- | :--- | :--- | :--- |
| **1** | **Full-Screen Image Lightbox** | ✅ Shipped | Implement `ImageLightboxModal.tsx` with double-click zoom (1x ↔ 3x), pan, drag/Esc dismiss, and top/bottom overlay controls. | **§1 below & Spec §5.2.1, §6.3** |
| **2** | **Explore 3-Dropdown Filter Row** | ✅ Shipped | Replace category pill strip with 3 side-by-side dropdowns (`Categories`, `Models`, `Aspect Ratio`), active filter count pill, and `Reset All`. | **§2 below & Spec §5.2, §6.4** |
| **3** | **Dynamic Aspect Ratio Grid (Library)** | ✅ Shipped | Render personal creations to their native aspect ratios (`1:1`, `16:9`, `9:16`, `4:5`) instead of fixed square boxes. | **§3 below & Spec §5.4** |
| **4** | **Persistent Creation Detail Header** | ✅ Shipped | Keep `< Back` and `+ Publish` buttons pinned in a sticky top bar so they never scroll away. | **§4 below & Spec §5.4.1** |
| **5** | **Double Header Hierarchy Cleanup** | ✅ Shipped | Single persistent brand header (`CraftAI Studio` + Credits + Avatar); sub-views start with content directly without stacked titles. | **§5 below** |
| **6** | **Razorpay Credit System & Dynamic Packs** | ✅ Shipped | Dynamic packages via Supabase `credit_packages`, Razorpay checkout modal (`checkout.js`), and atomic credit fulfillment RPC. | **§6 below & Spec §9** |

---

## 1. Full-Screen Zoomable Lightbox Modal (`ImageLightboxModal`)

### 1.1 Why This Feature Was Introduced
AI artwork (FLUX, SDXL) features intricate textures, fine lighting, and facial details. Creators need to inspect fine details without fingers blocking their view or losing image context before downloading in 4K or publishing.

### 1.2 UX Behavior & Interactions (1:1 Web Parity)
1. **Trigger Points:**
   - Clicking any artwork image in `/explore` (feed cards or detail drawer).
   - Clicking any image in `/library` (creation card or `/library/[jobId]` detail view).
   - Clicking the subtle `🔍 Pinch & Zoom` affordance badge located in the bottom-right corner of preview images.
2. **Interactive Zoom & Pan:**
   - **Click / Double-Click to Quick Zoom:** Toggles smoothly between **1.0x** (fit screen) and **3.0x** zoom centered directly on the clicked coordinates.
   - **Scroll Wheel / Pinch Zoom:** Continuous smooth magnification from **1.0x** up to **5.0x**.
   - **Pan / Drag:** When zoomed in (>1.05x), users can freely drag the image around to inspect all edges.
3. **Immersive Canvas Mode (Click to Toggle):**
   - Clicking the canvas/backdrop toggles the visibility of the top header and bottom controls so creators can view the artwork without UI clutter.
4. **Dismiss Gestures:**
   - Pressing the **`Esc`** key.
   - Clicking the Close button (`✕`) on the top-left.
   - Dragging down vertically with the mouse or finger (smoothly fades background black opacity to 0 and closes).
5. **Overlay Controls:**
   - **Top Bar:** Close (`✕`), Artwork Title, Model Subtitle (e.g. `FLUX.1 Schnell • Text to Image`), Aspect Ratio pill (`1:1`, `16:9`), Share button, and 4K Download button.
   - **Bottom Bar:** Zoom status badge (e.g. `🔍 Click or Double-Click to Zoom` or `3.0x Zoom | Reset`).

> 💡 **Ready-to-use Next.js 15 Component:** A drop-in React component (`ImageLightboxModal.tsx`) using Tailwind CSS and Lucide icons is provided in **Section 6.3** of `API_INTEGRATION_SPEC_FOR_WEB.md`.

---

## 2. Explore Feed 3-Dropdown Filter Architecture

### 2.1 Why The Layout Was Updated
The horizontal category pill bar required excessive horizontal scrolling and pushed technical filters (Models, Aspect Ratio) below the fold. The new layout unifies all filtering into a single, compact, high-density row.

### 2.2 Layout Breakdown
1. **Integrated Search Bar (Top):**
   - Search input for prompts, artists, and visual styles.
   - Live debounced search with 1-click clear (`✕`).
2. **Three Primary Dropdowns (Side-by-Side):**
   - **Categories:** Dynamic from `GET /api/v1/categories` or Supabase `categories` table (`All`, `Photorealism`, `Anime`, `Cyberpunk`, `3D Render`, `Character`, `Architecture`, `Product`). Default: `All`.
   - **Models:** (`All Models`, `FLUX.1 Schnell`, `SDXL 1.0`, `RealVisXL v4.0`, `Gemini Imagen 3`). Default: `All Models`.
   - **Aspect Ratio:** (`All`, `1:1`, `16:9`, `9:16`, `4:5`). Default: `All`.
3. **Active Filter Badge & Quick Reset:**
   - When any filter differs from default, displays `${activeCount} Active Filter(s)`.
   - A single-click **`Reset All`** button instantly resets all three dropdowns to their defaults.

> 💡 **Ready-to-use Next.js 15 Component:** A drop-in React component (`ExploreFilterBar.tsx`) is provided in **Section 6.4** of `API_INTEGRATION_SPEC_FOR_WEB.md`.

---

## 3. Cloud Library Dynamic Aspect Ratio Grid

### 3.1 Outdated Behavior vs Modern Behavior
- **Previous:** Fixed-height square boxes (`1:1`) that forced letterboxing or cropped non-square images (`16:9` widescreen wallpapers or `9:16` mobile reels).
- **Current Parity:** Dynamic Masonry grid (2 columns on mobile, 3-4 columns on desktop). Each card's container dynamically calculates its height based on `job.aspect_ratio` or native dimensions:
  - `1:1` → Square (1.0 aspect ratio)
  - `16:9` → Widescreen landscape (1.78 aspect ratio)
  - `9:16` → Story / Portrait (0.56 aspect ratio)
  - `4:5` → Social post (0.80 aspect ratio)

### 3.2 Card Elements
- High-res image with subtle rounded corners.
- Category badge & timestamp pill (e.g. `2h ago • 16:9`).
- Status pill: `Cloud Saved (Free)` or `Unlocked (4K Ready)`.
- Quick trash delete button opening the standard deletion confirmation modal.

---

## 4. Persistent Creation Detail Header (`/library/[jobId]`)

When navigating into an artwork's detail view:
- **Pinned Top Bar:** The `< Back` button and the **`+ Publish`** button are pinned inside a persistent sticky top bar.
- **Why:** In previous layouts, scrolling down to inspect long prompt recipes scrolled the back button and publish button off the screen. Pinned headers ensure the user never loses navigation context.

---

## 5. Deletion Flow & Dialog Parity

When deleting an image from the library:
1. **Modal Content:**
   - Title: `Delete Creation?`
   - Description: `"This will permanently delete this image from your cloud library and Supabase storage. This action cannot be undone."`
   - Actions: `Cancel` (outlined) and `Delete` (destructive red/solid).
2. **Backend Execution:**
   - Atomic deletion from Supabase `jobs` table (`job_id = jobId`).
   - Atomic deletion of file from Supabase `user_generations` storage bucket.
   - Optimistic removal from the UI state without a full page reload.

---

## 6. Razorpay Payment Gateway & Dynamic Credit Top-up System

### 6.1 Architecture & Pricing Unit Economics
To eliminate hardcoded packages in mobile app and web frontend, all credit packages are managed dynamically via Supabase table `public.credit_packages`. Changing a package price, credit bonus, or badge in the Supabase Table Editor instantly updates both the Flutter App and Next.js Web without client code deployments.

#### Dynamic Credit Tier Structure
| Package ID | Tier Name | Price (INR) | Base Credits | Bonus Credits | Total Credits | Effective Rate | Badges / Marketing Callouts |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `pack_starter_99` | **Starter** | **₹99** | 100 | 0 | **100** | ₹0.99 / credit | Ideal for casual explorations (~25 standard images) |
| `pack_creator_249` | **Creator** | **₹249** | 250 | 50 | **300** | ₹0.83 / credit | **MOST POPULAR** (20% Bonus Credits) |
| `pack_pro_499` | **Pro Studio** | **₹499** | 600 | 150 | **750** | ₹0.66 / credit | **BEST VALUE** (25% Bonus Credits) |
| `pack_master_999` | **Agency / Master** | **₹999** | 1500 | 500 | **2000** | ₹0.50 / credit | **MEGA SAVER** (33% Bonus Credits, ₹0.50/credit) |

---

### 6.2 Test Credentials & API Configuration
Add these credentials to your web project environment variables (`.env.local`):

```bash
# Razorpay Test Credentials
NEXT_PUBLIC_RAZORPAY_KEY_ID=rzp_test_Tz9TU5AYYJCplL
RAZORPAY_KEY_SECRET=CsXZNE0u7xmfMD4KuKyAv1FW
```

> ⚠️ **Security Rule:** Never expose `RAZORPAY_KEY_SECRET` in client-side Next.js code (`NEXT_PUBLIC_`). The secret is strictly reserved for server-side verification (`/api/verify-payment` route handler or FastAPI backend).

---

### 6.3 Database Schema & Atomic RPC
The database contains the following tables and RPC functions in Supabase:
1. `public.credit_packages`: Stores dynamic packages with active status, base credits, bonus credits, and sort order.
2. `public.payment_transactions`: Stores every Razorpay payment event with transaction ID, amount, and status (`created`, `success`, `failed`, `refunded`).
3. `public.wallet_ledger`: Detailed user passbook ledger documenting all credit additions and deductions.
4. `public.fulfill_credit_purchase(...)`: Security-definer idempotent RPC function that verifies the payment, updates the user's purchased balance, creates the audit record, and updates the passbook ledger in a single atomic transaction.

#### Next.js Calling the Fulfillment RPC:
```typescript
const { data, error } = await supabase.rpc('fulfill_credit_purchase', {
  p_user_id: user.id,
  p_package_id: selectedPackage.id,
  p_amount_paid_inr: selectedPackage.price_inr,
  p_credits_to_add: selectedPackage.credits + selectedPackage.bonus_credits,
  p_razorpay_payment_id: response.razorpay_payment_id,
  p_razorpay_order_id: response.razorpay_order_id || null,
  p_razorpay_signature: response.razorpay_signature || null,
});
```

---

### 6.4 Ready-to-Use Next.js 15 Razorpay Checkout Hook
Create a utility hook `useRazorpayCheckout.ts` to seamlessly launch Razorpay standard checkout:

```typescript
'use client';

import { useState } from 'react';
import { createClient } from '@/utils/supabase/client';

export interface CreditPackage {
  id: string;
  name: string;
  price_inr: number;
  credits: number;
  bonus_credits: number;
  badge?: string;
  is_popular: boolean;
}

export function useRazorpayCheckout() {
  const [isLoading, setIsLoading] = useState(false);
  const supabase = createClient();

  const loadRazorpayScript = (): Promise<boolean> => {
    return new Promise((resolve) => {
      if (typeof window !== 'undefined' && (window as any).Razorpay) {
        return resolve(true);
      }
      const script = document.createElement('script');
      script.src = 'https://checkout.razorpay.com/v1/checkout.js';
      script.onload = () => resolve(true);
      script.onerror = () => resolve(false);
      document.body.appendChild(script);
    });
  };

  const openCheckout = async ({
    pack,
    userEmail,
    userName,
    onSuccess,
    onError,
  }: {
    pack: CreditPackage;
    userEmail: string;
    userName?: string;
    onSuccess: (paymentId: string) => void;
    onError: (error: string) => void;
  }) => {
    setIsLoading(true);
    const scriptLoaded = await loadRazorpayScript();
    if (!scriptLoaded) {
      setIsLoading(false);
      onError('Razorpay SDK failed to load. Please check your internet connection.');
      return;
    }

    const options = {
      key: process.env.NEXT_PUBLIC_RAZORPAY_KEY_ID || 'rzp_test_Tz9TU5AYYJCplL',
      amount: pack.price_inr * 100, // Amount in paise
      currency: 'INR',
      name: 'CraftAI Studio',
      description: `${pack.name} — ${pack.credits + pack.bonus_credits} AI Credits`,
      image: '/logo.png',
      prefill: {
        name: userName || '',
        email: userEmail || '',
      },
      theme: {
        color: '#6366F1', // CraftAI Indigo
      },
      handler: async (response: any) => {
        try {
          const { data: { user } } = await supabase.auth.getUser();
          if (!user) throw new Error('User session not found');

          const { error: rpcError } = await supabase.rpc('fulfill_credit_purchase', {
            p_user_id: user.id,
            p_package_id: pack.id,
            p_amount_paid_inr: pack.price_inr,
            p_credits_to_add: pack.credits + pack.bonus_credits,
            p_razorpay_payment_id: response.razorpay_payment_id,
            p_razorpay_order_id: response.razorpay_order_id || null,
            p_razorpay_signature: response.razorpay_signature || null,
          });

          if (rpcError) throw rpcError;

          setIsLoading(false);
          onSuccess(response.razorpay_payment_id);
        } catch (err: any) {
          setIsLoading(false);
          onError(err.message || 'Failed to credit account after payment.');
        }
      },
      modal: {
        ondismiss: () => {
          setIsLoading(false);
        },
      },
    };

    const rzp = new (window as any).Razorpay(options);
    rzp.open();
  };

  return { openCheckout, isLoading };
}
```

---

## 7. Summary Checklist for Web Engineers

- [ ] Import and integrate `ImageLightboxModal.tsx` in `/explore` and `/library`.
- [ ] Add `🔍 Pinch & Zoom` affordance badge to artwork preview containers.
- [ ] Replace `/explore` pill tabs with the 3-dropdown filter bar (`ExploreFilterBar.tsx`).
- [ ] Ensure `/explore` category queries use `.ilike('category', selectedCategory)` to avoid case-sensitivity drops.
- [ ] Update `/library` grid to dynamic aspect ratio masonry (remove fixed square containers).
- [ ] Pin `< Back` and `+ Publish` buttons in the `/library/[jobId]` header.
- [ ] Integrate dynamic packages from Supabase `credit_packages` table.
- [ ] Implement Razorpay Checkout in `/billing` or `/wallet` using test credentials.
- [ ] Hook `fulfill_credit_purchase` RPC to atomically update user balance upon successful payment.
- [ ] Confirm no client-side `deduct_user_credits` RPC calls are made before `/api/v1/generation/dispatch`.

---
*For full backend schemas, API payloads, and WebSocket definitions, refer directly to [`API_INTEGRATION_SPEC_FOR_WEB.md`](./API_INTEGRATION_SPEC_FOR_WEB.md).*

