---
title: "Design System"
description: "Brand-Guidelines, Design-Tokens und Komponenten-Konventionen für das AmbientNav Design System."
---

## Speicherort

Das Design System befindet sich unter `design-system/` im Repository-Root, getrennt von der Flutter-App und der Firmware:

```
design-system/
├── tokens/
│   ├── colors.css       # CSS Custom Properties für Farben
│   ├── typography.css   # Schriftfamilien, -größen, -gewichte
│   └── spacing.css      # Abstands-Skala
├── components/          # Komponenten-Specs und HTML/CSS-Vorschauen
├── guidelines/
│   ├── tokens.md        # Token-Nutzungsdokumentation
│   └── voice-and-tone.md
└── index.html           # Design System Vorschau-Seite (im Browser öffnen)
```

:::tip
Um das Design System isoliert zu betrachten, öffne `design-system/index.html` direkt im Browser. Kein Build-Schritt erforderlich. Alle Komponenten, Farbmuster und Typografie-Beispiele sind dort zur schnellen Referenz während der Entwicklung gerendert.
:::

## Brand-Konzept

AmbientNavs visuelle Identität basiert auf einer einzigen Metapher: **ein hochwertiges Fahrzeug-Instrumentencluster bei Nacht**.

Die UI ist keine Light-Mode-App mit einem darüber gestülpten Dark Theme. Sie ist von Grund auf für die Nutzung bei geringer Umgebungshelligkeit während der Fahrt konzipiert. Jede Design-Entscheidung — Farben, die leuchten, Bewegungen, die ruhig sind, Typografie, die auf einen Blick lesbar ist — folgt aus dieser Vorgabe.

> **"Follow the light." / "Folge dem Licht."**

Die drei Signalfarben (Cyan, Magenta, Violett) sind von den farbigen LED-Streifen inspiriert. UI und Hardware teilen dieselbe visuelle Sprache.

## Farb-Tokens

Definiert in `design-system/tokens/colors.css` als CSS Custom Properties und gespiegelt in `app/lib/core/theme/app_theme.dart` als `Color`-Konstanten.

### Signalfarben

Diese bilden die chromatische Hauptidentität der Marke. Jede hat eine spezifische semantische Rolle — verwende sie nicht beliebig austauschbar.

| Token-Name | Hex | Rolle |
|---|---|---|
| `--color-signal-cyan` | `#00D4FF` | Primäre Navigationsrichtung, aktiver Zustand, Weiterfahren |
| `--color-signal-magenta` | `#FF00A0` | Warnungen, Einparkalerts, Fehler, Stop/Gefahr |
| `--color-signal-violet` | `#7B2FFF` | Sekundäre Aktionen, BLE-Verbindungsstatus, informativ |

### Hintergrund und Oberflächen

| Token-Name | Hex | Rolle |
|---|---|---|
| `--color-bg` | `#0A0A0F` | Wurzelhintergrund — Fast-Schwarz mit kühlem Blauunterton |
| `--color-surface-1` | `#12121A` | Karten- und Panel-Hintergründe, leicht über bg erhöht |
| `--color-surface-2` | `#1C1C28` | Sekundäre Oberflächen, Input-Hintergründe, Trennlinienkontast |

### Text

| Token-Name | Hex | Rolle |
|---|---|---|
| `--color-text-primary` | `#F0F0F5` | Alle primären Fließtexte, Überschriften, Labels |
| `--color-text-secondary` | `#8B8BA0` | Bildunterschriften, Hinweise, deaktivierte Labels, sekundäre Informationen |

### Leuchtschatten

Signalfarben werden als farbige Leuchteffekte auf dunklen Oberflächen verwendet. Verwende keine grauen Drop-Shadows.

```css
/* Korrekt: Cyan-Leuchten auf einem fokussierten Navigationselement */
box-shadow: 0 0 12px 2px rgba(0, 212, 255, 0.45);

/* Falsch: Grauer Drop-Shadow — wirkt fehl am Platz auf dunklen Hintergründen */
box-shadow: 0 4px 8px rgba(0, 0, 0, 0.4);
```

