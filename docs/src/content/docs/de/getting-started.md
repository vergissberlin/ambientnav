---
title: Erste Schritte
description: Hardwareanforderungen, Software-Voraussetzungen und Schritt-für-Schritt-Einrichtungsanleitung für AmbientNav.
---

## Voraussetzungen

### Hardware

| Komponente | Anz. | Hinweise |
|---|---|---|
| ESP32 DevKit (30-pin) | 2 | Einer vorne (Master), einer hinten (Slave) |
| WS2812B LED-Streifen | 2 | 5 V, 60 LEDs/m empfohlen |
| HC-SR04 Ultraschallsensor | 3 | Links / Mitte / Rechts an der hinteren Stoßstange |
| 5 V / 3 A Spannungswandler (Step-Down) | 1 | Gespeist aus der 12-V-Leitung des Fahrzeugs |
| 330 Ω Widerstände | 2 | Datenleitungsschutz für jeden LED-Streifen |
| 1000 µF / 6,3 V Kondensator | 2 | An 5 V / GND an jedem LED-Streifenanschluss |

### Software

| Werkzeug | Zweck | Installation |
|---|---|---|
| [PlatformIO](https://platformio.org/) | ESP32-Firmware-Build & Upload | VS Code Extension oder `pip install platformio` |
| Xcode 15+ | iOS App (nur iPhone) | Mac App Store |
| Node.js 20+ | Übersetzungs-Script (nur CI) | [nodejs.org](https://nodejs.org/) |

---

## Firmware einrichten

Repository klonen und die Firmware-Projekte in PlatformIO öffnen.

### Vorderer ESP32 (Master)

```bash
cd firmware/front
pio run --target upload
```

### Hinterer ESP32 (Slave)

```bash
cd firmware/rear
pio run --target upload
```

Den hinteren ESP32 **vor** dem vorderen flashen, damit der Master seine Bluetooth-Classic-Adresse beim ersten Start entdecken kann.

---

## iOS App einrichten

```bash
cd ios
open AmbientNav.xcodeproj
```

Auf einem **echten iPhone** bauen und ausführen — Bluetooth LE erfordert echte Hardware und kann nicht im iOS-Simulator getestet werden.

Die App fragt beim ersten Start nach der Bluetooth-Berechtigung. Der vordere ESP32 muss eingeschaltet und werbend sein, bevor die App geöffnet wird.

---

## Verkabelung

### Stromversorgung

Einen dedizierten 5-V-Spannungswandler verwenden, der aus dem Sicherungskasten (Dauerplus oder gezündet) gespeist wird. Einen 1000-µF-Kondensator nahe an jedem LED-Streifenanschluss hinzufügen, um Einschaltstromspitzen zu absorbieren.

```
12-V-Fahrzeugleitung → Sicherung (3 A) → Wandler 12 V→5 V → ESP32 VIN + LED-Streifen 5 V
```

### LED-Datenleitungen

Einen 330-Ω-Widerstand in Reihe auf der Datenleitung zwischen dem ESP32 GPIO und dem DIN-Pin des LED-Streifens schalten.

```
ESP32 GPIO  →  [330 Ω]  →  LED-Streifen DIN
GND         ──────────────  LED-Streifen GND
5 V         ──────────────  LED-Streifen 5 V (vom Spannungswandler)
```

Detaillierte Pin-Belegungen sind in [`docs/wiring.md`](/de/wiring/) (demnächst verfügbar).

---

## Leistungsaufnahme

| Komponente | Strom (typisch) |
|---|---|
| ESP32 vorne (BLE aktiv) | 240 mA |
| ESP32 hinten (BT aktiv) | 240 mA |
| WS2812B — 60 LEDs @ 50 % Weiß | 900 mA |
| 3× HC-SR04 | 45 mA |
| **Gesamt** | **~1,4 A @ 5 V** |

Den Spannungswandler für mindestens **3 A** auslegen, um Volllast-Spitzen abzufangen.

---

## GitHub Pages einrichten

Bevor der CI-Deploy-Workflow die Docs-Site veröffentlichen kann, muss GitHub Pages im Repository aktiviert werden:

1. Zu **Settings → Pages** navigieren
2. **Source** auf **GitHub Actions** setzen
3. Speichern

Der Deploy-Workflow läuft automatisch bei jedem Push auf `main`, der `docs/` oder `package.json` berührt.
