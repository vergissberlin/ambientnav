# AmbientNav App

Cross-platform (Flutter) navigation & microcontroller-management app for the
AmbientNav system. Targets **iOS and Android** today, with **CarPlay /
Android Auto** scaffolds and a documented **watchOS** path for later.

## Features

- Turn-by-turn navigation on a MapLibre (OpenStreetMap) map
- **Dark / Light mode** (follows system, with manual override) — persisted
- **Voice guidance** (multi-language, `flutter_tts`)
- **Offline capability**: a planned route (geometry + maneuvers) is cached and
  the surrounding map region downloaded, so the trip works without connectivity
- **Microcontroller management** over BLE:
  - Discover/connect controllers, live **signal strength (RSSI)** and **battery
    voltage**
  - **LED-strip configuration** — LED count, brightness, effect; read the
    controller's current config on connect and edit it, then write it back
  - **Sensor configuration** — choose the active ultrasonic sensor and calibrate
    its distance offset
  - **Firmware OTA updates** from the app
  - **Secure pairing**: a 6-digit passkey establishes a bonded, encrypted link;
    configuration writes and OTA are locked until paired (least privilege)

## Architecture

Feature-first layout; each feature is split into `data / domain / presentation`,
on a shared `core/`. State management uses **Riverpod**.

```
lib/
├── core/            # di, router, theme, l10n, persistence, security, utils
└── features/
    ├── navigation/  # routing (OSRM/Valhalla), map, voice, maneuver→BLE
    ├── offline/     # MapLibre offline region download
    ├── controllers/ # BLE: telemetry, LED/sensor config, OTA, pairing
    ├── car/         # CarPlay / Android Auto scaffolds
    └── settings/    # theme & preferences
```

The BLE layer sits behind a `ControllerRepository` interface with a real
`flutter_blue_plus` implementation (follow-up) and a `MockControllerRepository`
used in development and **every test**, so the whole app runs without hardware.

## Develop

```bash
flutter pub get
flutter gen-l10n
flutter run --dart-define=USE_MOCK=true   # run against the in-memory mock
```

## Test & analyze

```bash
flutter analyze
flutter test                 # unit + widget tests (no hardware needed)
flutter test integration_test  # requires a device/emulator
```

## Build

```bash
flutter build apk            # Android
flutter build ios --no-codesign  # iOS (codesign for device/store)
```

> **Note:** Full CarPlay / Android Auto navigation and watchOS require platform
> entitlements (Apple CarPlay entitlement, Google Car App Library review) and
> native template UIs; the in-repo scaffolds capture the shared data contract.
> See the project docs for the extended BLE protocol and the watchOS plan.
