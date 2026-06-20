---
title: "Flutter App"
description: "Architekturleitfaden und Entwicklungskonventionen für die AmbientNav Flutter-Anwendung."
---

## Verzeichnisstruktur

Der gesamte App-Quellcode liegt unter `app/lib/`. Zwei Top-Level-Verzeichnisse enthalten alles:

```
app/lib/
├── core/                    # Gemeinsame Infrastruktur, die alle Features nutzen
│   ├── di/
│   │   └── providers.dart   # Alle Riverpod-Provider, zentralisiert
│   ├── router/
│   │   └── app_router.dart  # GoRouter-Konfiguration, ShellRoute, Named Routes
│   ├── theme/
│   │   └── app_theme.dart   # Design-Token-Konstanten (AppTheme.signalCyan, etc.)
│   ├── ble/
│   │   ├── i_controller_repository.dart      # BLE-Abstraktionsinterface
│   │   ├── bluetooth_controller_repository.dart  # Echte BLE-Implementierung
│   │   └── mock_controller_repository.dart   # Mock für CI + Mock-Run-Modus
│   └── l10n/                # Generierte Lokalisierungsklassen (nicht manuell bearbeiten)
└── features/
    ├── nav/                 # Abbiegung-für-Abbiegung-Navigation (MapLibre, Valhalla/OSRM)
    ├── ble/                 # BLE-Geräteerkennung und Verbindungsverwaltung
    ├── parking/             # Einparkhilfe-UI, Proximity-Radar-Visualisierung
    └── settings/            # App-Einstellungen, LED-Konfiguration, Geräteinformationen
```

## Feature-Strukturmuster

Jedes Feature folgt demselben Drei-Schichten-Aufbau:

```
features/<feature>/
├── presentation/        # Widgets, Screens, Controller (ConsumerWidget-Subklassen)
├── domain/              # Entities, Use Cases, Repository-Interfaces (reines Dart)
└── data/                # Repository-Implementierungen, Codecs, lokale Datenquellen
```

- **Presentation** hängt von domain ab. Sie greift niemals direkt auf `data/` zu.
- **Domain** hat null Flutter-Abhängigkeiten — ausschließlich reine Dart-Klassen und Interfaces.
- **Data** implementiert Domain-Interfaces und darf Packages nutzen (Hive, http, flutter_blue_plus).

Feature-übergreifende Abhängigkeiten laufen ausschließlich über `core/`. Ein Feature importiert niemals aus dem `presentation/`-Layer eines anderen Features.

## Riverpod State Management

Alle Provider sind in `core/di/providers.dart` definiert. Provider über Feature-Verzeichnisse zu verstreuen macht das Nachverfolgen von Abhängigkeiten schwierig — halte sie zentralisiert.

