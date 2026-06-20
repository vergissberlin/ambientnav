---
title: Testing
description: Tests für die AmbientNav Flutter-App und ESP32-Firmware ausführen und schreiben.
---

AmbientNav verwendet zwei verschiedene Teststrategien: **Flutter Unit- und Widget-Tests** für den App-Layer sowie **Wokwi-Hardware-Simulation** für die Firmware-Validierung.

---

## App-Tests (Flutter)

### Tests ausführen

Aus dem Verzeichnis `app/`:

```bash
# Alle Tests ausführen
flutter test

# Ein bestimmtes Verzeichnis ausführen
flutter test test/features/controllers/

# Eine einzelne Datei ausführen
flutter test test/features/controllers/ble/codecs/nav_codec_test.dart

# Mit Coverage ausführen
flutter test --coverage
```

Die Test-Suite läuft vollständig im Prozess — kein physisches Gerät oder BLE-Hardware erforderlich.

### Teststruktur

```
app/test/
├── features/
│   ├── controllers/
│   │   ├── ble/
│   │   │   └── codecs/          # Codec-Unit-Tests (nav, led, telemetry, sensor, ota)
│   │   ├── data/
│   │   │   └── mock/            # MockControllerRepository-Tests
│   │   └── presentation/        # Widget-Tests für Formulare und Screens
│   └── navigation/
│       └── presentation/        # Widget-Tests für Nav-Screen und Abbiegepanel
└── core/
    └── widgets/                 # Atom- und Molecule-Widget-Tests
```

### MockControllerRepository

Der gesamte BLE-Layer kann zur Compile-Zeit über das `USE_MOCK` dart-define-Flag durch einen Mock ersetzt werden. Der Mock implementiert dasselbe `ControllerRepository`-Interface und liefert deterministische Daten zurück.

Verwende `MockControllerRepository` direkt in Tests:

```dart
import 'package:ambientnav/features/controllers/data/mock/mock_controller_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockRepo extends Mock implements ControllerRepository {}

void main() {
  late MockRepo repo;

  setUp(() {
    repo = MockRepo();
    when(() => repo.connect(any())).thenAnswer((_) async {});
  });

  test('connects to controller', () async {
    await repo.connect('device-id');
    verify(() => repo.connect('device-id')).called(1);
  });
}
```

Verwende `mocktail` (nicht `mockito`) für alle Mocks — es erfordert keine Code-Generierung.

### Codec-Unit-Tests

Die BLE-Codecs sind die wichtigsten unit-testbaren Komponenten. Jeder Codec hat einen entsprechenden Test, der Encode → Decode als Roundtrip prüft:

```dart
void main() {
  test('NavCodec encodes direction and distance', () {
    final bytes = NavCodec.encode(direction: Direction.left, distanceM: 120, indicator: Indicator.left);
    expect(bytes, equals([0x01, 0x78, 0x01]));
  });

  test('NavCodec round-trips cleanly', () {
    final original = NavCommand(direction: Direction.right, distanceM: 45, indicator: Indicator.right);
    final decoded = NavCodec.decode(NavCodec.encode(original));
    expect(decoded, equals(original));
  });
}
```

Wenn du eine neue Characteristic hinzufügst oder ein Codec-Format änderst, **aktualisiere zuerst den entsprechenden Test**.

### Widget-Tests

Widget-Tests verwenden `ProviderScope`-Overrides, um Mock-Daten zu injizieren:

```dart
testWidgets('LedConfigForm shows current LED count', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ledConfigProvider.overrideWith((_) => LedConfig(ledCount: 60, brightness: 128, effect: Effect.ambient)),
      ],
      child: const MaterialApp(home: LedConfigForm()),
    ),
  );

  expect(find.text('60'), findsOneWidget);
});
```

### App mit Mock-BLE ausführen

Du kannst die vollständige App ohne Hardware über das `USE_MOCK` dart-define starten:

```bash
flutter run --dart-define=USE_MOCK=true
```

