# UI/UX Integrity & Visual Guard Rules

## 1. Single Icon Policy (Zero Emoji Duplication)
- Never mix a Flutter `Icon` widget (`icon: Icon(...)`, `leading: Icon(...)`, `avatar: Icon(...)`) with a Unicode emoji/symbol (`⚡`, `✨`, `✦`, `★`, `🖐️`, etc.) inside the button's `label:` or child `Text`.
- Buttons must use either a Material Icon OR an emoji/text, NEVER both.
- Common anti-patterns to guard against:
  - ❌ `icon: Icon(Icons.bolt)` + `'⚡ Remix in Studio'` -> Results in double bolt `⚡ ⚡`
  - ❌ `icon: Icon(Icons.auto_awesome)` + `'Generate ✨'` -> Results in double sparkle `✨ Generate ✨`
  - ❌ `icon: Icon(Icons.auto_fix_high)` + `'Grab Subject 🖐️'` -> Results in double icons

## 2. Action-to-Intent Verification Protocol
Whenever creating, modifying, or reviewing any button or CTA:
- **Trace the `onPressed` / `onTap` destination**: The label MUST accurately represent the invoked action.
  - "Remix in Lab" / "Remix Artwork" MUST navigate to `RemixChatView` with required arguments (`anchorImageUrl`, `initialPrompt`), NEVER just a generic tab switch to Studio (`switchTab(1)`).
  - "Remove Background" on an existing creation MUST open `BackgroundRemoverView(initialImagePath: ...)` with that image pre-loaded, NEVER a blank switch to the Tools tab.
- **No Dead Callbacks**: Never leave `onPressed: () {}` or `onTap: () {}` in production code.

## 3. Style Chip & Modifier Safeguards
- Any aesthetic chip or prompt modifier (`ActionChip`, `ChoiceChip`, etc.) MUST implement toggle behavior (Tap to Add, Tap to Remove).
- Never allow duplicate additions of the same modifier (e.g., "Cyberpunk Neon, Cyberpunk Neon").
- Visually reflect the active state (highlighted border + checkmark icon) so the user clearly sees which options are active.

## 4. Mandatory Verification Checklist Before Completing Any UI Task
Before ending any turn touching UI:
1. Run `flutter analyze` to ensure 0 errors and 0 warnings.
2. Run `flutter test` to ensure 100% of test suites pass.
3. Check button labels vs icons to ensure zero duplicate symbols.
