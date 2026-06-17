---
title: Erste Schritte
description: Hardwareanforderungen, Softwarevoraussetzungen und Schritt-für-Schritt-Anleitungen zur Einrichtung von AmbientNav.
---

## Voraussetzungen

### Hardware

| Komponente | Menge | Anmerkungen |
|---|---|---|
| ESP32 DevKit (30-Pin) | 2 | Eine vorne (Master), eine hinten (Slave) |
| WS2812B LED-Streifen | 2 | 5 V, 60 LEDs/m empfohlen |
| HC-SR04 Ultraschallsensor | 3 | Links / Mitte / Rechts am hinteren Stoßfänger |
| 5 V / 3 A Step-Down-Wandler | 1 | Versorgt von der 12 V-Leitung des Fahrzeugs |
| 330 Ω Widerstände | 2 | Datensignal-Schutz für jeden LED-Streifen |
| 1000 µF / 6.3 V Kondensator | 2 | Über 5 V / GND an jedem LED-Streifen-Anschluss |

### Software

| Werkzeug | Zweck | Installation |
|---|---|---|
| [PlatformIO](https://platformio.org/) | ESP32 Firmware-Build & Upload | VS Code Erweiterung oder `pip install platformio` |
| Xcode 15+ | iOS-App (nur iPhone) | Mac App Store |
| Node.js 20+ | Übersetzungsskript (CI nur) | [nodejs.org](https://nodejs.org/) |

---

## Kompatible Mikrocontroller

AmbientNav benötigt den **originalen ESP32** Chip (Xtensa LX6 Dual-Core). Die Platine muss **Bluetooth Classic (SPP)** und **Bluetooth Low Energy (BLE)** gleichzeitig unterstützen — dies schließt die Varianten ESP32-S2, S3, C3, C6 und H2 aus, die Bluetooth Classic nicht unterstützen.

| Platine | Pins | Anmerkungen | Kaufen |
|---|---|---|---|
| ESP32 DevKit V1 | 30 | **Empfohlen** — kompakt, weit verbreitet, getestet | [Amazon](https://www.amazon.de/s?k=ESP32+DevKit+V1+30+Pin&tag=thebeatles-21) |
| ESP32 DevKit V1 | 38 | Mehr GPIOs, etwas größere Bauform | [Amazon](https://www.amazon.de/s?k=ESP32+DevKit+V1+38+Pin&tag=thebeatles-21) |
| AZDelivery ESP32 NodeMCU | 30 | Beliebt in DE/AT/CH, wird mit Headern geliefert | [Amazon](https://www.amazon.de/s?k=AZDelivery+ESP32+NodeMCU&tag=thebeatles-21) |
| DOIT ESP32 DevKit V1 | 30 | Alternative Marke, identische 30-Pin-Belegung | [Amazon](https://www.amazon.de/s?k=DOIT+ESP32+DevKit+V1&tag=thebeatles-21) |

> **Wichtig:** Alle oben genannten Platinen müssen auf dem **ESP32-WROOM-32** oder **ESP32-WROVER** Modul basieren. Verwenden Sie **nicht** ESP32-S2, S3, C3, C6 oder H2 — sie unterstützen kein Bluetooth Classic, das für die inter-board SPP-Verbindung erforderlich ist.

---

## Firmware-Einrichtung

Klonen Sie das Repository und öffnen Sie die Firmware-Projekte in PlatformIO.

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

Flashen Sie den hinteren ESP32 **vor** dem vorderen, damit der Master ihn beim ersten Booten über seine Bluetooth Classic-Adresse entdecken kann.

---

## iOS App-Einrichtung

```bash
cd ios
open AmbientNav.xcodeproj
```

Bauen und führen Sie die App auf einem **physischen iPhone** aus — Bluetooth LE erfordert echte Hardware und kann nicht im iOS-Simulator getestet werden.

Die App fordert beim ersten Start die Bluetooth-Berechtigung an. Stellen Sie sicher, dass der vordere ESP32 mit Strom versorgt wird und Werbung macht, bevor Sie die App öffnen.

---

## Verkabelung

### Stromversorgung

Verwenden Sie einen dedizierten 5 V Step-Down-Wandler, der von der Sicherungskasten (immer eingeschaltet oder mit der Zündung geschaltet) gespeist wird. Fügen Sie einen 1000 µF Bulk-Kondensator in der Nähe jedes LED-Streifen-Anschlusses hinzu, um Stromspitzen abzufangen.

```
12 V Autobatterie → Sicherung (3 A) → Step-Down 12 V→5 V → ESP32 VIN + LED-Streifen 5 V
```

### LED-Datenleitungen

Schließen Sie einen 330 Ω Widerstand in Reihe auf der Datenleitung zwischen jedem ESP32 GPIO und dem DIN-Pin des LED-Streifens an.

```
ESP32 GPIO  →  [330 Ω]  →  LED-Streifen DIN
GND         ──────────────  LED-Streifen GND
5 V         ──────────────  LED-Streifen 5 V (vom Step-Down-Wandler)
```

Detaillierte Pin-Zuweisungen finden Sie in [Verkabelung](/wiring/).

---

## Leistungsbudget

| Komponente | Strom (typisch) |
|---|---|
| ESP32 vorne (BLE aktiv) | 240 mA |
| ESP32 hinten (BT aktiv) | 240 mA |
| WS2812B — 60 LEDs @ 50 % weiß | 900 mA |
| 3× HC-SR04 | 45 mA |
| **Gesamt** | **~1.4 A @ 5 V** |

Dimensionieren Sie Ihren Step-Down-Wandler für mindestens **3 A**, um Spitzen bei voller Helligkeit zu bewältigen.

---

## GitHub Pages-Einrichtung

Bevor der CI-Bereitstellungsworkflow die Dokumentationsseite veröffentlichen kann, aktivieren Sie GitHub Pages im Repository:

1. Gehen Sie zu **Einstellungen → Seiten**
2. Setzen Sie **Quelle** auf **GitHub Actions**
3. Speichern

Der Bereitstellungsworkflow wird automatisch bei jedem Push zu `main`, der `docs/` oder `package.json` berührt, ausgeführt.