Oder über den Justfile-Shortcut:

```bash
just run
```

Damit wird der echte `flutter_blue_plus` BLE-Layer durch deterministische Mock-Daten ersetzt — Navigationsscreen, Abbiegepanel, LED-Konfigurationsformulare und Telemetrieanzeigen funktionieren vollständig.

---

## Firmware-Tests (Wokwi)

Hardware-unabhängige Firmware-Tests nutzen **Wokwi**, einen browserbasierten Mikrocontroller-Simulator. Diagramme für beide Platinen sind im Verzeichnis `wokwi/` vorkonfiguriert.

### Einrichtung

1. Installiere die **Wokwi for VS Code**-Erweiterung.
2. Öffne `wokwi/front/diagram.json` oder `wokwi/rear/diagram.json` in VS Code.
3. Drücke **F1 → Wokwi: Start Simulator**.

Der Simulator liest die kompilierte Firmware aus PlatformIO's Build-Output — baue zuerst:

```bash
cd firmware/front
pio run
# oder
cd firmware/rear
pio run
```

### Was Wokwi abdeckt

| Szenario | Wokwi-Unterstützung |
|---|---|
| BLE GATT Advertising und Characteristic Writes | Teilweise (simulierter BLE-Host) |
| FastLED Pixel-Ausgabe auf GPIO | Ja — LED-Streifen wird visualisiert |
| HC-SR04 Echo-Timing | Ja — einstellbarer Slider im Diagramm |
| FreeRTOS-Task-Scheduling | Ja |
| Serielle Ausgabe (`Serial.println`) | Ja — Serial-Monitor-Tab |
| Bluetooth Classic SPP zwischen zwei Platinen | Nicht unterstützt (Einzelplatinen-Simulation) |

Für vollständige Zwei-Platinen-Integrationstests: echte Hardware verwenden.

### Sensoreingabe simulieren

Im Hinterplatinen-Diagramm werden HC-SR04-Sensoren als interaktive Slider dargestellt. Ziehe den Slider, um die simulierte Distanz anzupassen. Die Hinter-LED-Streifen-Visualisierung aktualisiert sich in Echtzeit und bestätigt, dass die Distanz → Füllprozent-Formel in `led_effects.cpp` korrekt ist.

---

## CI-Integration

Der Workflow `build-app.yml` führt die vollständige Test-Suite bei jedem Push aus:

```yaml
- run: flutter analyze
- run: flutter test
```

Tests laufen gegen den Mock-BLE-Layer — kein Gerät in CI erforderlich. Ein fehlgeschlagener Test oder eine Analyzer-Warnung blockiert den Build.

:::tip
Führe `flutter analyze` lokal vor dem Push aus. Es findet Typfehler und Lint-Verstöße, die die Test-Suite nicht abdeckt.
:::

---

## Neue Tests schreiben

### Checkliste

- Eine Test-Datei pro Quelldatei: `nav_codec.dart` → `nav_codec_test.dart`
- **Arrange / Act / Assert**-Struktur verwenden
- Den öffentlichen Vertrag testen, nicht interne Implementierungsdetails
- Randfälle abdecken: Null-Distanz, maximale Distanz (255 m), außerhalb des Bereichs liegende Sensorwerte (999)
- Kein Framework-Verhalten testen (z. B. nicht testen, dass `Riverpod` State speichert)

### Was einen Test erfordert

| Änderung | Test erforderlich |
|---|---|
| Neuer BLE-Codec oder Codec-Format-Änderung | Ja — Unit-Test mit Encode + Decode |
| Neues Widget mit Business-Logik | Ja — Widget-Test |
| Neuer Riverpod-Provider | Ja — Unit-Test mit Mock-Abhängigkeiten |
| Neuer LED-Effekt (Firmware) | Ja — Wokwi-Simulation validiert die visuelle Ausgabe |
| UI-Texte oder Styling-Änderung | Nein |
| Config-Konstanten-Änderung | Nein |