```dart
// core/di/providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambientnav/core/ble/i_controller_repository.dart';
import 'package:ambientnav/core/ble/bluetooth_controller_repository.dart';
import 'package:ambientnav/core/ble/mock_controller_repository.dart';

// Über compile-time dart-define definiert; beim Start aufgelöst
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

In Widgets verwendest du `ConsumerWidget` oder `ConsumerStatefulWidget`:

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

Verwende `ref.invalidate()` oder `ref.refresh()` sparsam — bevorzuge reaktive Streams statt manuellem Cache-Busting.

## Atomic Design-Hierarchie

Komponenten sind in Schichten organisiert. Jede Schicht baut auf der darunter liegenden auf. **Imports fließen nur abwärts** — Organisms dürfen Molecules und Atoms verwenden, aber nicht umgekehrt.

### Quarks — Design Foundation

Quarks sind keine Widgets. Sie sind Token-Konstanten und Theme-Definitionen in `core/theme/app_theme.dart`. Keine visuelle Komponente; sie existieren nur, um von höheren Schichten referenziert zu werden.

```
AppTheme.signalCyan        → Color(0xFF00D4FF)
AppTheme.backgroundDeep    → Color(0xFF0A0A0F)
AppTheme.fontDisplay       → 'Space Grotesk'
AppTheme.spacingMd         → 16.0
```

### Atoms — Einzelzweck-Primitive

Kleine, zustandslose (oder nahezu zustandslose) Widgets ohne Business-Logik:

| Atom | Beschreibung |
|---|---|
| `RssiIndicator` | RSSI-Signalstärke-Balken (1–5 Balken), nimmt `int rssi` |
| `BatteryGauge` | Akkustandsbalken mit Farb-Schwellenwert (grün/gelb/rot) |
| `SpeedReadout` | Formatiertes km/h-Label in großer Display-Schrift |
| `LedCountBadge` | Pill-Badge mit aktiver LED-Anzahl |
| `SignalDot` | Animierter Punkt zur Anzeige des BLE-Verbindungsstatus |

### Molecules — Zusammengesetzte UI-Einheiten

Molecules kombinieren Atoms zu sinnvollen UI-Gruppen:

| Molecule | Beschreibung |
|---|---|
| `DeviceListTile` | Gescannter BLE-Geräteeintrag: Gerätename, RSSI-Indikator, Verbinden-Button |
| `RouteInfoCard` | Aktuelle Routenzusammenfassung: Entfernung, ETA, nächstes Manöver-Icon |
| `ProximityReading` | Einzelnes Sensor-Entfernungslabel + Warnicon |
| `LedBrightnessRow` | Label + Slider + Vorschau-Punkt für einen LED-Kanal |

### Organisms — Komplexe Feature-Abschnitte

Organisms implementieren einen vollständigen Feature-Abschnitt und dürfen lokalen State enthalten:

| Organism | Beschreibung |
|---|---|
| `LedConfigForm` | Vollständiges LED-Konfigurationspanel: Effekt-Picker, Helligkeits-Slider, Farbvorschau |
| `ParkingRadar` | Animierte Vogelperspektive des Fahrzeugs mit Proximity-Bögen für jeden Ultraschallsensor |
| `DeviceScanner` | BLE-Scan-Controller: Scan-Indikator, Geräteliste, Verbinden/Trennen |
| `NavManeuverBanner` | Dauerhaftes unteres Banner: nächste Abbiegeinstruktion, Entfernung, Straßenname |

### Pages

Pages sind vollständige Screens, die im GoRouter registriert sind. Sie verdrahten Riverpod-Provider und setzen Organisms zusammen:

| Page | Route | Beschreibung |
|---|---|---|
| `MapScreen` | `/` | MapLibre-Kartenansicht + `NavManeuverBanner`-Overlay |
| `ParkingScreen` | `/parking` | Vollbild-`ParkingRadar`-Organism |
| `DeviceScanScreen` | `/ble/scan` | BLE-Geräteerkennung und Pairing |
| `LedSettingsPage` | `/settings/leds` | `LedConfigForm` in einem Settings-Scaffold |
| `SettingsPage` | `/settings` | App-Einstellungsliste |

## BLE-Abstraktionsschicht

Die BLE-Schicht ist hinter dem `IControllerRepository`-Interface versteckt. Die App ruft `flutter_blue_plus`-APIs niemals direkt aus UI-Code auf.

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

`BluetoothControllerRepository` ist die Produktionsimplementierung, die `flutter_blue_plus` verwendet. `MockControllerRepository` gibt periodische Fake-Daten-Streams zurück — keine Bluetooth-Hardware erforderlich.

Der Wechsel zwischen echter und gemockter Implementierung wird zur Compile-Zeit über das `USE_MOCK` dart-define aufgelöst:

```bash
# Mock-Modus (CI, Simulator, UI-Entwicklung)
flutter run --dart-define=USE_MOCK=true

