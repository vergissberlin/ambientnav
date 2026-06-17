---
title: LED-Effekte
description: Vollständiger Katalog der Navigations- und Einparkhilfe-LED-Effekte für den vorderen und hinteren WS2812B-Streifen.
---

AmbientNav steuert zwei unabhängige WS2812B LED-Streifen über FastLED. Der vordere Streifen übernimmt Navigation und Blinker-Feedback; der hintere Streifen übernimmt die Einparkhilfe.

---

## Vorderer Streifen — Navigationseffekte

Der vordere Streifen wird vom EffectAgent auf dem vorderen ESP32 gesteuert. Effekte werden durch Navigationsbefehle der iOS App ausgelöst.

| Effekt-ID | Auslöser | Farbe | Zeitverhalten |
|---|---|---|---|
| `NAV_LEFT` | Links abbiegen, Abstand < 200 m | Amber `#FFA500` | Sweep Mitte → linker Rand, 600 ms Zyklus |
| `NAV_RIGHT` | Rechts abbiegen, Abstand < 200 m | Amber `#FFA500` | Sweep Mitte → rechter Rand, 600 ms Zyklus |
| `NAV_STRAIGHT` | Geradeaus weiterfahren | Weiß `#FFFFFF` | Einzelner Puls zur Mitte, 800 ms |
| `BLINKER_LEFT` | Linker Blinker aktiv | Amber `#FFA500` | Schnelles Blinken, nur linke Hälfte, 400 ms ein/aus |
| `BLINKER_RIGHT` | Rechter Blinker aktiv | Amber `#FFA500` | Schnelles Blinken, nur rechte Hälfte, 400 ms ein/aus |
| `HAZARD` | Warnblinker | Amber `#FFA500` | Gesamter Streifen blinkt, 400 ms ein/aus |
| `AMBIENT` | Leerlauf / keine Navigation | Konfigurierbar | Langsames Sinus-Atmen, 3 s Periode |

### Priorität

Wenn die Navigations-App gleichzeitig eine bevorstehende Abbiegung signalisiert und der Blinker aktiv ist, haben `NAV_LEFT` / `NAV_RIGHT` Vorrang vor `BLINKER_LEFT` / `BLINKER_RIGHT`, da sie zusätzliche Abstandsinformationen liefern.

### Sweep-Animation

Die `NAV_LEFT`- und `NAV_RIGHT`-Sweeps verwenden einen bewegenden Punkt, der in der Streifenmitte beginnt und zum Rand wandert. Die Punktbreite beträgt 15 % der Gesamt-LED-Anzahl, mit einem weichen Fade-Schweif.

```
NAV_LEFT:   ████░░░░░░░░░  →  ░░░░░░░░░████
            Mitte               linker Rand
```

---

## Hinterer Streifen — Einparkhilfe

Der hintere Streifen ist in drei gleiche Zonen unterteilt, die jeweils unabhängig vom entsprechenden HC-SR04-Sensor gesteuert werden. Die Zonen spiegeln die Hindernisannäherung für links, mitte und rechts wider.

### Zonenfüllung nach Abstand

| Abstand | Füllgrad | Farbe | Blinken |
|---|---|---|---|
| > 150 cm | 100 % | Grün `#00FF00` | Nein |
| 100–150 cm | 80 % | Gelbgrün `#AAFF00` | Nein |
| 50–100 cm | 50 % | Amber `#FFA500` | Nein |
| 20–50 cm | 20 % | Orange `#FF4400` | Nein |
| < 20 cm | 10 % | Rot `#FF0000` | 200 ms ein/aus |

### Füllformel

Die Zonenfüllung wird pro Sensor unabhängig berechnet:

```
fill = clamp((distance_cm - 20) / 130, 0.1, 1.0)
```

Zuordnung:
- `Abstand = 150 cm` → `fill = 1,0` (100 %, voller Balken)
- `Abstand = 20 cm`  → `fill = 0,1` (10 %, minimaler Balken)
- `Abstand < 20 cm`  → auf `0,1` begrenzt, plus schnelles Blinken
- `Abstand = 999`    → `fill = 1,0` (kein Hindernis, voller grüner Balken)

### Zonenlayout

```
Fahrzeugheck:

 Linke Zone           Mittlere Zone         Rechte Zone
[██████████]         [██████████]          [██████████]
 HC-SR04 L            HC-SR04 M             HC-SR04 R
```

Jede Zone belegt ein Drittel der Gesamt-LED-Anzahl. Die Zonen sind unabhängig — die mittlere Zone kann kritischen Abstand anzeigen, während die Seitenzonen frei sind.

### Aktivierung des Rückfahrmodus

Der Einparkhilfe-Effekt des hinteren Streifens ist nur aktiv, wenn der vordere ESP32 `{ "cmd": "reverse", "active": true }` sendet. Außerhalb des Rückfahrmodus zeigt der hintere Streifen den `AMBIENT`-Effekt.

---

## FastLED Konfiguration

Beide Streifen verwenden WS2812B LEDs mit 5 V und dem 800-kHz-Datenprotokoll.

```cpp
// Vorderer Streifen
#define FRONT_LED_PIN   5
#define FRONT_LED_COUNT 60
CRGB frontLeds[FRONT_LED_COUNT];
FastLED.addLeds<WS2812B, FRONT_LED_PIN, GRB>(frontLeds, FRONT_LED_COUNT).setCorrection(TypicalLEDStrip);

// Hinterer Streifen
#define REAR_LED_PIN    18
#define REAR_LED_COUNT  60
CRGB rearLeds[REAR_LED_COUNT];
FastLED.addLeds<WS2812B, REAR_LED_PIN, GRB>(rearLeds, REAR_LED_COUNT).setCorrection(TypicalLEDStrip);
```

`FastLED.setBrightness(128)` begrenzt die globale Helligkeit auf 50 %, um innerhalb des 3-A-Leistungsbudgets zu bleiben. Die individuelle Effekthelligkeit wird relativ zu dieser globalen Begrenzung skaliert.
