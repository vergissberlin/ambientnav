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

```plaintext
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
just run          # iOS simulator + mock BLE (from repo root)
just phone        # physical iPhone + mock BLE
```

Or manually:

```bash
flutter pub get
flutter gen-l10n
flutter run --dart-define=USE_MOCK=true   # run against the in-memory mock
```

### iOS device (physical iPhone)

Device builds need an Apple Development certificate. One-time setup:

1. Open the Xcode workspace: `open ios/Runner.xcworkspace`
2. **Xcode → Settings → Accounts** — sign in with your Apple ID
3. Select **Runner** → **Signing & Capabilities** → enable **Automatically manage signing**
4. Choose your **Team** (Personal Team is fine for local testing)
5. Connect/unlock the iPhone, trust the Mac, enable **Developer Mode** on the device
6. Run again: `flutter run -d <device-id> --dart-define=USE_MOCK=true`
7. On first install: **Settings → General → VPN & Device Management** → trust the developer app

Alternatively, copy `ios/Flutter/Local.xcconfig.example` to `ios/Flutter/Local.xcconfig`
and set `DEVELOPMENT_TEAM` to your Team ID (file is gitignored).

Wireless debugging: pair once over USB, then enable **Connect via network** in
**Window → Devices and Simulators**.

## Navigation backends

The Navigate tab uses free, key-less services by default:

- **Map tiles/style:** OpenFreeMap Liberty (`tiles.openfreemap.org`)
- **Routing:** public OSRM demo (`router.project-osrm.org`)
- **Geocoding:** OpenStreetMap Nominatim (`nominatim.openstreetmap.org`)

These are shared, rate-limited community services — fine for development. For
production, host your own (Nominatim, OSRM/Valhalla, a tile/style server) and
override `kMapStyleUrl` + `routingApiProvider` + `geocodingServiceProvider` in
`lib/core/di/providers.dart`. A planned route is cached and its map region can be
downloaded for offline use.

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
