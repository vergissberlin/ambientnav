---
title: "Flutter App"
description: "Architecture guide and development conventions for the AmbientNav Flutter application."
---

## Directory Structure

The app source lives entirely under `app/lib/`. Two top-level directories contain everything:

```
app/lib/
├── core/                    # Shared infrastructure, used across all features
│   ├── di/
│   │   └── providers.dart   # All Riverpod providers, centralized
│   ├── router/
│   │   └── app_router.dart  # GoRouter configuration, ShellRoute, named routes
│   ├── theme/
│   │   └── app_theme.dart   # Design token constants (AppTheme.signalCyan, etc.)
│   ├── ble/
│   │   ├── i_controller_repository.dart      # BLE abstraction interface
│   │   ├── bluetooth_controller_repository.dart  # Real BLE implementation
│   │   └── mock_controller_repository.dart   # Mock for CI + mock-run mode
│   └── l10n/                # Generated localization classes (do not edit)
└── features/
    ├── nav/                 # Turn-by-turn navigation (MapLibre, Valhalla/OSRM)
    ├── ble/                 # BLE device discovery and connection management
    ├── parking/             # Parking aid UI, proximity radar visualization
    └── settings/            # App preferences, LED configuration, device info
```

## Feature Structure Pattern

Every feature follows the same three-layer split:

```
features/<feature>/
├── presentation/        # Widgets, screens, controllers (ConsumerWidget subclasses)
├── domain/              # Entities, use cases, repository interfaces (pure Dart)
└── data/                # Repository implementations, codecs, local data sources
```

- **Presentation** depends on domain. It never touches `data/` directly.
- **Domain** has zero Flutter dependencies — pure Dart classes and interfaces only.
- **Data** implements domain interfaces and may use packages (Hive, http, flutter_blue_plus).

Cross-feature dependencies flow only through `core/`. A feature never imports from another feature's `presentation/` layer.

## Riverpod State Management

All providers are defined in `core/di/providers.dart`. Scattering providers across feature directories makes dependency tracing difficult — keep them centralized.

```dart
// core/di/providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambientnav/core/ble/i_controller_repository.dart';
import 'package:ambientnav/core/ble/bluetooth_controller_repository.dart';
import 'package:ambientnav/core/ble/mock_controller_repository.dart';

// Defined via compile-time dart-define; resolved at startup
const bool _useMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);

final controllerRepositoryProvider = Provider<IControllerRepository>((ref) {
  return _useMock
      ? MockControllerRepository()
      : BluetoothControllerRepository();
});

final navCommandStreamProvider = StreamProvider<NavCommand>((ref) {
  return ref.watch(controllerRepositoryProvider).navCommandStream;
});

final telemetryStreamProvider = StreamProvider<Telemetry>((ref) {
  return ref.watch(controllerRepositoryProvider).telemetryStream;
});

final sensorConfigProvider = StreamProvider<SensorConfig>((ref) {
  return ref.watch(controllerRepositoryProvider).sensorConfigStream;
});
```

In widgets, use `ConsumerWidget` or `ConsumerStatefulWidget`:

```dart
class SpeedReadout extends ConsumerWidget {
  const SpeedReadout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetry = ref.watch(telemetryStreamProvider);
    return telemetry.when(
      data: (t) => Text('${t.speedKmh.toStringAsFixed(0)} km/h'),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const Icon(Icons.signal_wifi_off),
    );
  }
}
```

Use `ref.invalidate()` or `ref.refresh()` sparingly — prefer reactive streams over manual cache busting.

## Atomic Design Hierarchy

Components are organized in layers. Each layer builds on the one below it. **Imports only flow downward** — Organisms may use Molecules and Atoms, but never the reverse.

### Quarks — Design Foundation

Quarks are not widgets. They are token constants and theme definitions in `core/theme/app_theme.dart`. No visual component; they exist only to be referenced by higher layers.

```
AppTheme.signalCyan        → Color(0xFF00D4FF)
AppTheme.backgroundDeep    → Color(0xFF0A0A0F)
AppTheme.fontDisplay       → 'Space Grotesk'
AppTheme.spacingMd         → 16.0
```

### Atoms — Single-purpose Primitives

Small, stateless (or near-stateless) widgets with no business logic:

| Atom | Description |
|---|---|
| `RssiIndicator` | RSSI signal strength bar (1–5 bars), takes `int rssi` |
| `BatteryGauge` | Battery percentage bar with color threshold (green/yellow/red) |
| `SpeedReadout` | Formatted km/h label, large display font |
| `LedCountBadge` | Pill badge showing active LED count |
| `SignalDot` | Animated dot indicating BLE connection state |

### Molecules — Composed UI Units

Molecules combine Atoms into meaningful UI groups:

| Molecule | Description |
|---|---|
| `DeviceListTile` | Scanned BLE device row: device name, RSSI indicator, connect button |
| `RouteInfoCard` | Current route summary: distance, ETA, next maneuver icon |
| `ProximityReading` | Single sensor distance label + warning icon |
| `LedBrightnessRow` | Label + slider + preview dot for one LED channel |

### Organisms — Complex Feature Sections

Organisms implement a full feature section and may contain local state:

| Organism | Description |
|---|---|
| `LedConfigForm` | Full LED configuration panel: effect picker, brightness sliders, color preview |
| `ParkingRadar` | Animated top-down vehicle view with proximity arcs for each ultrasonic sensor |
| `DeviceScanner` | BLE scan controller: scanning indicator, device list, connect/disconnect |
| `NavManeuverBanner` | Persistent bottom banner: next turn instruction, distance, road name |