# Echter Hardware-Modus
flutter run --dart-define=USE_MOCK=false
```

Der `controllerRepositoryProvider` in `providers.dart` liest `bool.fromEnvironment('USE_MOCK')` und gibt die passende Implementierung zurück. Da es sich um eine Compile-Time-Konstante handelt, entfernt Tree Shaking die nicht verwendete Implementierung aus dem Release-Build.

## Navigation

GoRouter ist in `core/router/app_router.dart` konfiguriert. Alle Routen sind benannte Konstanten, um hartcodierte Pfad-Strings zu vermeiden:

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

Navigiere programmatisch mit benannten Routen:

```dart
context.goNamed(AppRoutes.parking);
context.pushNamed(AppRoutes.ledSettings);
```

Verwende niemals hartcodierte Pfad-Strings wie `context.go('/settings/leds')`.

## Lokalisierung

Die App wird in Englisch (`en`) und Deutsch (`de`) ausgeliefert. ARB-Dateien liegen in `app/lib/l10n/`:

```
app/lib/l10n/
├── app_en.arb    # Englisch — Quelle der Wahrheit
└── app_de.arb    # Deutsch — von Beitragenden / CI-Übersetzungsschritt gepflegt
```

Nachdem du eine `.arb`-Datei bearbeitet hast, generierst du die Lokalisierungsklassen neu:

```bash
cd app
flutter gen-l10n
# oder:
just gen
```

Bearbeite niemals Dateien in `app/lib/core/l10n/` (generierter Output) — sie werden bei jedem `gen-l10n`-Lauf überschrieben.

:::note
Deutsche Übersetzungen in `app_de.arb` durchlaufen vor dem Merge einen Review-Schritt. Verwende keine maschinell übersetzten Texte direkt in UI-Strings — stimme mit Maintainern ab, wenn du neue Übersetzungsstrings hinzufügen musst.
:::

## Wichtige Domain-Entities

| Entity | Speicherort | Beschreibung |
|---|---|---|
| `NavCommand` | `features/nav/domain/nav_command.dart` | Eine einzelne Navigationsanweisung: `maneuver` (enum), `distanceM` (int), `streetName` (String) |
| `LedConfig` | `features/settings/domain/led_config.dart` | LED-Effekt-ID, Helligkeit (0–255), Farbüberschreibung, Animationsgeschwindigkeit |
| `Telemetry` | `core/ble/telemetry.dart` | Geschwindigkeit in km/h, Kurs in Grad, Akkustand in Prozent, Firmware-Version |
| `SensorConfig` | `features/parking/domain/sensor_config.dart` | Vier Ultraschalldistanzen in cm, Erkennungsschwellenwert, Alert-aktiviert-Flag |

## BLE-Codecs

Rohe BLE-Characteristic-Werte sind binär (`Uint8List`). Jede Entity hat einen dedizierten Codec im `data/`-Layer des jeweiligen Features:

```
features/nav/data/nav_codec.dart          # NavCommand ↔ Uint8List
features/settings/data/led_config_codec.dart  # LedConfig ↔ Uint8List
```

Codec-Konventionen:
- Ein Codec ist eine einfache Klasse mit zwei statischen Methoden: `encode(Entity) → Uint8List` und `decode(Uint8List) → Entity`.
- Keine nullable Felder in der Encode-Ausgabe — verwende Sentinel-Werte (z. B. `0xFF`) für "nicht gesetzt".
- Byte-Reihenfolge ist durchgehend Little-Endian, passend zum ESP32-Standard.
- Jeder Codec hat eine entsprechende `*_codec_test.dart`, die repräsentative Werte hin und zurück testet.

## Ein neues Feature hinzufügen

Folge diesen Schritten in der angegebenen Reihenfolge:

1. **Feature-Verzeichnis erstellen:**

   ```
   app/lib/features/<name>/
   ├── presentation/
   ├── domain/
   └── data/
   ```

2. **Domain-Entity und Repository-Interface definieren** in `domain/`.

3. **Repository implementieren** in `data/`. Wenn BLE-Zugriff benötigt wird, implementiere `IControllerRepository` oder füge eine Methode hinzu.

4. **Provider hinzufügen** zu `core/di/providers.dart`.

5. **Eine GoRoute hinzufügen** zu `core/router/app_router.dart` und eine benannte Konstante zu `AppRoutes`.

6. **Die UI bauen** mit Atoms → Molecules → Organisms → Page, dabei nur abwärts in der Hierarchie importieren.

7. **Tests schreiben:** Unit-Tests für Codec, Domain-Logik und Provider; Widget-Tests für wichtige Organisms.

Lies [Testing](/de/contributing/testing/) für Test-Konventionen und wie du Provider in Widget-Tests mockst.
