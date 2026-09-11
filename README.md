# CraftAI Studio — Mobile App (Flutter)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Auth%20%7C%20DB%20%7C%20Storage-3ECF8E?logo=supabase)](https://supabase.com)
[![FastAPI](https://img.shields.io/badge/Backend-FastAPI-009688?logo=fastapi)](https://fastapi.tiangolo.com)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

High-performance Flutter mobile application for **CraftAI Studio** — the next-generation AI media creation and prompt marketplace platform. Built with Flutter 3.x, GetX reactive state management, and Supabase integration.

---

## 📱 App Architecture & Screens

```
lib/
├── core/
│   ├── constants/            # AppColors, AppStrings
│   ├── services/             # SupabaseService (Auth, Client, Realtime)
│   └── theme/                # Dark neon cyber-luxe theme (Outfit font)
├── data/
│   └── models/               # ExploreCardModel, JobModel, WalletModel, CharacterModel
├── features/
│   ├── shell/                # Navigation shell with real-time credit header
│   ├── explore/              # Community prompt feed, pgvector recommendations
│   ├── studio/               # Consistent character creation studio with face locks
│   ├── library/              # Free cloud gallery + 2-credit 4K master download gating
│   └── wallet/               # Dual-balance ledger & creator royalties payout
└── main.dart                 # Responsive root with ScreenUtil (390×844dp baseline)
```

---

## 🌟 Core Feature Implementations

### 1. Explore Feed (`features/explore`)
- **Interactive Feed**: Responsive staggered cards showing creator avatars, masked prompt summaries, like counts, and remix counters.
- **Category Filter Chips**: Instant category switching (All, Cinematic, Anime, 3D Render, Photorealism, Cyberpunk).
- **Dual-Action Workflows**:
  - `Use as Prompt`: Injects the card prompt directly into Creation Studio.
  - `Use as Ref`: Locks the image as reference for Image-to-Image / Consistent Character workflow.
- **"More Like This" Bottom Sheet**: Triggers Supabase `pgvector` HNSW cosine similarity recommendations based on prompt embeddings.

### 2. Creation Studio (`features/studio`)
- **Consistent Character Face Lock**: Upload 3-angle references (Front, 45°, Side) with InstantID Apache 2.0 facial embedding extraction.
- **In-Prompt AI Controls**:
  - `✨ Enhance`: Gemini 1.5 Flash magic expander for detailed prompt augmentation.
  - `🎯 AI Edit`: Subject/background segmentation lock for precise inpainting.
- **Generation Parameters**:
  - Batch count slider (`- 1 / 4 +`).
  - Seed lock toggle (`🔒 / 🎲`).
  - Aspect ratio chips (`Auto`, `1:1`, `9:16`, `16:9`, `4:5`).
  - Output quality selector (`2K / 4K`).
- **Dynamic Action Button**: Computes real-time credit deductions (e.g. `Generate ✨ (1.0 Cr)`).

### 3. Cloud Library & Paywall Gate (`features/library`)
- **Free In-App Gallery**: Browse all generated images at high resolution without cost.
- **Idempotent 2-Credit Pay-to-Download**:
  - Deducts flat 2 credits only on the first download unlock.
  - Subsequent downloads for the same creation generate 15-minute signed Supabase Storage URLs for free (`\$0.00`).

### 4. Dual-Balance Wallet & Royalties (`features/wallet`)
- **Separated Balances**:
  - **Purchased Credits**: Acquired via In-App Purchases for generation.
  - **Earned Royalties**: Passive income earned from community prompt remixes.
- **Creator Payout Guard**: Real-time withdrawal eligibility validation (strictly requires minimum balance >= \$25.00).

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `>= 3.3.0`
- Dart SDK `>= 3.3.0`
- Android Studio / Xcode

### Setup & Run
```bash
# Clone the repository
git clone git@github.com:RitutoshAeologic/craftai_studio_mobile.git
cd craftai_studio_mobile

# Install dependencies
flutter pub get

# Run unit tests
flutter test

# Run flutter analyze
flutter analyze

# Launch on connected simulator or physical device
flutter run
```

---

## 🔗 Ecosystem Repositories

- **Backend (FastAPI)**: [craftai_studio_backend](https://github.com/RitutoshAeologic/craftai_studio_backend)
- **Web Frontend (Next.js 15)**: [craftai_studio_web](https://github.com/RitutoshAeologic/craftai_studio_web)
