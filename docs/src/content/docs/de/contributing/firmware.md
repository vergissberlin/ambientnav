---
title: "Firmware-Entwicklung"
description: "ESP32-Firmware für die Vorder- und Hinterplatine von AmbientNav bauen, flashen und erweitern."
---

## Zwei PlatformIO-Projekte

Die Firmware besteht aus zwei unabhängigen PlatformIO-Projekten, eines für jede physische Platine:

| Projekt | Pfad | Rolle |
|---|---|---|
| **Vorderplatine** | `firmware/front/` | BLE GATT-Server, Navigations-LED-Effekte, BT Classic Host (empfängt Sensordaten der Hinterplatine), Orchestrator |
| **Hinterplatine** | `firmware/rear/` | Ultraschall-Proximity-Sensing, hintere LED-Effekte, BT Classic Client (sendet Sensordaten an Vorderplatine) |

Jedes Projekt ist eigenständig mit eigener `platformio.ini`, `src/`- und `include/`-Verzeichnis. Sie teilen keine Quelldateien — das gemeinsame Protokoll ist zur Laufzeit durch die JSON-over-BT-Classic-SPP-Verbindung definiert.

## Vorderplatine: Wichtige Quelldateien

| Datei | Beschreibung |
|---|---|
| `src/main.cpp` | Einstiegspunkt: Hardware-Init, FreeRTOS-Task-Erstellung, `app_main()` |
| `src/ble_server.cpp` | NimBLE GATT-Server-Setup: Service UUID, Characteristic-Registrierung, Verbindungs-Callbacks |
| `src/bt_classic.cpp` | ESP-IDF SPP Host: akzeptiert eingehende Verbindung von der Hinterplatine, empfängt JSON-Sensorframes |
| `src/orchestrator.cpp` | `OrchestratorAgent` FreeRTOS-Task: 10-ms-Tick, dispatcht Nav-Befehle und Sensordaten an LED-Effekte |
| `src/led_effects.cpp` | Alle LED-Animationsfunktionen: Richtungspfeile, Proximity-Gradienten, Idle-Puls, Alert-Flash |
| `src/gatt_ext.cpp` | Erweiterte GATT-Characteristic-Handler: LedConfig Write, Telemetry Notify, SensorConfig Notify |
| `src/battery.cpp` | ADC-basierte Batteriespannungsmessung, Prozentberechnung mit Glättung |
| `include/config.h` | Alle GPIO-Pins, LED-Streifenlänge, Timing-Konstanten, BLE-Service- und Characteristic-UUIDs |

## Hinterplatine: Wichtige Quelldateien

| Datei | Beschreibung |
|---|---|
| `src/main.cpp` | Einstiegspunkt: Hardware-Init, FreeRTOS-Task-Erstellung |
| `src/ultrasonic.cpp` | HC-SR04 Trigger/Echo-Zyklus für vier Sensoren, Distanzberechnung in cm |
| `src/bt_classic.cpp` | ESP-IDF SPP Client: verbindet sich mit Vorderplatinen-MAC, überträgt JSON-Sensorframes alle 30 ms |
| `src/led_effects.cpp` | Hintere LED-Animationen: Proximity-Farbskala, Brems-Flash |
| `src/sensor_store.cpp` | Thread-sicherer Sensor-Reading-Cache, genutzt von SPP-Transmit-Task und LED-Task |
| `include/config.h` | GPIO-Zuweisungen, Sensoranzahl, LED-Anzahl, Timing-Konstanten, MAC-Adresse der Vorderplatine |

## FreeRTOS-Task-Modell

Die Firmware verwendet eine **Message-Passing-Architektur** über FreeRTOS-Queues. Tasks greifen niemals über gemeinsame Globals auf die Daten anderer Tasks zu.

### Vorderplatinen-Tasks

| Task | Priorität | Stack | Periode | Aufgabe |
|---|---|---|---|---|
| `OrchestratorAgent` | 5 | 8 KB | 10 ms | Liest Queues, entscheidet aktiven Effekt, ruft FastLED auf |
| `BleTask` | 4 | 6 KB | ereignisgesteuert | Verarbeitet GATT-Characteristic-Reads/Writes, benachrichtigt App |
| `BtClassicRxTask` | 3 | 4 KB | ereignisgesteuert | Empfängt Sensor-JSON von Hinterplatine, schreibt in Sensor-Queue |
| `BatteryTask` | 1 | 2 KB | 5 s | Liest ADC, aktualisiert Battery-Level-Characteristic |

