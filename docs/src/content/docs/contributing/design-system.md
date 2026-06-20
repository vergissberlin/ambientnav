---
title: "Design System"
description: "Brand guidelines, design tokens, and component conventions for the AmbientNav design system."
---

## Location

The design system lives at `design-system/` in the repository root, separate from the Flutter app and firmware:

```
design-system/
├── tokens/
│   ├── colors.css       # Color custom properties
│   ├── typography.css   # Font families, sizes, weights
│   └── spacing.css      # Spacing scale
├── components/          # Component specifications and HTML/CSS previews
├── guidelines/
│   ├── tokens.md        # Token usage documentation
│   └── voice-and-tone.md
└── index.html           # Design system preview page (open in browser)
```

:::tip
To preview the design system in isolation, open `design-system/index.html` directly in your browser. No build step required. All components, color swatches, and typography samples are rendered there for quick reference during development.
:::

## Brand Concept

AmbientNav's visual identity is built around a single metaphor: **a premium automotive instrument cluster at night**.

The UI is not a light-mode app with a dark theme applied on top. It is designed from the ground up for low-ambient-light use while driving. Every design decision — colors that glow, motion that is calm, typography that reads at a glance — follows from this constraint.

> **"Follow the light." / "Folge dem Licht."**

The three signal colors (cyan, magenta, violet) are inspired by the colored LED strip outputs. The UI and the hardware share the same visual language.

## Color Tokens

Defined in `design-system/tokens/colors.css` as CSS custom properties, and mirrored in `app/lib/core/theme/app_theme.dart` as `Color` constants.

### Signal Colors

These are the brand's primary chromatic identity. Each has a specific semantic role — do not use them interchangeably.

| Token name | Hex | Role |
|---|---|---|
| `--color-signal-cyan` | `#00D4FF` | Primary navigation direction, active state, go/proceed |
| `--color-signal-magenta` | `#FF00A0` | Alerts, parking warnings, errors, stop/danger |
| `--color-signal-violet` | `#7B2FFF` | Secondary actions, BLE connection state, informational |

### Background and Surface

| Token name | Hex | Role |
|---|---|---|
| `--color-bg` | `#0A0A0F` | Root background — near-black with a cool blue undertone |
| `--color-surface-1` | `#12121A` | Card and panel backgrounds, slightly elevated above bg |
| `--color-surface-2` | `#1C1C28` | Secondary surfaces, input backgrounds, divider contrast |

### Text

| Token name | Hex | Role |
|---|---|---|
| `--color-text-primary` | `#F0F0F5` | All primary body text, headings, labels |
| `--color-text-secondary` | `#8B8BA0` | Captions, hints, disabled labels, secondary information |

### Glow Shadows

Signal colors are used as colored glow effects on dark surfaces. Do not add grey drop-shadows.

```css
/* Correct: cyan glow on a focused navigation element */
box-shadow: 0 0 12px 2px rgba(0, 212, 255, 0.45);

/* Wrong: grey drop-shadow — looks out of place on dark backgrounds */
box-shadow: 0 4px 8px rgba(0, 0, 0, 0.4);
```

## Typography

### Font Families

| Family | Weights used | Role |
|---|---|---|
| **Space Grotesk** | 500 (Medium), 700 (Bold) | Display text, screen titles, navigation instructions |
| **IBM Plex Sans** | 400 (Regular), 500 (Medium) | Body copy, labels, list items, button text |
| **IBM Plex Mono** | 400 (Regular) | Telemetry readings, metrics, code, sensor values |

Typography is defined in `design-system/tokens/typography.css`:

```css
:root {
  --font-display: 'Space Grotesk', sans-serif;
  --font-body:    'IBM Plex Sans', sans-serif;
  --font-mono:    'IBM Plex Mono', monospace;

  --fw-medium: 500;
  --fw-bold:   700;

  /* Type scale */
  --text-xs:   0.75rem;   /* 12px — captions */
  --text-sm:   0.875rem;  /* 14px — labels */
  --text-base: 1rem;      /* 16px — body */
  --text-lg:   1.125rem;  /* 18px — subheadings */
  --text-xl:   1.25rem;   /* 20px — section titles */
  --text-2xl:  1.5rem;    /* 24px — screen titles */
  --text-4xl:  2.25rem;   /* 36px — large speed readout */
}
```

In Flutter, reference `AppTheme.fontDisplay`, `AppTheme.fontBody`, and `AppTheme.fontMono` — never hard-code font family strings.

## Spacing Scale

Base unit: **4 px**. All spacing values are multiples of this base.

| Token | Value | Common use |
|---|---|---|
| `--space-1` | 4 px | Icon inner padding, tight gaps |
| `--space-2` | 8 px | List item padding, inline gaps |
| `--space-3` | 12 px | Small card padding |
| `--space-4` | 16 px | Standard section padding |
| `--space-6` | 24 px | Card padding, between groups |
| `--space-8` | 32 px | Section gaps |
| `--space-12` | 48 px | Large section spacing |
| `--space-16` | 64 px | Screen-level margins |
| `--space-24` | 96 px | Generous hero spacing |

In Flutter: `AppTheme.spacingSm` (8), `AppTheme.spacingMd` (16), `AppTheme.spacingLg` (24), `AppTheme.spacingXl` (32).

## Component Overview

### Button

Three variants:

| Variant | Background | Border | Text color | Use |
|---|---|---|---|---|
| `primary` | `--color-signal-cyan` | none | `#0A0A0F` (dark) | Main call-to-action |
| `ghost` | transparent | `--color-signal-cyan` (1 px) | `--color-signal-cyan` | Secondary actions |
| `danger` | `--color-signal-magenta` | none | `#F0F0F5` | Destructive actions, alerts |

Minimum tap target: 44 × 44 px (WCAG 2.5.8). Border radius: 8 px.

### Badge

Small status pill. Background uses a 15% opacity version of the signal color, border uses the full signal color at 40% opacity.

```css
.badge--cyan    { background: rgba(0, 212, 255, 0.15); border-color: rgba(0, 212, 255, 0.4); }
.badge--magenta { background: rgba(255, 0, 160, 0.15); border-color: rgba(255, 0, 160, 0.4); }
.badge--violet  { background: rgba(123, 47, 255, 0.15); border-color: rgba(123, 47, 255, 0.4); }
```

### Card

Container for grouped content.

```css
.card {
  background: var(--color-surface-1);
  border: 1px solid rgba(240, 240, 245, 0.06); /* subtle separator */
  border-radius: 12px;
  padding: var(--space-6);
}
```

Elevated cards (modals, bottom sheets) use `--color-surface-2` as background.

### LightStrip

A horizontal animated bar that previews the active LED effect — used in the `LedSettingsPage` and `LedConfigForm` organism. In Flutter, implemented as a `CustomPainter` that renders the current `LedConfig` as a gradient or animated sequence of colored circles, mirroring what the physical LED strip would show.

## Design Principles

### Glow, Not Shadow

Depth on dark backgrounds is created with **colored box-shadows** (cyan/magenta/violet glow), not grey drop-shadows. Grey shadows read as "desktop UI" and break the instrument cluster aesthetic.

```dart
// In Flutter — correct glow approach
decoration: BoxDecoration(
  boxShadow: [
    BoxShadow(
      color: AppTheme.signalCyan.withOpacity(0.35),
      blurRadius: 16,
      spreadRadius: 2,
    ),
  ],
),
```

### Calm Motion

The driver is navigating. Motion must not distract.

- Animations: `opacity` + `Transform.translate` only. No scale bounces, no rotation animations.
- Duration: 200–300 ms for state transitions; 800–1200 ms for ambient pulses.
- Easing: `Curves.easeOut` for entrances, `Curves.easeIn` for exits.
- No spring physics (`SpringSimulation`, `ElasticCurve`) in any navigating-mode UI.

### Lucide Icons

Use [Lucide](https://lucide.dev/) icons throughout:

- Style: outline, **2 px stroke weight**, never filled.
- Size: 20 px for UI icons, 24 px for navigation controls.
- Do not mix Lucide with Material Icons or Cupertino icons in the same screen.

The `lucide_flutter` package is already declared in `app/pubspec.yaml`.

### No Hard-coded Colors in Widgets

Every color reference in Flutter code must come from `AppTheme`:

```dart
// Correct
color: AppTheme.signalCyan

// Wrong — will not update if the token changes, breaks theming
color: const Color(0xFF00D4FF)
```

Same rule applies to spacing: use `AppTheme.spacingMd` instead of `16.0`.

## Using Tokens in Flutter

```dart
// core/theme/app_theme.dart
import 'package:flutter/material.dart';

abstract final class AppTheme {
  // Signal colors
  static const signalCyan    = Color(0xFF00D4FF);
  static const signalMagenta = Color(0xFFFF00A0);
  static const signalViolet  = Color(0xFF7B2FFF);

  // Backgrounds and surfaces
  static const backgroundDeep = Color(0xFF0A0A0F);
  static const surface1       = Color(0xFF12121A);
  static const surface2       = Color(0xFF1C1C28);

  // Text
  static const textPrimary   = Color(0xFFF0F0F5);
  static const textSecondary = Color(0xFF8B8BA0);

  // Typography
  static const fontDisplay = 'Space Grotesk';
  static const fontBody    = 'IBM Plex Sans';
  static const fontMono    = 'IBM Plex Mono';

  // Spacing
  static const spacingXs  = 4.0;
  static const spacingSm  = 8.0;
  static const spacingMd  = 16.0;
  static const spacingLg  = 24.0;
  static const spacingXl  = 32.0;
  static const spacing2xl = 48.0;
}
```

## Adding a New Token

Adding a token requires updating three files to keep CSS, Flutter, and documentation in sync:

1. **`design-system/tokens/colors.css`** (or `typography.css` / `spacing.css`): Add the CSS custom property.
2. **`app/lib/core/theme/app_theme.dart`**: Add the corresponding Dart constant.
3. **`design-system/guidelines/tokens.md`**: Document the token name, value, and intended use.

Never introduce a token in only one place. Inconsistency between the CSS design system and the Flutter implementation is a bug.

## Bilingual Copy Policy

All UI strings appear in both English (`app_en.arb`) and German (`app_de.arb`). The rules:

- **English is the source of truth.** Add new strings to `app_en.arb` first.
- **Do not commit machine-translated German copy directly.** Machine translation is used only as a starting point in the CI translation workflow. Human review is required before German strings reach the app.
- If you need a new string added urgently (e.g., for a bug fix), add the English string and open the corresponding ARB key in `app_de.arb` with the English text as a temporary placeholder. Tag the PR with the `needs-translation` label.
- Coordinate with maintainers on any copy that involves technical automotive terms — these often require domain-specific translation choices.
