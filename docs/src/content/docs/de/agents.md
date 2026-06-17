---
title: Agenten
description: Referenz der fünf logischen Agenten in AmbientNav — Verantwortlichkeiten, Ein-/Ausgaben und Zustandsautomaten.
---

AmbientNav ist um fünf logische Agenten strukturiert. Jeder Agent hat eine einzige, klar definierte Verantwortlichkeit und kommuniziert mit anderen über typisierte Schnittstellen.

```
NavAgent (iOS) ──BLE──▶ OrchestratorAgent (ESP32 Vorne)
                                │                   ▲
                        EffectAgent (Vorne)   BT Classic
                                          ProximityAgent (ESP32 Hinten)
                                                    │
                                          EffectAgent (Hinten)
```

---

## NavAgent — iOS

**Ort:** `ios/AmbientNav/Navigation/`  
**Laufzeit:** iPhone, Vordergrund  
**Sprache:** Swift

Liest Live-Navigationsdaten vom Valhalla-Routing-Engine über MapLibre Navigation iOS. Extrahiert das nächste Manöver und sendet kompakte BLE-Pakete an den vorderen ESP32. Veröffentlicht **nur bei Änderungen** (delta-gesteuert), um BLE-Datenverkehr zu minimieren.

### Eingaben

| Quelle | Daten |
|---|---|
| MapLibre / Valhalla SDK | Nächster Manövertyp, Abstand zum Manöver |
| iOS Blinker-API | Blinkerstatus (links / rechts / aus) |

### Ausgaben

| Ziel | Protokoll | Format |
|---|---|---|
| OrchestratorAgent | Bluetooth LE — GATT Write | `[direction, distance_m, blinker]` — 3 Bytes |

### Zustände

```
LEERLAUF ──navigation_start──▶ NAVIGIEREND ──angekommen──▶ LEERLAUF
                                     │
                               Manöverereignis
                                     │
                               VERÖFFENTLICHEND → zurück zu NAVIGIEREND
```

Fällt auf `direction = 0x00` (keine) zurück, wenn das GPS-Signal länger als 3 Sekunden verloren ist.

---

## ProximityAgent — ESP32 Hinten

**Ort:** `firmware/rear/src/`  
**Laufzeit:** ESP32 Slave, FreeRTOS-Task  
**Sprache:** C++ (Arduino / ESP-IDF)

Steuert drei HC-SR04 Sensoren sequenziell an (30 ms Abstand zwischen Triggern zur Vermeidung von Übersprechen). Wendet einen 3-Messung-Medianfilter pro Sensor an. Sendet das gefusionierte Abstandstripel bei **10 Hz** an den OrchestratorAgent, solange der Rückfahrmodus aktiv ist. Rendert außerdem den hinteren LED-Streifen direkt.

### Eingaben

| Quelle | Schnittstelle | Signal |
|---|---|---|
| HC-SR04 Links | GPIO (TRIG + ECHO) | Laufzeitimpuls |
| HC-SR04 Mitte | GPIO (TRIG + ECHO) | Laufzeitimpuls |
| HC-SR04 Rechts | GPIO (TRIG + ECHO) | Laufzeitimpuls |
| OrchestratorAgent | BT Classic SPP | `{ "cmd": "reverse", "active": bool }` |

### Ausgaben

| Ziel | Protokoll | Format |
|---|---|---|
| OrchestratorAgent | BT Classic SPP | `{ "type": "sensors", "left": cm, "center": cm, "right": cm }` |
| Hinterer LED-Streifen | FastLED (GPIO) | Direkte Pixel-Schreibvorgänge |

### Zustände

```
BEREITSCHAFT ──reverse(active=true)──▶ MESSUNG ──reverse(active=false)──▶ BEREITSCHAFT
                   │
             Sensorzyklus (30 ms)
                   │
             REPORTING → zurück zu MESSUNG
```

Außerhalb des Messbereichs liegende Messwerte (> 400 cm oder Echo-Timeout) werden durch `999` (kein Hindernis) ersetzt.

---

## OrchestratorAgent — ESP32 Vorne

**Ort:** `firmware/front/src/`  
**Laufzeit:** ESP32 Master, FreeRTOS-Task (10 ms Takt)  
**Sprache:** C++ (Arduino / ESP-IDF)

Die zentrale Entscheidungsinstanz. Führt Navigationsbefehle vom iPhone und Sensordaten vom hinteren ESP32 zusammen. Bestimmt den richtigen LED-Effekt für beide Streifen und sendet Render-Befehle an die EffectAgents.