## Typografie

### Schriftfamilien

| Familie | Verwendete Gewichte | Rolle |
|---|---|---|
| **Space Grotesk** | 500 (Medium), 700 (Bold) | Display-Text, Screen-Titel, Navigationsanweisungen |
| **IBM Plex Sans** | 400 (Regular), 500 (Medium) | Fließtext, Labels, Listeneinträge, Button-Text |
| **IBM Plex Mono** | 400 (Regular) | Telemetriemesswerte, Metriken, Code, Sensorwerte |

Typografie ist in `design-system/tokens/typography.css` definiert:

```css
:root {
  --font-display: 'Space Grotesk', sans-serif;
  --font-body:    'IBM Plex Sans', sans-serif;
  --font-mono:    'IBM Plex Mono', monospace;

  --fw-medium: 500;
  --fw-bold:   700;

  /* Typ-Skala */
  --text-xs:   0.75rem;   /* 12px — Bildunterschriften */
  --text-sm:   0.875rem;  /* 14px — Labels */
  --text-base: 1rem;      /* 16px — Fließtext */
  --text-lg:   1.125rem;  /* 18px — Zwischenüberschriften */
  --text-xl:   1.25rem;   /* 20px — Abschnittstitel */
  --text-2xl:  1.5rem;    /* 24px — Screen-Titel */
  --text-4xl:  2.25rem;   /* 36px — Große Geschwindigkeitsanzeige */
}
```

In Flutter: `AppTheme.fontDisplay`, `AppTheme.fontBody` und `AppTheme.fontMono` referenzieren — niemals Schriftfamiliennamen hartcodieren.

## Abstands-Skala

Basiseinheit: **4 px**. Alle Abstands-Werte sind Vielfache dieser Basis.

| Token | Wert | Typische Verwendung |
|---|---|---|
| `--space-1` | 4 px | Icon-Innenabstand, enge Lücken |
| `--space-2` | 8 px | Listeneintrag-Padding, Inline-Abstände |
| `--space-3` | 12 px | Kleines Karten-Padding |
| `--space-4` | 16 px | Standard-Abschnittsabstand |
| `--space-6` | 24 px | Karten-Padding, zwischen Gruppen |
| `--space-8` | 32 px | Abschnittsabstände |
| `--space-12` | 48 px | Großer Abschnittsabstand |
| `--space-16` | 64 px | Screen-Level-Margins |
| `--space-24` | 96 px | Großzügiger Hero-Abstand |

In Flutter: `AppTheme.spacingSm` (8), `AppTheme.spacingMd` (16), `AppTheme.spacingLg` (24), `AppTheme.spacingXl` (32).

## Komponentenüberblick

### Button

Drei Varianten:

| Variante | Hintergrund | Rahmen | Textfarbe | Verwendung |
|---|---|---|---|---|
| `primary` | `--color-signal-cyan` | keiner | `#0A0A0F` (dunkel) | Hauptaufruf zur Aktion |
| `ghost` | transparent | `--color-signal-cyan` (1 px) | `--color-signal-cyan` | Sekundäre Aktionen |
| `danger` | `--color-signal-magenta` | keiner | `#F0F0F5` | Destruktive Aktionen, Warnungen |

Minimale Tippfläche: 44 × 44 px (WCAG 2.5.8). Border Radius: 8 px.

### Badge

Kleines Status-Pill. Hintergrund verwendet eine 15%-Opacity-Version der Signalfarbe, Rahmen die volle Signalfarbe mit 40% Opacity.

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
  border: 1px solid rgba(240, 240, 245, 0.06); /* subtiler Trenner */
  border-radius: 12px;
  padding: var(--space-6);
}
```

Erhöhte Karten (Modals, Bottom Sheets) verwenden `--color-surface-2` als Hintergrund.

### LightStrip

Eine horizontale animierte Leiste, die den aktiven LED-Effekt in der Vorschau zeigt — verwendet in der `LedSettingsPage` und im `LedConfigForm`-Organism. In Flutter als `CustomPainter` implementiert, der die aktuelle `LedConfig` als Gradient oder animierte Sequenz farbiger Kreise rendert und so widerspiegelt, was der physische LED-Streifen anzeigen würde.

## Design-Prinzipien

### Leuchten, nicht Schatten

Tiefe auf dunklen Hintergründen wird mit **farbigen Box-Shadows** (Cyan/Magenta/Violett-Leuchten) erzeugt, nicht mit grauen Drop-Shadows. Graue Schatten wirken wie "Desktop-UI" und brechen die Instrumentencluster-Ästhetik.

```dart
// In Flutter — korrekter Leuchtansatz
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

