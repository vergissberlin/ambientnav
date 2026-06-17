---
title: Getting Started
description: Hardware requirements, software prerequisites, and step-by-step setup instructions for AmbientNav.
---

## Prerequisites

### Hardware

| Component | Qty | Notes |
|---|---|---|
| ESP32 DevKit (30-pin) | 2 | One front (Master), one rear (Slave) |
| WS2812B LED strip | 2 | 5 V, 60 LEDs/m recommended |
| HC-SR04 ultrasonic sensor | 3 | Left / Center / Right at the rear bumper |
| 5 V / 3 A step-down converter | 1 | Fed from the vehicle's 12 V line |
| 330 Ω resistors | 2 | Data line protection for each LED strip |
| 1000 µF / 6.3 V capacitor | 2 | Across 5 V / GND at each LED strip connector |

### Software

| Tool | Purpose | Install |
|---|---|---|
| [PlatformIO](https://platformio.org/) | ESP32 firmware build & upload | VS Code extension or `pip install platformio` |
| Xcode 15+ | iOS app (iPhone only) | Mac App Store |
| Node.js 20+ | Translation script (CI only) | [nodejs.org](https://nodejs.org/) |

---

## Compatible Microcontrollers

AmbientNav requires the **original ESP32** chip (Xtensa LX6 dual-core). The board must support **Bluetooth Classic (SPP)** and **Bluetooth Low Energy (BLE)** simultaneously — this rules out the ESP32-S2, S3, C3, C6, and H2 variants, which lack Bluetooth Classic.

| Board | Pins | Notes | Buy |
|---|---|---|---|
| ESP32 DevKit V1 | 30 | **Recommended** — compact, widely available, tested | [Amazon](https://www.amazon.de/s?k=ESP32+DevKit+V1+30+Pin&tag=thebeatles-21) |
| ESP32 DevKit V1 | 38 | More GPIOs, slightly larger footprint | [Amazon](https://www.amazon.de/s?k=ESP32+DevKit+V1+38+Pin&tag=thebeatles-21) |
| AZDelivery ESP32 NodeMCU | 30 | Popular in DE/AT/CH, ships with headers | [Amazon](https://www.amazon.de/s?k=AZDelivery+ESP32+NodeMCU&tag=thebeatles-21) |
| DOIT ESP32 DevKit V1 | 30 | Alternative brand, identical 30-pin pinout | [Amazon](https://www.amazon.de/s?k=DOIT+ESP32+DevKit+V1&tag=thebeatles-21) |

> **Important:** All boards above must be based on the **ESP32-WROOM-32** or **ESP32-WROVER** module. Do **not** use ESP32-S2, S3, C3, C6, or H2 — they do not support Bluetooth Classic, which is required for the inter-board SPP link.

---

## Firmware Setup

Clone the repository and open the firmware projects in PlatformIO.

### Front ESP32 (Master)

```bash
cd firmware/front
pio run --target upload
```

### Rear ESP32 (Slave)

```bash
cd firmware/rear
pio run --target upload
```

Flash the rear ESP32 **before** the front so that the master can discover it by its Bluetooth Classic address on first boot.

---

## iOS App Setup

```bash
cd ios
open AmbientNav.xcodeproj
```

Build and run on a **physical iPhone** — Bluetooth LE requires real hardware and cannot be tested in the iOS Simulator.

The app requests Bluetooth permission on first launch. Make sure the front ESP32 is powered and advertising before opening the app.

---

## Wiring

### Power

Use a dedicated 5 V step-down converter fed from the fuse box (always-on or switched with the ignition). Add a 1000 µF bulk capacitor close to each LED strip connector to absorb current spikes.

```
12 V car line → fuse (3 A) → step-down 12 V→5 V → ESP32 VIN + LED strip 5 V
```

### LED Data Lines

Connect a 330 Ω resistor in series on the data line between each ESP32 GPIO and the LED strip DIN pin.

```
ESP32 GPIO  →  [330 Ω]  →  LED strip DIN
GND         ──────────────  LED strip GND
5 V         ──────────────  LED strip 5 V (from step-down converter)
```

Detailed pin assignments are in [Wiring](/wiring/).

---

## Power Budget

| Component | Current (typical) |
|---|---|
| ESP32 front (BLE active) | 240 mA |
| ESP32 rear (BT active) | 240 mA |
| WS2812B — 60 LEDs @ 50 % white | 900 mA |
| 3× HC-SR04 | 45 mA |
| **Total** | **~1.4 A @ 5 V** |

Size your step-down converter for at least **3 A** to handle full-brightness peaks.

---

## GitHub Pages Setup

Before the CI deploy workflow can publish the docs site, enable GitHub Pages in the repository:

1. Go to **Settings → Pages**
2. Set **Source** to **GitHub Actions**
3. Save

The deploy workflow runs automatically on every push to `main` that touches `docs/` or `package.json`.