### Eingaben

| Quelle | Protokoll | Daten |
|---|---|---|
| NavAgent | BLE GATT Write | `[direction, distance_m, blinker]` |
| ProximityAgent | BT Classic SPP | `{ "type": "sensors", ... }` |

### Ausgaben

| Ziel | Protokoll | Daten |
|---|---|---|
| EffectAgent (Vorne) | Interne Warteschlange | `EffectCommand { type, color, intensity }` |
| EffectAgent (Hinten) | BT Classic SPP | `{ "cmd": "effect", "type": "...", "params": {...} }` |

### Prioritätsregeln

Bei gleichzeitig eintreffenden Eingaben gilt folgende Priorität:

1. **Rückwärtsfahrt aktiv** — Einparkhilfe überschreibt alle anderen Effekte auf dem hinteren Streifen
2. **Aktives Manöver** (Abstand < 200 m) — Navigationseffekt auf dem vorderen Streifen
3. **Blinker aktiv** — Blinker-Animation auf dem vorderen Streifen
4. **Leerlauf** — Langsames Ambiente-Atmen auf beiden Streifen

---

## EffectAgent — Vorderer LED-Streifen

**Ort:** `firmware/front/src/led_effects.cpp`  
**Laufzeit:** ESP32 Vorne, synchron vom OrchestratorAgent aufgerufen

Übersetzt abstrakte `EffectCommand`-Strukturen in WS2812B-Pixeldaten.

| Effekt-ID | Auslöser | Farbe | Zeitverhalten |
|---|---|---|---|
| `NAV_LEFT` | Abbiegen links, Abstand < 200 m | Amber `#FFA500` | Sweep Mitte → linker Rand, 600 ms Zyklus |
| `NAV_RIGHT` | Abbiegen rechts, Abstand < 200 m | Amber `#FFA500` | Sweep Mitte → rechter Rand, 600 ms Zyklus |
| `NAV_STRAIGHT` | Geradeaus weiterfahren | Weiß `#FFFFFF` | Einzelner Puls vorwärts, 800 ms |
| `BLINKER_LEFT` | Linker Blinker aktiv | Amber `#FFA500` | Schnelles Blinken, nur linke Hälfte, 400 ms ein/aus |
| `BLINKER_RIGHT` | Rechter Blinker aktiv | Amber `#FFA500` | Schnelles Blinken, nur rechte Hälfte, 400 ms ein/aus |
| `HAZARD` | Warnblinker | Amber `#FFA500` | Gesamter Streifen blinkt, 400 ms ein/aus |
| `AMBIENT` | Leerlauf / keine Navigation | Konfigurierbar | Langsames Sinus-Atmen, 3 s Periode |

---

## EffectAgent — Hinterer LED-Streifen

**Ort:** `firmware/rear/src/led_effects.cpp`  
**Laufzeit:** ESP32 Hinten, gesteuert vom OrchestratorAgent über SPP

Rendert Einparkhilfe-Visualisierungen. Der Streifen ist in drei gleiche Zonen eingeteilt (links / mitte / rechts), die jeweils vom entsprechenden HC-SR04-Sensor gesteuert werden.

| Abstand | Füllgrad | Farbe |
|---|---|---|
| > 150 cm | 100 % | Grün |
| 100–150 cm | 80 % | Gelbgrün |
| 50–100 cm | 50 % | Amber |
| 20–50 cm | 20 % | Orange |
| < 20 cm | 10 % + Blinken | Rot |

Zone-Füllformel:

```
fill = clamp((distance_cm - 20) / 130, 0.1, 1.0)
```

---

## Fehlermodi

| Fehler | Erkannt von | Wiederherstellung |
|---|---|---|
| BLE-Verbindung unterbrochen | OrchestratorAgent (GATT Disconnect) | Vorderer Streifen → AMBIENT nach 5 s |
| BT Classic-Verbindung unterbrochen | OrchestratorAgent (SPP Disconnect) | Rückfahrmodus deaktivieren; alle 5 s Wiederverbindung versuchen |
| HC-SR04 Echo-Timeout | ProximityAgent | Messwert durch `999` ersetzen; Betrieb fortsetzen |
| Veraltete Sensordaten (> 500 ms) | OrchestratorAgent (Zeitstempel-Prüfung) | Alle Sensorwerte als `999` behandeln |
