# CraftAI Studio — Design System Tokens & Color Theme Specification
> **Handoff Document for Web Development Team**  
> **Source of Truth:** Mobile Application (`lib/core/constants/app_colors.dart` & `lib/core/theme/app_theme.dart`)  
> **Font Family:** `Inter`, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif

---

## 1. Brand Identity & Constant Accents
These accent colors are persistent across all themes (Light & Dark).

| Token Name | Hex Code | RGB | Purpose / Usage |
| :--- | :--- | :--- | :--- |
| **`brand-primary`** | `#6366F1` | `99, 102, 241` | Main brand color (Cosmic Indigo), CTA buttons, active tabs |
| **`brand-secondary`** | `#8B5CF6` | `139, 92, 246` | Cyber Violet, AI badges, accent highlights |
| **`brand-vip`** | `#A855F7` | `168, 85, 247` | Pro / Royalty / Premium membership tiers |
| **`accent-cyan`** | `#06B6D4` | `6, 182, 212` | Studio Copilot, quick modifiers, generation state |
| **`accent-emerald` / `success`** | `#10B981` | `16, 185, 129` | Success states, wallet credit additions, completed jobs |
| **`accent-amber` / `warning`** | `#F59E0B` | `245, 158, 11` | Credit warnings, processing alerts, pending states |
| **`accent-crimson` / `error`** | `#EF4444` | `239, 68, 68` | Failed jobs, destructive actions, validation errors |

---

## 2. Signature Gradients

### 🌌 AI Cosmic Gradient (Hero / Primary CTA / Brand Gradient)
```css
background: linear-gradient(135deg, #8B5CF6 0%, #6366F1 50%, #06B6D4 100%);
```
- **Usage:** Main `Generate` button, Pro feature banners, glowing borders.

### 🪟 Glass Specular Gradient (Frosted Glass Overlays)
```css
/* Light Mode */
background: linear-gradient(135deg, rgba(255, 255, 255, 0.5) 0%, rgba(99, 102, 241, 0.1) 100%);

/* Dark Mode */
background: linear-gradient(135deg, rgba(255, 255, 255, 0.1) 0%, rgba(99, 102, 241, 0.05) 100%);
```

---

## 3. Dynamic Theme Tokens (Light vs. Dark)

### A. Default Light Theme: **Luminous Aurora**
Clean, modern, crisp glassmorphism with subtle indigo borders.

| Semantic Token | Hex / RGBA | Description |
| :--- | :--- | :--- |
| `bg-canvas` | `#F8FAFC` | Page background (Slate 50) |
| `bg-surface` | `#FFFFFF` | Main cards, modal sheets, dropdowns |
| `bg-surface-elevated` | `#FFFFFF` | Floating bars, tooltips |
| `bg-surface-muted` | `#F1F5F9` | Secondary cards, inactive chips, prompt canvas |
| `border-default` | `#E2E8F0` | Dividers, card borders (Slate 200) |
| `border-subtle` | `#EEF2F6` | Inner chip borders, subtle outlines |
| `glass-surface` | `rgba(255, 255, 255, 0.73)` | Frosted glass headers, floating navigation |
| `glass-border` | `rgba(99, 102, 241, 0.20)` | Glass cards border with indigo tint |
| `text-primary` | `#0F172A` | Headings, primary text (Slate 900) |
| `text-secondary` | `#475569` | Body text, labels (Slate 600) |
| `text-muted` | `#64748B` | Subtitles, helper text (Slate 500) |
| `text-tertiary` | `#94A3B8` | Placeholders, disabled text (Slate 400) |

---

### B. Default Dark Theme: **Deep Obsidian**
Deep OLED dark theme designed for AI artwork display.

| Semantic Token | Hex / RGBA | Description |
| :--- | :--- | :--- |
| `bg-canvas` | `#0B0D14` | Deep obsidian page background |
| `bg-surface` | `#161B26` | Card background, bottom sheets |
| `bg-surface-elevated` | `#121622` | Modal dialogues, navigation bars |
| `bg-surface-muted` | `#1F2636` | Inactive chips, code/prompt containers |
| `border-default` | `#283245` | Standard card border, dividers |
| `border-subtle` | `#1C2230` | Inner subtle dividers |
| `glass-surface` | `rgba(22, 27, 38, 0.80)` | Frosted dark glass navbar/sidebar |
| `glass-border` | `rgba(255, 255, 255, 0.18)` | Specular border highlight |
| `text-primary` | `#F8FAFC` | Headings, primary text (Slate 50) |
| `text-secondary` | `#94A3B8` | Secondary labels (Slate 400) |
| `text-muted` | `#64748B` | Timestamp, helper text (Slate 500) |
| `text-tertiary` | `#475569` | Disabled text, icons (Slate 600) |

---

## 4. Radii & Geometry (Pinterest-Style Aesthetic)
- **Filter Chips / Modifiers:** `12px` - `14px` (`rounded-xl` / Pinterest corner curve)
- **Cards & Grids:** `16px` - `20px` (`rounded-2xl`)
- **Buttons & Action Bars:** `12px` - `16px` (`rounded-xl`)
- **Floating Pills / FABs:** `9999px` (`rounded-full`)