### Hinterplatinen-Tasks

| Task | Priorität | Stack | Periode | Aufgabe |
|---|---|---|---|---|
| `ProximityAgent` | 5 | 4 KB | 30 ms | Triggert Ultraschallsensoren, speichert Messwerte in `SensorStore` |
| `BtClassicTxTask` | 4 | 4 KB | 30 ms | Liest `SensorStore`, serialisiert zu JSON, sendet via SPP |
| `LedTask` | 3 | 4 KB | 40 ms | Liest `SensorStore`, wendet hinteren LED-Effekt an, ruft FastLED auf |

### Warum Queues statt Shared Globals

Ein roher globaler Struct, der durch einen Mutex geschützt wird, birgt Priority-Inversion-Risiken und koppelt Tasks eng aneinander. FreeRTOS-Queues dagegen:

- Übergeben Dateneigentümerschaft atomar zwischen Tasks
- Bieten natürlichen Gegendruck (eine volle Queue signalisiert dem Produzenten, zu verlangsamen)
- Machen den Datenfluss explizit und nachvollziehbar im Task-Modell

Der Sensordatenpfad auf der Vorderplatine: `BtClassicRxTask` → `xSensorQueue` (10 Elemente, überschreibt ältestes bei Überlauf) → `OrchestratorAgent`.

## Einen neuen LED-Effekt hinzufügen

Folge diesen vier Schritten:

**1. Die Effekt-ID zum Enum in `include/config.h` hinzufügen:**

```cpp
// include/config.h
enum class LedEffect : uint8_t {
  kOff         = 0x00,
  kNavArrow    = 0x01,
  kProximity   = 0x02,
  kIdlePulse   = 0x03,
  kAlertFlash  = 0x04,
  kYourEffect  = 0x05,  // <-- hier einfügen
};
```

**2. Die Effektfunktion in `src/led_effects.cpp` implementieren:**

```cpp
// Non-blocking: verwendet millis()-Delta, nie delay()
void EffectYourEffect(CRGB* leds, int num_leds, uint32_t now_ms) {
  static uint32_t last_ms = 0;
  static uint8_t phase = 0;

  if (now_ms - last_ms < 50) return;  // 20 Hz Update-Rate
  last_ms = now_ms;

  // ... leds[i]-Werte setzen ...
}
```

Deklariere die Funktion in `include/led_effects.h`.

**3. Den neuen Effekt in `src/orchestrator.cpp` behandeln:**

```cpp
case LedEffect::kYourEffect:
  EffectYourEffect(leds, kLedCount, millis());
  break;
```

**4. `FastLED.show()` nur im Orchestrator aufrufen** — niemals innerhalb von `EffectYourEffect()`. Der Orchestrator ist der einzige Aufrufer von `FastLED.show()`, um Race Conditions zu verhindern.

## BLE-Stack: NimBLE-Arduino

Die Vorderplatine verwendet **NimBLE-Arduino** (nicht den Standard-Bluedroid oder den nativen ESP-IDF BLE-Stack).

**Warum NimBLE?**
- Bluedroid belegt ungefähr 100 KB Heap; NimBLE nur ~35 KB
- Die Vorderplatine betreibt BLE und BT Classic gleichzeitig — die RAM-Einsparung ist entscheidend
- NimBLEs API ist für GATT-Server-Anwendungsfälle übersichtlicher

Wichtige NimBLE API-Muster:

```cpp
// ble_server.cpp — Server-Setup
NimBLEServer* pServer = NimBLEDevice::createServer();
pServer->setCallbacks(new ServerCallbacks());

NimBLEService* pSvc = pServer->createService(kServiceUUID);

NimBLECharacteristic* pNavChar = pSvc->createCharacteristic(
    kNavCommandUUID,
    NIMBLE_PROPERTY::NOTIFY
);

pSvc->start();
NimBLEAdvertising* pAdv = NimBLEDevice::getAdvertising();
pAdv->addServiceUUID(kServiceUUID);
pAdv->start();
```