Der Fahrer navigiert. Bewegung darf nicht ablenken.

- Animationen: nur `opacity` + `Transform.translate`. Keine Skalierungs-Bounces, keine Rotationsanimationen.
- Dauer: 200–300 ms für Zustandsübergänge; 800–1200 ms für Ambient-Pulse.
- Easing: `Curves.easeOut` für Einblendungen, `Curves.easeIn` für Ausblendungen.
- Keine Spring-Physik (`SpringSimulation`, `ElasticCurve`) in navigationsbezogenen UIs.

### Lucide Icons

Verwende durchgehend [Lucide](https://lucide.dev/)-Icons:

- Stil: Outline, **2 px Strichstärke**, niemals gefüllt.
- Größe: 20 px für UI-Icons, 24 px für Navigationssteuerelemente.
- Mische Lucide nicht mit Material Icons oder Cupertino Icons auf demselben Screen.

Das `lucide_flutter`-Package ist bereits in `app/pubspec.yaml` deklariert.

### Keine hartcodierten Farben in Widgets

Jede Farbreferenz in Flutter-Code muss aus `AppTheme` stammen:

```dart
// Korrekt
color: AppTheme.signalCyan

// Falsch — wird nicht aktualisiert, wenn sich der Token ändert; bricht Theming
color: const Color(0xFF00D4FF)
```

Dieselbe Regel gilt für Abstände: verwende `AppTheme.spacingMd` statt `16.0`.

## Tokens in Flutter verwenden

```dart
// core/theme/app_theme.dart
import 'package:flutter/material.dart';

abstract final class AppTheme {
  // Signalfarben
  static const signalCyan    = Color(0xFF00D4FF);
  static const signalMagenta = Color(0xFFFF00A0);
  static const signalViolet  = Color(0xFF7B2FFF);

  // Hintergründe und Oberflächen
  static const backgroundDeep = Color(0xFF0A0A0F);
  static const surface1       = Color(0xFF12121A);
  static const surface2       = Color(0xFF1C1C28);

  // Text
  static const textPrimary   = Color(0xFFF0F0F5);
  static const textSecondary = Color(0xFF8B8BA0);

  // Typografie
  static const fontDisplay = 'Space Grotesk';
  static const fontBody    = 'IBM Plex Sans';
  static const fontMono    = 'IBM Plex Mono';

  // Abstände
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

Führe einen Token niemals nur an einer Stelle ein. Inkonsistenz zwischen dem CSS-Design-System und der Flutter-Implementierung ist ein Bug.

## Zweisprachige Texte

Alle UI-Strings erscheinen sowohl auf Englisch (`app_en.arb`) als auch auf Deutsch (`app_de.arb`). Die Regeln:

- **Englisch ist die Quelle der Wahrheit.** Neue Strings zuerst in `app_en.arb` hinzufügen.
- **Committe keine maschinell übersetzten deutschen Texte direkt.** Maschinelle Übersetzung dient nur als Ausgangspunkt im CI-Übersetzungsworkflow. Vor dem Eingang in die App ist eine menschliche Überprüfung erforderlich.
- Wenn du dringend einen neuen String benötigst (z. B. für einen Bugfix), füge den englischen String hinzu und setze den entsprechenden ARB-Key in `app_de.arb` vorübergehend auf den englischen Text. Markiere den PR mit dem Label `needs-translation`.
- Stimme mit Maintainern bei Texten ab, die technische Automotive-Begriffe enthalten — diese erfordern oft domänenspezifische Übersetzungsentscheidungen.