---

## 5. Web Implementation Snippets

### A. CSS Custom Properties (`styles/theme.css`)
```css
:root {
  /* Brand Accents */
  --brand-primary: #6366F1;
  --brand-secondary: #8B5CF6;
  --brand-vip: #A855F7;
  --accent-cyan: #06B6D4;
  --accent-success: #10B981;
  --accent-warning: #F59E0B;
  --accent-error: #EF4444;

  /* AI Gradients */
  --grad-ai-cosmic: linear-gradient(135deg, #8B5CF6 0%, #6366F1 50%, #06B6D4 100%);
  --grad-glass-specular: linear-gradient(135deg, rgba(255, 255, 255, 0.5) 0%, rgba(99, 102, 241, 0.1) 100%);

  /* Light Theme (Luminous Aurora) */
  --bg-canvas: #F8FAFC;
  --bg-surface: #FFFFFF;
  --bg-surface-elevated: #FFFFFF;
  --bg-surface-muted: #F1F5F9;
  --border-default: #E2E8F0;
  --border-subtle: #EEF2F6;
  --glass-surface: rgba(255, 255, 255, 0.73);
  --glass-border: rgba(99, 102, 241, 0.20);
  --text-primary: #0F172A;
  --text-secondary: #475569;
  --text-muted: #64748B;
  --text-tertiary: #94A3B8;
}

[data-theme="dark"],
.dark {
  /* Dark Theme (Deep Obsidian) */
  --bg-canvas: #0B0D14;
  --bg-surface: #161B26;
  --bg-surface-elevated: #121622;
  --bg-surface-muted: #1F2636;
  --border-default: #283245;
  --border-subtle: #1C2230;
  --glass-surface: rgba(22, 27, 38, 0.80);
  --glass-border: rgba(255, 255, 255, 0.18);
  --text-primary: #F8FAFC;
  --text-secondary: #94A3B8;
  --text-muted: #64748B;
  --text-tertiary: #475569;
}
```

---

### B. Tailwind CSS Config (`tailwind.config.js`)
```javascript
/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: ['class', '[data-theme="dark"]'],
  theme: {
    extend: {
      colors: {
        brand: {
          primary: 'var(--brand-primary)',
          secondary: 'var(--brand-secondary)',
          vip: 'var(--brand-vip)',
        },
        accent: {
          cyan: 'var(--accent-cyan)',
          success: 'var(--accent-success)',
          warning: 'var(--accent-warning)',
          error: 'var(--accent-error)',
        },
        surface: {
          canvas: 'var(--bg-canvas)',
          DEFAULT: 'var(--bg-surface)',
          elevated: 'var(--bg-surface-elevated)',
          muted: 'var(--bg-surface-muted)',
        },
        border: {
          DEFAULT: 'var(--border-default)',
          subtle: 'var(--border-subtle)',
          glass: 'var(--glass-border)',
        },
        content: {
          primary: 'var(--text-primary)',
          secondary: 'var(--text-secondary)',
          muted: 'var(--text-muted)',
          tertiary: 'var(--text-tertiary)',
        }
      },
      backgroundImage: {
        'ai-cosmic': 'var(--grad-ai-cosmic)',
        'glass-specular': 'var(--grad-glass-specular)',
      },
      borderRadius: {
        'chip': '14px',
        'card': '18px',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      }
    }
  }
};
```

---

### C. JSON Tokens (Figma / Style Dictionary)
```json
{
  "brand": {
    "primary": { "value": "#6366F1", "type": "color" },
    "secondary": { "value": "#8B5CF6", "type": "color" },
    "vip": { "value": "#A855F7", "type": "color" },
    "cyan": { "value": "#06B6D4", "type": "color" },
    "success": { "value": "#10B981", "type": "color" },
    "warning": { "value": "#F59E0B", "type": "color" },
    "error": { "value": "#EF4444", "type": "color" }
  },
  "light": {
    "background": { "value": "#F8FAFC", "type": "color" },
    "surface": { "value": "#FFFFFF", "type": "color" },
    "surfaceMuted": { "value": "#F1F5F9", "type": "color" },
    "border": { "value": "#E2E8F0", "type": "color" },
    "textPrimary": { "value": "#0F172A", "type": "color" },
    "textSecondary": { "value": "#475569", "type": "color" },
    "textMuted": { "value": "#64748B", "type": "color" }
  },
  "dark": {
    "background": { "value": "#0B0D14", "type": "color" },
    "surface": { "value": "#161B26", "type": "color" },
    "surfaceMuted": { "value": "#1F2636", "type": "color" },
    "border": { "value": "#283245", "type": "color" },
    "textPrimary": { "value": "#F8FAFC", "type": "color" },
    "textSecondary": { "value": "#94A3B8", "type": "color" },
    "textMuted": { "value": "#64748B", "type": "color" }
  }
}
```

