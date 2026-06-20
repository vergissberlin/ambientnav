---
title: "Testing"
description: "Tests für die AmbientNav-App und Firmware ausführen und schreiben."
---

## Test-Stack der App

| Werkzeug | Rolle |
|---|---|
| `flutter test` | Test-Runner für alle Unit- und Widget-Tests |
| `mocktail` | Mocking-Bibliothek — `when()`, `verify()`, `any()`-Matcher |
| `MockControllerRepository` | Vollständiger BLE-Stub — ermöglicht alle Testszenarien ohne Hardware |
| `flutter_riverpod` `ProviderScope` | Provider-Overrides in Widget-Tests |
| Wokwi for VS Code | Firmware-Simulation mit echten GPIO- und UART-Interaktionen |

:::note
Das Testverzeichnis spiegelt das lib-Verzeichnis exakt wider. Eine Quelldatei unter `lib/features/parking/domain/sensor_config.dart` hat ihren Test unter `test/features/parking/domain/sensor_config_test.dart`. Wenn du eine Quelldatei hinzufügst, lege die entsprechende Testdatei im selben relativen Pfad an.
:::

## Tests ausführen

### Alle Tests

```bash
cd app
flutter test
```

Oder vom Repository-Wurzelverzeichnis aus über den Task-Runner:

```bash
just test
```

### Tests für ein bestimmtes Feature

```bash
cd app
flutter test test/features/parking/
flutter test test/features/nav/data/nav_codec_test.dart
```

### Mit Coverage-Bericht

```bash
cd app
flutter test --coverage

# Generate HTML report (requires lcov)
genhtml coverage/lcov.info -o coverage/html

# Open in browser
open coverage/html/index.html
```

Unter Linux installierst du lcov mit `sudo apt install lcov`, unter macOS mit `brew install lcov`.

Coverage wird in CI nicht als feste Mindestgrenze erzwungen, aber Reviewer werden PRs markieren, die die Abdeckung auf kritischen Pfaden (Codecs, Domain-Logik, Repository-Layer) reduzieren.

## Unit-Tests

Unit-Tests überprüfen reine Dart-Logik ohne Widget-Baum.

### BLE Codecs

Die Codec-Tests sind die kritischsten Unit-Tests im Projekt. Sie verifizieren die Round-Trip-Korrektheit des Binärprotokolls zwischen App und Firmware.

```dart
// test/features/nav/data/nav_codec_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ambientnav/features/nav/domain/nav_command.dart';
import 'package:ambientnav/features/nav/data/nav_codec.dart';

void main() {
  group('NavCodec', () {
    test('round-trips a TurnLeft command with 42 m distance', () {
      const original = NavCommand(
        maneuver: Maneuver.turnLeft,
        distanceM: 42,
        streetName: 'Hauptstraße',
      );

      final encoded = NavCodec.encode(original);
      final decoded = NavCodec.decode(encoded);

      expect(decoded.maneuver, equals(Maneuver.turnLeft));
      expect(decoded.distanceM, equals(42));
      expect(decoded.streetName, equals('Hauptstraße'));
    });

    test('handles maximum distance value (65535 m)', () {
      const cmd = NavCommand(maneuver: Maneuver.straight, distanceM: 65535, streetName: '');
      expect(NavCodec.decode(NavCodec.encode(cmd)).distanceM, equals(65535));
    });
  });
}
```

Entsprechend deckt `test/features/settings/data/led_config_codec_test.dart` die binäre Kodierung der LED-Konfiguration ab.

### Riverpod Providers

Teste Provider-Logik, indem du einen `ProviderContainer` mit Overrides instanziierst:

```dart
// test/core/di/providers_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambientnav/core/di/providers.dart';
import 'package:ambientnav/core/ble/mock_controller_repository.dart';

void main() {
  test('navCommandStreamProvider emits NavCommands from mock repo', () async {
    final container = ProviderContainer(
      overrides: [
        controllerRepositoryProvider.overrideWithValue(MockControllerRepository()),
      ],
    );
    addTearDown(container.dispose);

    final stream = container.read(navCommandStreamProvider.stream);
    await expectLater(stream, emits(isA<NavCommand>()));
  });
}
```

## Widget-Tests

Widget-Tests rendern einen Teil des Widget-Baums und überprüfen das Verhalten, ohne die vollständige App zu starten.

### Mock-Provider in Widget-Tests bereitstellen

Überschreibe Provider mit `ProviderScope` an der Wurzel des zu testenden Widgets:

```dart
// test/features/parking/presentation/parking_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ambientnav/core/di/providers.dart';
import 'package:ambientnav/features/parking/presentation/parking_screen.dart';

class MockRepo extends Mock implements IControllerRepository {}

void main() {
  testWidgets('ParkingScreen renders ParkingRadar organism', (tester) async {
    final mockRepo = MockRepo();

    when(() => mockRepo.sensorConfigStream).thenAnswer(
      (_) => Stream.value(const SensorConfig(
        distances: [42, 87, 210, 255],
        thresholdCm: 100,
        alertEnabled: true,
      )),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          controllerRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(home: ParkingScreen()),
      ),
    );

    await tester.pump();
    expect(find.byType(ParkingRadar), findsOneWidget);
  });
}
```

Verwende `tester.pump()`, um nach dem Einrichten asynchroner Daten einen Frame voranzurücken, und `tester.pumpAndSettle()`, um alle laufenden Animationen abzuschließen.

## MockControllerRepository

`MockControllerRepository` ist in `app/lib/core/ble/mock_controller_repository.dart` definiert. Es implementiert das vollständige `IControllerRepository`-Interface und liefert realistische Fake-Daten-Streams:

```dart
class MockControllerRepository implements IControllerRepository {
  @override
  Stream<NavCommand> get navCommandStream => Stream.periodic(
        const Duration(seconds: 3),
        (i) => NavCommand(
          maneuver: Maneuver.values[i % Maneuver.values.length],
          distanceM: 80 + (i * 17 % 400),
          streetName: _fakeStreets[i % _fakeStreets.length],
        ),
      );

  @override
  Stream<Telemetry> get telemetryStream => Stream.periodic(
        const Duration(milliseconds: 500),
        (i) => Telemetry(
          speedKmh: 30.0 + (i % 20),
          headingDeg: (i * 7) % 360,
          batteryPct: 85 - (i % 15),
          firmwareVersion: '1.2.0',
        ),
      );

  @override
  Stream<SensorConfig> get sensorConfigStream => Stream.periodic(
        const Duration(milliseconds: 200),
        (i) => SensorConfig(
          distances: [
            (42 + i * 3) % 255,
            (87 + i * 5) % 255,
            210,
            255,
          ],
          thresholdCm: 100,
          alertEnabled: true,
        ),
      );

  @override
  Future<void> sendLedConfig(LedConfig config) async {
    debugPrint('[MockRepo] sendLedConfig: $config');
  }

  @override
  Future<void> connect(String deviceId) async {}

  @override
  Future<void> disconnect() async {}
}
```

Da `MockControllerRepository` über `controllerRepositoryProvider` injiziert wird, läuft die gesamte App ohne Bluetooth-Hardware — praktisch für CI, Simulatoren und UI-Entwicklung.

## Integrationstests

Integrationstests starten die vollständige App auf einem verbundenen Gerät oder Emulator und steuern sie über den `flutter_test`-Treiber.

```bash
cd app
flutter test integration_test/
```

:::caution
Integrationstests werden **standardmäßig nicht in CI ausgeführt**, da sie ein verbundenes Gerät oder einen Emulator benötigen. Sie werden manuell vor größeren Releases oder dann ausgeführt, wenn ein PR die GoRouter-Konfiguration oder den Screen-Flow ändert. Falls deine Organisation einen selbst gehosteten GitHub Actions Runner mit verbundenem Gerät hat, kannst du den `integration_test`-Job in `build-app.yml` aktivieren, indem du seine `if: false`-Bedingung entfernst.
:::

Integrationstestdateien liegen in `app/integration_test/` und verwenden dieselbe `flutter_test`-API wie Widget-Tests, haben aber über `IntegrationTestWidgetsFlutterBinding` Zugriff auf die vollständig laufende App.

## Die vollständige App mit Mock-BLE ausführen

Für manuelle UI-Tests ohne Hardware:

```bash
flutter run --dart-define=USE_MOCK=true
```

Dieser Befehl startet das release-äquivalente App-Binary mit injiziertem `MockControllerRepository`. Alle Navigationsabläufe, Einparkradar-Animationen, LED-Konfigurationsscreens und BLE-Gerätescans verwenden Fake-Daten. Dies ist der empfohlene Weg, um UI-Änderungen vor dem Öffnen eines Pull Requests zu überprüfen.

## Firmware-Tests mit Wokwi

Wokwi simuliert die ESP32-Hardware einschließlich GPIO, UART, SPI und I2C-Peripherie.

1. Öffne die Datei `wokwi/rear/diagram.json` in VS Code.
2. Die Wokwi for VS Code-Erweiterung erkennt das PlatformIO-Projekt und bietet an, die **Simulation zu starten**.
3. Simuliere HC-SR04-Echopulse über das Wokwi GPIO-Panel, indem du den Echo-Pin hoch/niedrig schaltest.
4. Beobachte die serielle Monitorausgabe:
   ```
   [PROXIMITY][I] s0=42 s1=87 s2=210 s3=255
   [BT][I] Sent: {"s0":42,"s1":87,"s2":210,"s3":255}
   ```
5. Passe das Trigger-Timing an, um ein schnell herannahendes Hindernis zu simulieren, und überprüfe, ob der LED-Gradienteneffekt unterhalb der Schwellenentfernung aktiviert wird.

Wokwi führt dieselbe `.pio/build/esp32dev/firmware.bin` aus, die von `pio run` erzeugt wurde — keine Neukompilierung. Führe zuerst `pio run` aus, dann starte die Simulation.

## Einen neuen Test schreiben

### Namenskonvention

Alle Testdateien enden auf `_test.dart`. Der Test-Runner erkennt sie automatisch.

### Arrange / Act / Assert

Strukturiere jeden Testfall in drei beschriftete Abschnitte:

```dart
test('LedConfigCodec encodes brightness=128 correctly', () {
  // Arrange
  const config = LedConfig(
    effectId: 2,
    brightness: 128,
    colorOverride: null,
    animationSpeed: 50,
  );

  // Act
  final bytes = LedConfigCodec.encode(config);

  // Assert
  expect(bytes[0], equals(2));    // effect ID byte
  expect(bytes[1], equals(128));  // brightness byte
});
```

### Mocktail-Muster

```dart
// Stub a method to return a value
when(() => mockRepo.connect(any())).thenAnswer((_) async {});

// Stub a stream
when(() => mockRepo.navCommandStream).thenAnswer(
  (_) => Stream.value(fakeNavCommand),
);

// Verify a method was called exactly once
verify(() => mockRepo.sendLedConfig(captureAny())).called(1);

// Capture the argument for deeper assertion
final captured = verify(() => mockRepo.sendLedConfig(captureAny())).captured;
expect((captured.first as LedConfig).brightness, equals(200));
```

Die vollständige API-Referenz findest du in der [mocktail-Dokumentation](https://pub.dev/packages/mocktail).
