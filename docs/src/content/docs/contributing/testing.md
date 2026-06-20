---
title: "Testing"
description: "How to run and write tests for the AmbientNav app and firmware."
---

## App Testing Stack

| Tool | Role |
|---|---|
| `flutter test` | Test runner for all unit and widget tests |
| `mocktail` | Mocking library — `when()`, `verify()`, `any()` matchers |
| `MockControllerRepository` | Full BLE stub — enables all test scenarios without hardware |
| `flutter_riverpod` `ProviderScope` | Provider overrides in widget tests |
| Wokwi for VS Code | Firmware simulation with real GPIO and UART interaction |

:::note
The test directory mirrors the lib directory exactly. A source file at `lib/features/parking/domain/sensor_config.dart` has its test at `test/features/parking/domain/sensor_config_test.dart`. If you add a source file, add the corresponding test file in the same relative path.
:::

## Running the Tests

### All tests

```bash
cd app
flutter test
```

Or from the repository root using the task runner:

```bash
just test
```

### Tests for a specific feature

```bash
cd app
flutter test test/features/parking/
flutter test test/features/nav/data/nav_codec_test.dart
```

### With coverage report

```bash
cd app
flutter test --coverage

# Generate HTML report (requires lcov)
genhtml coverage/lcov.info -o coverage/html

# Open in browser
open coverage/html/index.html
```

On Linux, install lcov with `sudo apt install lcov`. On macOS: `brew install lcov`.

Coverage is not enforced as a hard threshold in CI, but reviewers will flag PRs that reduce coverage on critical paths (codecs, domain logic, repository layer).

## Unit Tests

Unit tests cover pure Dart logic with no widget tree.

### BLE Codecs

The codec tests are the most critical unit tests in the project. They verify round-trip correctness of the binary protocol between app and firmware.

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

Similarly, `test/features/settings/data/led_config_codec_test.dart` covers the LED configuration binary encoding.

### Riverpod Providers

Test provider logic by instantiating a `ProviderContainer` with overrides:

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

## Widget Tests

Widget tests render a subset of the widget tree and verify behavior without running the full app.

### Providing Mock Providers in Widget Tests

Override providers using `ProviderScope` at the root of the widget under test:

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

Use `tester.pump()` to advance one frame after setting up async data, and `tester.pumpAndSettle()` to drain all pending animations.

## MockControllerRepository

`MockControllerRepository` is defined in `app/lib/core/ble/mock_controller_repository.dart`. It implements the full `IControllerRepository` interface and provides realistic fake data streams:

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

Because `MockControllerRepository` is injected via `controllerRepositoryProvider`, the entire app runs without any Bluetooth hardware — useful for CI, simulators, and UI development.

## Integration Tests

Integration tests run the full app on a connected device or emulator and drive it via the `flutter_test` driver.

```bash
cd app
flutter test integration_test/
```

:::caution
Integration tests are **not run in CI by default** because they require a connected device or emulator. They are run manually before significant releases or when a PR changes the GoRouter configuration or screen flow. If your organization has a self-hosted GitHub Actions runner with a connected device, you can enable the `integration_test` job in `build-app.yml` by removing its `if: false` condition.
:::

Integration test files live in `app/integration_test/` and use the same `flutter_test` API as widget tests, but have access to the full running app via `IntegrationTestWidgetsFlutterBinding`.

## Running the Full App with Mock BLE

For full manual UI testing without hardware:

```bash
flutter run --dart-define=USE_MOCK=true
```

This runs the release-equivalent app binary with `MockControllerRepository` injected. All navigation flows, parking radar animations, LED config screens, and BLE device scans use fake data. It is the recommended way to verify UI changes before opening a pull request.

## Firmware Testing with Wokwi

Wokwi simulates the ESP32 hardware, including GPIO, UART, SPI, and I2C peripherals.

1. Open the `wokwi/rear/diagram.json` file in VS Code.
2. The Wokwi for VS Code extension detects the PlatformIO project and offers to **Start Simulation**.
3. Use the Wokwi GPIO panel to simulate HC-SR04 echo pulses by toggling the echo pin high/low.
4. Observe the serial monitor output:
   ```
   [PROXIMITY][I] s0=42 s1=87 s2=210 s3=255
   [BT][I] Sent: {"s0":42,"s1":87,"s2":210,"s3":255}
   ```
5. Adjust trigger timing to simulate a fast-approaching obstacle and verify the LED gradient effect activates below the threshold distance.

Wokwi runs the same `.pio/build/esp32dev/firmware.bin` produced by `pio run` — not a re-compilation. Run `pio run` first, then start the simulation.

## Writing a New Test

### Naming Convention

All test files end in `_test.dart`. The test runner discovers them automatically.

### Arrange / Act / Assert

Structure every test case in three labeled sections:

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

### Mocktail Patterns

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

See [mocktail documentation](https://pub.dev/packages/mocktail) for the full API reference.