### Pages

Pages are full screens registered in the GoRouter. They wire up Riverpod providers and compose Organisms:

| Page | Route | Description |
|---|---|---|
| `MapScreen` | `/` | MapLibre map view + `NavManeuverBanner` overlay |
| `ParkingScreen` | `/parking` | Full-screen `ParkingRadar` organism |
| `DeviceScanScreen` | `/ble/scan` | BLE device discovery and pairing |
| `LedSettingsPage` | `/settings/leds` | `LedConfigForm` in a settings scaffold |
| `SettingsPage` | `/settings` | App preferences list |

## BLE Abstraction Layer

The BLE layer is hidden behind the `IControllerRepository` interface. The app never calls `flutter_blue_plus` APIs directly from UI code.

```dart
// core/ble/i_controller_repository.dart
abstract interface class IControllerRepository {
  Stream<NavCommand> get navCommandStream;
  Stream<Telemetry> get telemetryStream;
  Stream<SensorConfig> get sensorConfigStream;

  Future<void> sendLedConfig(LedConfig config);
  Future<void> connect(String deviceId);
  Future<void> disconnect();
}
```

`BluetoothControllerRepository` is the production implementation using `flutter_blue_plus`. `MockControllerRepository` returns periodic fake data streams — no Bluetooth hardware required.

The switch between real and mock is resolved at compile time via the `USE_MOCK` dart-define:

```bash
# Mock mode (CI, simulator, UI development)
flutter run --dart-define=USE_MOCK=true

# Real hardware mode
flutter run --dart-define=USE_MOCK=false
```

The `controllerRepositoryProvider` in `providers.dart` reads `bool.fromEnvironment('USE_MOCK')` and returns the appropriate implementation. Because this is a compile-time constant, tree shaking removes the unused implementation from the release build.

## Navigation

GoRouter is configured in `core/router/app_router.dart`. All routes are named constants to avoid hardcoded path strings:

```dart
// core/router/app_router.dart
final appRouter = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppScaffold(child: child),
      routes: [
        GoRoute(
          path: '/',
          name: AppRoutes.map,
          builder: (_, __) => const MapScreen(),
        ),
        GoRoute(
          path: '/parking',
          name: AppRoutes.parking,
          builder: (_, __) => const ParkingScreen(),
        ),
        GoRoute(
          path: '/settings',
          name: AppRoutes.settings,
          builder: (_, __) => const SettingsPage(),
          routes: [
            GoRoute(
              path: 'leds',
              name: AppRoutes.ledSettings,
              builder: (_, __) => const LedSettingsPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
```

Navigate programmatically using named routes:

```dart
context.goNamed(AppRoutes.parking);
context.pushNamed(AppRoutes.ledSettings);
```

Never use hardcoded path strings like `context.go('/settings/leds')`.

## Localization

The app ships in English (`en`) and German (`de`). ARB files live in `app/lib/l10n/`:

```
app/lib/l10n/
├── app_en.arb    # English — source of truth
└── app_de.arb    # German — maintained by contributors / CI translation step
```

After editing any `.arb` file, regenerate the localization classes:

```bash
cd app
flutter gen-l10n
# or:
just gen
```

Never edit files in `app/lib/core/l10n/` (generated output) — they are overwritten on every `gen-l10n` run.

:::note
German translations in `app_de.arb` go through a review step before merge. Do not use machine-translated copy directly in UI strings — coordinate with maintainers if you need new translation strings added.
:::

## Key Domain Entities

| Entity | Location | Description |
|---|---|---|
| `NavCommand` | `features/nav/domain/nav_command.dart` | A single navigation instruction: `maneuver` (enum), `distanceM` (int), `streetName` (String) |
| `LedConfig` | `features/settings/domain/led_config.dart` | LED effect ID, brightness (0–255), color override, animation speed |
| `Telemetry` | `core/ble/telemetry.dart` | Speed in km/h, heading in degrees, battery percentage, firmware version |
| `SensorConfig` | `features/parking/domain/sensor_config.dart` | Four ultrasonic distances in cm, detection threshold, alert enabled flag |

## BLE Codecs

Raw BLE characteristic values are binary (`Uint8List`). Each entity has a dedicated codec in the `data/` layer of the relevant feature:

```
features/nav/data/nav_codec.dart          # NavCommand ↔ Uint8List
features/settings/data/led_config_codec.dart  # LedConfig ↔ Uint8List
```

Codec conventions:
- A codec is a plain class with two static methods: `encode(Entity) → Uint8List` and `decode(Uint8List) → Entity`.
- No nullable fields in encode output — use sentinel values (e.g., `0xFF`) for "not set."
- Byte order is little-endian throughout, matching the ESP32 default.
- Every codec has a corresponding `*_codec_test.dart` that round-trips representative values.

## Adding a New Feature

Follow these steps in order:

1. **Create the feature directory:**

   ```
   app/lib/features/<name>/
   ├── presentation/
   ├── domain/
   └── data/
   ```

2. **Define the domain entity and repository interface** in `domain/`.

3. **Implement the repository** in `data/`. If it needs BLE access, implement `IControllerRepository` or add a method to it.

4. **Add providers** to `core/di/providers.dart`.

5. **Add a GoRoute** to `core/router/app_router.dart` and a named constant to `AppRoutes`.

6. **Build the UI** using Atoms → Molecules → Organisms → Page, importing only downward in the hierarchy.

7. **Write tests:** unit tests for codec, domain logic, and provider; widget tests for key Organisms.

See [Testing](/contributing/testing/) for test conventions and how to mock providers in widget tests.