```cpp
// Characteristic-Write-Callback
class LedConfigCallbacks : public NimBLECharacteristicCallbacks {
  void onWrite(NimBLECharacteristic* pChar) override {
    std::string val = pChar->getValue();
    LedConfig cfg = DecodeLedConfig(
        reinterpret_cast<const uint8_t*>(val.data()), val.size());
    xQueueOverwrite(xLedConfigQueue, &cfg);
  }
};
```

## Bluetooth Classic SPP: Hinterplatine → Vorderplatine

Die Hinterplatine überträgt Sensormesswerte über eine Bluetooth Classic SPP-Verbindung (Serial Port Profile) an die Vorderplatine, implementiert mit dem ESP-IDF `esp_spp_api.h`.

**Protokoll:** Zeilengetrennte JSON-Frames, ein Frame pro Übertragungszyklus (30 ms):

```json
{"s0":42,"s1":87,"s2":210,"s3":255}\n
```

Die Felder `s0`–`s3` sind die vier Ultraschall-Sensordistanzen in Zentimetern. `255` bedeutet "kein Hindernis erkannt" (außerhalb des Messbereichs). Parsing auf der Vorderplatine:

```cpp
// bt_classic.cpp (Empfangsseite Vorderplatine)
void ParseSensorFrame(const char* json_str, SensorReading* out) {
  // Leichtgewichtiges manuelles Parsen — kein Heap-Alloc im ISR-Kontext
  sscanf(json_str, "{\"s0\":%hhu,\"s1\":%hhu,\"s2\":%hhu,\"s3\":%hhu}",
         &out->dist[0], &out->dist[1], &out->dist[2], &out->dist[3]);
}
```

**Warum SPP statt BLE für die Hinter-zu-Vorder-Verbindung?**
Die Vorderplatine fungiert bereits als BLE GATT-Server für das Smartphone. Gleichzeitig als BLE Central zu laufen (um sich mit der Hinterplatine zu verbinden) ist auf demselben ESP32 mit NimBLE aufgrund von Controller-Scheduling-Konflikten instabil. SPP läuft über das Classic-Bluetooth-Radio, das sich zwar das 2,4-GHz-Band teilt, aber einen separaten Controller-Pfad nutzt.

## FastLED-Hinweise

:::caution
**Rufe `FastLED.show()` niemals aus mehr als einem FreeRTOS-Task auf.** `FastLED.show()` treibt die LED-Datenleitung via Bit-Banging an und deaktiviert dabei für die gesamte Dauer die Interrupts. Ein Aufruf aus zwei Tasks gleichzeitig korrumpiert den LED-Frame und kann das System zum Absturz bringen. Der `OrchestratorAgent` ist der **einzige** Aufrufer von `FastLED.show()`.
:::

- `FastLED.show()` blockiert für ungefähr **3 ms pro 60 LEDs** (WS2812B-Protokoll). Berücksichtige das beim Orchestrator-Tick-Timing — ein 10-ms-Tick mit 60 LEDs verbringt 30 % seiner Zeit in `show()`.
- Effektfunktionen müssen **non-blocking** sein. Verwende `millis()`-Deltas für Animationstiming, niemals `delay()` oder `vTaskDelay()` innerhalb einer Effektfunktion.
- Verwende `CRGB`-Arithmetik für Blending: `leds[i] = leds[i].lerp8(target, amount)`. Das ist schneller als Fließkomma-Interpolation.
- Setze Helligkeit global mit `FastLED.setBrightness(brightness)` — skaliere individuelle `CRGB`-Werte nicht manuell, außer du brauchst Per-LED-Helligkeit.

## Wokwi-Simulation

Das Verzeichnis `wokwi/` im Repository-Root enthält Simulationsdiagramme für jede Platine:

```
wokwi/
├── front/
│   └── diagram.json    # Vorderplatine: ESP32, LED-Streifen, simulierte BLE-Events
└── rear/
    └── diagram.json    # Hinterplatine: ESP32, HC-SR04 × 4, LED-Streifen
```

So nutzt du den Simulator:

1. Installiere die **Wokwi for VS Code**-Erweiterung.
2. Öffne `wokwi/rear/diagram.json` in VS Code.
3. Klicke im Wokwi-Panel auf **Start Simulation**.
4. Interagiere mit den simulierten HC-SR04-Sensoren über Wokwis GPIO-Slider-Steuerung, um Proximity-Messungen auszulösen.
5. Beobachte die Serielle-Monitor-Ausgabe für Sensormesswerte und BT Classic Transmit-Logs.

Die Wokwi-Simulation führt das vollständige PlatformIO-Firmware-Binary aus — dasselbe Binary, das auf echte Hardware geflasht wird. BT Classic RF wird nicht simuliert, aber GPIO, UART und SPI werden vollständig emuliert.

## Bauen und Flashen

Flashe zuerst die **Hinterplatine**, dann die **Vorderplatine**. So stellt der BT Classic SPP Client sicher, dass er Verbindungen annimmt, bevor der Host der Vorderplatine versucht, sich zu verbinden.

```bash
# Vorderplatinen-Firmware bauen und flashen (Vorderplatine per USB verbinden)
cd firmware/front
pio run --target upload

# Hinterplatinen-Firmware bauen und flashen (Hinterplatine per USB verbinden)
cd firmware/rear
pio run --target upload
```

Nur bauen (kein Flash — wie in CI):

```bash
pio run
```

## Serieller Monitor

```bash
# Vorderplatine
cd firmware/front
pio device monitor -b 115200

# Hinterplatine
cd firmware/rear
pio device monitor -b 115200
```

Die Log-Ausgabe verwendet das Format `[TASK][LEVEL] message`, z. B.:

```
[ORCH][I] Effect kNavArrow active, dist 42 cm
[BLE][I] Client connected, MTU 247
[BT][W] SPP connection attempt 2/5
```

## config.h: Einzige Wahrheitsquelle

Alle GPIO-Zuweisungen, LED-Anzahlen, Timing-Konstanten und UUID-Definitionen befinden sich in `include/config.h`. **Hartcodiere diese Werte niemals in `.cpp`-Dateien.**

```cpp
// include/config.h (Vorderplatine, Auszug)
constexpr gpio_num_t kLedPin     = GPIO_NUM_5;
constexpr int        kLedCount   = 60;
constexpr uint32_t   kOrchTickMs = 10;

// BLE UUIDs
constexpr char kServiceUUID[]    = "180D";
constexpr char kNavCommandUUID[] = "2A37";
constexpr char kLedConfigUUID[]  = "2A38";
constexpr char kTelemetryUUID[]  = "2A39";
```

Wenn du eine neue GATT-Characteristic hinzufügst, kommt die UUID-Konstante zuerst in `config.h`, dann wird sie in `gatt_ext.cpp` und im App-Layer `core/ble/` referenziert.

## Eine neue GATT-Characteristic hinzufügen

**Firmware-Seite:**

1. UUID-Konstante in `include/config.h` definieren.
2. Characteristic in `src/gatt_ext.cpp` mit `NimBLEService::createCharacteristic()` und den korrekten Properties (`NOTIFY`, `READ`, `WRITE`) erstellen.
3. Eine Write-Callback-Klasse hinzufügen (wenn schreibbar), die in die entsprechende FreeRTOS-Queue schreibt.
4. Wenn die Characteristic Notifications sendet, `pChar->notify()` aus dem relevanten Task aufrufen, wenn neue Daten vorliegen.

**App-Seite (muss im selben PR erfolgen):**

1. UUID-Konstante zu `core/ble/gatt_uuids.dart` hinzufügen.
2. Encode/Decode-Codec im `data/`-Verzeichnis des jeweiligen Features hinzufügen.
3. Den neuen Datenstrom oder die Write-Methode über `IControllerRepository` exponieren.
4. `BluetoothControllerRepository` und `MockControllerRepository` mit der neuen Interface-Methode aktualisieren.
5. Codec-Tests in `test/features/<feature>/data/<name>_codec_test.dart` hinzufügen.

Firmware- und App-Änderungen in einem einzigen Pull Request zu halten verhindert, dass die beiden Seiten auseinanderdriften.
