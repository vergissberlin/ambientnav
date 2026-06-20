# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Layout

```
ambientnav/
├── app/                  # Flutter iOS/Android app
├── firmware/front/       # ESP32 master — BLE + front LED strip
├── firmware/rear/        # ESP32 slave  — ultrasonic sensors + rear LED strip
├── docs/                 # Astro/Starlight documentation site
├── wokwi/                # ESP32 circuit simulations
└── Justfile              # Top-level dev shortcuts
```

## Build & Test Commands

### App (Flutter)
```bash
just prepare              # flutter pub get + gen-l10n
just run                  # iOS simulator with mock BLE (USE_MOCK=true)
just analyze              # flutter analyze
just test                 # unit + widget tests
flutter test integration_test   # integration tests
flutter build apk         # Android debug APK
```

### Firmware (PlatformIO)
```bash
cd firmware/front && pio run                    # build
cd firmware/front && pio run --target upload    # flash
cd firmware/rear  && pio run
cd firmware/rear  && pio run --target upload
```

### Docs (Astro/Starlight — pnpm)
```bash
cd docs && pnpm install
cd docs && pnpm run dev      # dev server
cd docs && pnpm run build    # production build
```

## Architecture

**Data flow:**

```
Flutter App  ──BLE GATT──►  ESP32 Front (master)  ──SPP──►  ESP32 Rear (slave)
                              │  nav effects                   │  parking aid
                              │  front LED strip               │  rear LED strip
                              └──────────────────              └── HC-SR04 × 3
```

- **BLE characteristic DEF1** (3 bytes): `direction | distance_m | blinker`
- **BLE characteristic DEF6** (8 bytes): `LedRuntimeConfig` — led_count, brightness, effect, params
- **SPP** messages: newline-delimited JSON from front to rear (sensor config, reverse signal)

**Front ESP32 tasks (FreeRTOS):**
- Core 0: `taskBTClient` (SPP to rear)
- Core 1: `taskOrchestrator` → `effectQueue` → `taskLEDFront` + `taskTelemetry`

**Effect priority in `orchestrator.cpp`** (highest first):
1. Active nav maneuver within 200 m → `EFF_NAV_LEFT / RIGHT / STRAIGHT`
2. Hazard active → `EFF_HAZARD`
3. Blinker active → `EFF_BLINKER_LEFT / RIGHT`
4. Reverse engaged → `EFF_AMBIENT` (rear handles parking)
5. Default → `EFF_AMBIENT`

"Fresh nav" = BLE command received within `BLE_FADE_TIMEOUT_MS` (5 000 ms).

**App features** — Riverpod state, MapLibre GL maps, Valhalla/OSRM routing, flutter_tts voice, Hive persistence, flutter_blue_plus BLE.

## Invariant: Firmware ↔ Documentation Animation Parity

**Every LED effect change in firmware MUST be mirrored in the CSS/JS visualizer.**

| Firmware file | Documentation file |
|---|---|
| `firmware/front/src/led_effects.cpp` | `docs/src/components/LedEffectsVisualizer.astro` |

The Astro component contains CSS `@keyframes` and gradient definitions that visually represent each effect in the docs. When you modify the colour palette, timing, or motion of an effect in the C++ render function, update the matching CSS animation in the Astro component in the same commit. The mapping is:

| `EffectType` | CSS class(es) in Visualizer |
|---|---|
| `EFF_AMBIENT` | `.le-ambient`, `@keyframes le-breathe` |
| `EFF_NAV_LEFT` | `.le-wave-left`, `.le-wave-grad`, `@keyframes le-wave-l` |
| `EFF_NAV_RIGHT` | `.le-wave-right`, `.le-wave-grad`, `@keyframes le-wave-r` |
| `EFF_NAV_STRAIGHT` | `.le-straight`, `@keyframes le-breathe` |
| `EFF_BLINKER_LEFT` | `.le-half-left`, `.le-blink` |
| `EFF_BLINKER_RIGHT` | `.le-half-right`, `.le-blink` |
| `EFF_HAZARD` | `.le-hazard`, `.le-blink` |

## Commit Convention

Follows Conventional Commits. Changelog-visible scopes: `feat`, `fix`, `docs`, `firmware`. Example:

```
feat(front-led): replace nav sweep with ambient wave
```

Versioning is managed by `release-please`; extra files auto-bumped on release: `firmware/front/src/config.h`, `firmware/rear/src/config.h`, `app/pubspec.yaml`.
