---
title: "Development Environment"
description: "Set up your local development environment for AmbientNav — tools, dependencies, and first run."
---

## Required Tools

Install all of the following before attempting to build any part of the project.

| Tool | Minimum version | Purpose |
|---|---|---|
| Flutter | 3.27.0 | App build and test |
| Dart | 3.6.0 | Included with Flutter |
| FVM | any | (Optional) Pins Flutter version per project |
| Xcode | 15.0 | iOS simulator and archive — macOS only |
| Android SDK | API 33 (Android 13) | Android builds and emulator |
| PlatformIO Core | 6.1 | Firmware build and flash |
| Node.js | 20.0 | Docs site build (Astro/Starlight) |
| `just` | 1.13 | Project task runner |

### Installing `just`

```bash
# macOS
brew install just

# Linux (cargo)
cargo install just

# Windows (winget)
winget install --id Casey.Just
```

:::tip
Use [FVM (Flutter Version Manager)](https://fvm.app/) to pin the exact Flutter version specified in `.fvm/fvm_config.json`. This ensures every developer and CI uses the same SDK revision.

```bash
# Install FVM
dart pub global activate fvm

# Inside the repo — install and use pinned version
fvm install
fvm use

# Then prefix flutter commands:
fvm flutter pub get
fvm flutter test
```

Or add `fvm flutter` as an alias in your shell profile.
:::

:::note
**Xcode is macOS-only.** iOS simulator and archive builds are not available on Linux or Windows. You can still build the Android APK, run firmware, and develop the docs site on any platform. iOS contributors need a Mac running macOS 14 (Sonoma) or later.
:::

## Cloning the Repository

```bash
git clone https://github.com/your-org/ambientnav.git
cd ambientnav
```

## Flutter App Dependencies

```bash
cd app
flutter pub get
flutter gen-l10n
```

`flutter gen-l10n` generates the localization classes from the ARB files in `app/lib/l10n/`. You must re-run it after adding or editing any `.arb` file.

## Running the App Without Hardware

The app runs in a fully mocked BLE mode — no ESP32 required. `MockControllerRepository` returns simulated navigation commands, proximity sensor data, and telemetry streams.

```bash
# Using the just task runner (recommended)
just run

# Or directly with flutter
flutter run --dart-define=USE_MOCK=true
```

This launches the app on the default connected device or emulator with mock BLE enabled. All UI flows — navigation, parking radar, LED configuration, settings — are functional.

## Running on a Physical Device

To run on a real phone with a connected ESP32 (BLE hardware present):

```bash
just phone
# Equivalent to:
# flutter run --dart-define=USE_MOCK=false
```

Make sure Bluetooth is enabled on the phone and the ESP32 front board is powered on before launching.

## Firmware: Building with PlatformIO

Each firmware directory is an independent PlatformIO project.

```bash
# Build front board firmware
cd firmware/front
pio run

# Build rear board firmware
cd firmware/rear
pio run
```

PlatformIO automatically fetches all declared library dependencies on first build. Expect the first build to take 2–4 minutes.

## Docs Site: Local Development

```bash
cd docs
npm install
npm run dev
```

The Starlight site starts on `http://localhost:4321`. Changes to markdown files hot-reload in the browser.

To verify the production build compiles without errors:

```bash
npm run build
```

## Running All Tests

```bash
# Using just (from repo root)
just test

# Or directly from the app directory
cd app
flutter test
```

To run tests for a single feature:

```bash
cd app
flutter test test/features/ble/
```

## Static Analysis

```bash
# Using just (from repo root)
just analyze

# Or directly
cd app
flutter analyze
```

Analysis uses the rules in `app/analysis_options.yaml`. All warnings are treated as errors in CI — fix them before pushing.

## Available `just` Commands

The `justfile` at the repository root defines the canonical commands used both locally and in CI:

```bash
just run        # flutter run --dart-define=USE_MOCK=true
just phone      # flutter run --dart-define=USE_MOCK=false
just test       # flutter test (from app/)
just analyze    # flutter analyze (from app/)
just gen        # flutter gen-l10n (from app/)
just build-apk  # flutter build apk --release
just docs       # npm run dev (from docs/)
```

Run `just --list` to see all available recipes.

## IDE Recommendations

### VS Code

Install the following extensions:

| Extension | Publisher | Purpose |
|---|---|---|
| Flutter | Dart Code | Dart/Flutter language support, debugging |
| Dart | Dart Code | Dart language server |
| PlatformIO IDE | PlatformIO | Firmware build, upload, serial monitor |
| Wokwi Simulator | Wokwi | Hardware simulation without physical ESP32 |
| Even Better TOML | tamasfe | `platformio.ini` syntax highlighting |
| Prettier | Prettier | Docs/MDX formatting |

The `.vscode/` directory in the repository contains recommended workspace settings and launch configurations for both the Flutter app (with `USE_MOCK=true`) and the PlatformIO firmware projects.

### Android Studio / IntelliJ

The Flutter and Dart plugins work well for app development. PlatformIO firmware is better developed in VS Code — Android Studio has no PlatformIO support.
