---
title: "Design System"
description: "Markenrichtlinien, Design-Tokens und Komponentenkonventionen für das AmbientNav Design System."
---

## Speicherort

Das Design System liegt im Verzeichnis `design-system/` im Repository-Wurzelverzeichnis, getrennt von der Flutter-App und der Firmware:

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
Um das Design System isoliert zu betrachten, öffne `design-system/index.html` direkt im Browser. Kein Build-Schritt erforderlich. Alle Komponenten, Farbmuster und Typografiebeispiele werden dort gerendert — praktisch als schnelle Referenz während der Entwicklung.
:::

## Markenkonzept

AmbientNavs visuelle Identität basiert auf einer einzigen Metapher: **ein hochwertiges Automobil-Instrumentencluster bei Nacht**.

Die Benutzeroberfläche ist keine App im hellen Modus mit einem nachträglich aufgesetzten dunklen Theme. Sie wurde von Grund auf für die Nutzung bei wenig Umgebungslicht während der Fahrt entworfen. Jede Designentscheidung — leuchtende Farben, ruhige Bewegung, Typografie, die auf einen Blick lesbar ist — ergibt sich aus dieser Vorgabe.

> **"Follow the light." / "Folge dem Licht."**

Die drei Signalfarben (Cyan, Magenta, Violett) sind von den farbigen LED-Streifenausgaben inspiriert. Benutzeroberfläche und Hardware teilen dieselbe visuelle Sprache.

## Color Tokens

Definiert in `design-system/tokens/colors.css` als CSS Custom Properties und gespiegelt in `app/lib/core/theme/app_theme.dart` als `Color`-Konstanten.

### Signalfarben

Diese bilden die primäre chromatische Identität der Marke. Jede Farbe hat eine spezifische semantische Rolle — sie dürfen nicht austauschbar eingesetzt werden.

| Token-Name | Hex | Rolle |
|---|---|---|
| `--color-signal-cyan` | `#00D4FF` | Primäre Navigationsrichtung, aktiver Zustand, weiterfahren |
| `--color-signal-magenta` | `#FF00A0` | Warnungen, Einparkhinweise, Fehler, Stopp/Gefahr |
| `--color-signal-violet` | `#7B2FFF` | Sekundäre Aktionen, BLE-Verbindungsstatus, informativ |

### Hintergrund und Oberflächen

| Token-Name | Hex | Rolle |
|---|---|---|
| `--color-bg` | `#0A0A0F` | Wurzel-Hintergrund — nahezu schwarz mit kühlem Blauton |
| `--color-surface-1` | `#12121A` | Karten- und Panel-Hintergründe, leicht über bg erhöht |
| `--color-surface-2` | `#1C1C28` | Sekundäre Oberflächen, Eingabe-Hintergründe, Trennkontrast |

### Text

| Token-Name | Hex | Rolle |
|---|---|---|
| `--color-text-primary` | `#F0F0F5` | Gesamter primärer Fließtext, Überschriften, Labels |
| `--color-text-secondary` | `#8B8BA0` | Bildunterschriften, Hinweise, deaktivierte Labels, sekundäre Infos |

### Glow-Schatten

Signalfarben werden als farbige Leuchteffekte auf dunklen Oberflächen eingesetzt. Graue Schlagschatten sind nicht erlaubt.

```css
/* Correct: cyan glow on a focused navigation element */
box-shadow: 0 0 12px 2px rgba(0, 212, 255, 0.45);

/* Wrong: grey drop-shadow — looks out of place on dark backgrounds */
box-shadow: 0 4px 8px rgba(0, 0, 0, 0.4);
```

## Typografie

### Schriftfamilien

| Familie | Verwendete Schriftschnitte | Rolle |
|---|---|---|
| **Space Grotesk** | 500 (Medium), 700 (Bold) | Display-Text, Screen-Titel, Navigationsanweisungen |
| **IBM Plex Sans** | 400 (Regular), 500 (Medium) | Fließtext, Labels, Listenelemente, Button-Texte |
| **IBM Plex Mono** | 400 (Regular) | Telemetriewerte, Metriken, Code, Sensorwerte |

Die Typografie ist in `design-system/tokens/typography.css` definiert:

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

In Flutter verwendest du `AppTheme.fontDisplay`, `AppTheme.fontBody` und `AppTheme.fontMono` — Schriftfamiliennamen niemals als Hardcode eintragen.

## Abstands-Skala

Basiseinheit: **4 px**. Alle Abstände sind Vielfache dieser Basis.

| Token | Wert | Typische Verwendung |
|---|---|---|
| `--space-1` | 4 px | Innenabstand bei Icons, enge Zwischenräume |
| `--space-2` | 8 px | Listenelement-Padding, Inline-Abstände |
| `--space-3` | 12 px | Padding kleiner Karten |
| `--space-4` | 16 px | Standard-Bereichsabstand |
| `--space-6` | 24 px | Karten-Padding, Abstände zwischen Gruppen |
| `--space-8` | 32 px | Abstände zwischen Bereichen |
| `--space-12` | 48 px | Große Bereichsabstände |
| `--space-16` | 64 px | Seitenweite Ränder |
| `--space-24` | 96 px | Großzügige Hero-Abstände |

In Flutter: `AppTheme.spacingSm` (8), `AppTheme.spacingMd` (16), `AppTheme.spacingLg` (24), `AppTheme.spacingXl` (32).

## Komponentenübersicht

### Button

Drei Varianten:

| Variante | Hintergrund | Rahmen | Textfarbe | Verwendung |
|---|---|---|---|---|
| `primary` | `--color-signal-cyan` | keiner | `#0A0A0F` (dunkel) | Hauptaktion (Call-to-Action) |
| `ghost` | transparent | `--color-signal-cyan` (1 px) | `--color-signal-cyan` | Sekundäre Aktionen |
| `danger` | `--color-signal-magenta` | keiner | `#F0F0F5` | Destruktive Aktionen, Warnungen |

Minimale Tap-Fläche: 44 × 44 px (WCAG 2.5.8). Rahmenradius: 8 px.

### Badge

Kleines Status-Pill. Der Hintergrund verwendet eine 15%ige Deckkraft der Signalfarbe, der Rahmen die volle Signalfarbe bei 40 % Deckkraft.

```css
.badge--cyan    { background: rgba(0, 212, 255, 0.15); border-color: rgba(0, 212, 255, 0.4); }
.badge--magenta { background: rgba(255, 0, 160, 0.15); border-color: rgba(255, 0, 160, 0.4); }
.badge--violet  { background: rgba(123, 47, 255, 0.15); border-color: rgba(123, 47, 255, 0.4); }
```

### Card

Container für gruppierte Inhalte.

```css
.card {
  background: var(--color-surface-1);
  border: 1px solid rgba(240, 240, 245, 0.06); /* subtle separator */
  border-radius: 12px;
  padding: var(--space-6);
}
```

Erhöhte Karten (Modals, Bottom Sheets) verwenden `--color-surface-2` als Hintergrund.

### LightStrip

Eine horizontal animierte Leiste, die den aktiven LED-Effekt vorschaut — verwendet in der `LedSettingsPage` und im `LedConfigForm`-Organismus. In Flutter als `CustomPainter` implementiert, der die aktuelle `LedConfig` als Verlauf oder animierte Sequenz farbiger Kreise rendert und so widerspiegelt, was der physische LED-Streifen zeigen würde.

## Designprinzipien

### Glow statt Schatten

Tiefe auf dunklen Hintergründen wird mit **farbigen Box-Shadows** (Cyan/Magenta/Violett-Leuchteffekt) erzeugt, nicht mit grauen Schlagschatten. Graue Schatten wirken wie Desktop-UI und brechen die Instrumentencluster-Ästhetik.

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

### Ruhige Bewegung

Der Fahrer navigiert. Animationen dürfen nicht ablenken.

- Animationen: ausschließlich `opacity` + `Transform.translate`. Keine Scale-Bounces, keine Rotationsanimationen.
- Dauer: 200–300 ms für Zustandsübergänge, 800–1200 ms für Ambient-Pulse.
- Easing: `Curves.easeOut` für Einblendungen, `Curves.easeIn` für Ausblendungen.
- Keine Federphysik (`SpringSimulation`, `ElasticCurve`) in Navigations-UIs.

### Lucide Icons

Verwende durchgehend [Lucide](https://lucide.dev/)-Icons:

- Stil: Outline, **2 px Strichstärke**, niemals ausgefüllt.
- Größe: 20 px für UI-Icons, 24 px für Navigationssteuerelemente.
- Lucide nicht mit Material Icons oder Cupertino Icons auf demselben Screen mischen.

Das Paket `lucide_flutter` ist bereits in `app/pubspec.yaml` deklariert.

### Keine hardcodierten Farben in Widgets

Jede Farbangabe im Flutter-Code muss aus `AppTheme` stammen:

```dart
// Correct
color: AppTheme.signalCyan

// Wrong — will not update if the token changes, breaks theming
color: const Color(0xFF00D4FF)
```

Dieselbe Regel gilt für Abstände: verwende `AppTheme.spacingMd` statt `16.0`.

## Tokens in Flutter verwenden

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

## Einen neuen Token hinzufügen

Das Hinzufügen eines Tokens erfordert die Aktualisierung von drei Dateien, um CSS, Flutter und Dokumentation synchron zu halten:

1. **`design-system/tokens/colors.css`** (oder `typography.css` / `spacing.css`): CSS Custom Property hinzufügen.
2. **`app/lib/core/theme/app_theme.dart`**: Entsprechende Dart-Konstante hinzufügen.
3. **`design-system/guidelines/tokens.md`**: Token-Name, Wert und vorgesehene Verwendung dokumentieren.

Führe einen Token niemals nur an einer Stelle ein. Inkonsistenz zwischen dem CSS Design System und der Flutter-Implementierung ist ein Bug.

## Zweisprachige Textstrategie

Alle UI-Strings erscheinen sowohl auf Englisch (`app_en.arb`) als auch auf Deutsch (`app_de.arb`). Die Regeln:

- **Englisch ist die einzige Quelle der Wahrheit.** Neue Strings zuerst in `app_en.arb` hinzufügen.
- **Keine maschinell übersetzten deutschen Texte direkt committen.** Maschinelle Übersetzung dient im CI-Übersetzungsworkflow nur als Ausgangspunkt. Vor der Aufnahme in die App ist eine menschliche Überprüfung erforderlich.
- Wenn ein String dringend benötigt wird (z. B. für einen Bugfix), füge den englischen String hinzu und trage den entsprechenden ARB-Key in `app_de.arb` mit dem englischen Text als temporären Platzhalter ein. Versehe den PR mit dem Label `needs-translation`.
- Stimme dich mit den Maintainern ab, wenn Copy technische Kraftfahrzeugbegriffe enthält — diese erfordern oft fachspezifische Übersetzungsentscheidungen.
