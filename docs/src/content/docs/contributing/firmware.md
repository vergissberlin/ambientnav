---
title: "Firmware Development"
description: "How to build, flash, and extend the AmbientNav ESP32 firmware for the front and rear boards."
---

## Two PlatformIO Projects

The firmware consists of two independent PlatformIO projects, one for each physical board:

| Project | Path | Role |
|---|---|---|
| **Front board** | `firmware/front/` | BLE GATT server, navigation LED effects, BT Classic host (receives rear sensor data), orchestrator |
| **Rear board** | `firmware/rear/` | Ultrasonic proximity sensing, rear LED effects, BT Classic client (sends sensor data to front) |

Each is an isolated project with its own `platformio.ini`, `src/`, and `include/` directories. They share no source files — the shared protocol is defined by the JSON over BT Classic SPP link at runtime.

## Front Board: Key Source Files

| File | Description |
|---|---|
| `src/main.cpp` | Entry point: hardware init, FreeRTOS task creation, `app_main()` |
| `src/ble_server.cpp` | NimBLE GATT server setup: service UUID, characteristic registration, connection callbacks |
| `src/bt_classic.cpp` | ESP-IDF SPP host: accepts incoming connection from rear board, receives JSON sensor frames |
| `src/orchestrator.cpp` | `OrchestratorAgent` FreeRTOS task: 10 ms tick, dispatches nav commands and sensor data to LED effects |
| `src/led_effects.cpp` | All LED animation functions: direction arrows, proximity gradients, idle pulse, alert flash |
| `src/gatt_ext.cpp` | Extended GATT characteristic handlers: LedConfig write, Telemetry notify, SensorConfig notify |
| `src/battery.cpp` | ADC-based battery voltage measurement, percentage calculation with smoothing |
| `include/config.h` | All GPIO pins, LED strip length, timing constants, BLE service and characteristic UUIDs |

## Rear Board: Key Source Files

| File | Description |
|---|---|
| `src/main.cpp` | Entry point: hardware init, FreeRTOS task creation |
| `src/ultrasonic.cpp` | HC-SR04 trigger/echo cycle for four sensors, distance calculation in cm |
| `src/bt_classic.cpp` | ESP-IDF SPP client: connects to front board MAC, transmits JSON sensor frames every 30 ms |
| `src/led_effects.cpp` | Rear LED animations: proximity color scale, brake flash |
| `src/sensor_store.cpp` | Thread-safe sensor reading cache, used by both SPP transmit task and LED task |
| `include/config.h` | GPIO assignments, sensor count, LED count, timing constants, front board MAC address |

## FreeRTOS Task Model

The firmware uses a **message-passing architecture** via FreeRTOS queues. Tasks never access each other's data through shared globals.

### Front Board Tasks

| Task | Priority | Stack | Period | Responsibility |
|---|---|---|---|---|
| `OrchestratorAgent` | 5 | 8 KB | 10 ms | Reads queues, decides active effect, calls FastLED |
| `BleTask` | 4 | 6 KB | event-driven | Handles GATT characteristic reads/writes, notifies app |
| `BtClassicRxTask` | 3 | 4 KB | event-driven | Receives sensor JSON from rear, posts to sensor queue |
| `BatteryTask` | 1 | 2 KB | 5 s | Samples ADC, updates battery level characteristic |

### Rear Board Tasks

| Task | Priority | Stack | Period | Responsibility |
|---|---|---|---|---|
| `ProximityAgent` | 5 | 4 KB | 30 ms | Triggers ultrasonic sensors, stores readings in `SensorStore` |
| `BtClassicTxTask` | 4 | 4 KB | 30 ms | Reads `SensorStore`, serializes to JSON, sends via SPP |
| `LedTask` | 3 | 4 KB | 40 ms | Reads `SensorStore`, applies rear LED effect, calls FastLED |

### Why Queues, Not Shared Globals

A raw global struct protected by a mutex introduces priority inversion risk and makes tasks tightly coupled. FreeRTOS queues:

- Transfer ownership of data between tasks atomically
- Provide natural backpressure (a full queue signals the producer to slow down)
- Make data flow explicit and auditable in the task model

The sensor data path on the front board: `BtClassicRxTask` → `xSensorQueue` (10-element, overwrites oldest on overflow) → `OrchestratorAgent`.

## Adding a New LED Effect

Follow these four steps:

**1. Add the effect ID to the enum in `include/config.h`:**

```cpp
// include/config.h
enum class LedEffect : uint8_t {
  kOff         = 0x00,
  kNavArrow    = 0x01,
  kProximity   = 0x02,
  kIdlePulse   = 0x03,
  kAlertFlash  = 0x04,
  kYourEffect  = 0x05,  // <-- add here
};
```

**2. Implement the effect function in `src/led_effects.cpp`:**

```cpp
// Non-blocking: uses millis() delta, never delay()
void EffectYourEffect(CRGB* leds, int num_leds, uint32_t now_ms) {
  static uint32_t last_ms = 0;
  static uint8_t phase = 0;

  if (now_ms - last_ms < 50) return;  // 20 Hz update rate
  last_ms = now_ms;

  // ... set leds[i] values ...
}
```

Declare the function in `include/led_effects.h`.

**3. Handle the new effect in `src/orchestrator.cpp`:**

```cpp
case LedEffect::kYourEffect:
  EffectYourEffect(leds, kLedCount, millis());
  break;
```

**4. Call `FastLED.show()` only in the orchestrator** — never from within `EffectYourEffect()`. The orchestrator is the single caller of `FastLED.show()` to prevent race conditions.

## BLE Stack: NimBLE-Arduino

The front board uses **NimBLE-Arduino** (not the default Bluedroid or ESP-IDF native BLE stack).

**Why NimBLE?**
- Bluedroid uses approximately 100 KB of heap; NimBLE uses ~35 KB
- The front board runs BLE and BT Classic simultaneously — the RAM savings are critical
- NimBLE's API is cleaner for GATT server use cases

Key NimBLE API patterns:

```cpp
// ble_server.cpp — server setup
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
// Characteristic write callback
class LedConfigCallbacks : public NimBLECharacteristicCallbacks {
  void onWrite(NimBLECharacteristic* pChar) override {
    std::string val = pChar->getValue();
    LedConfig cfg = DecodeLedConfig(
        reinterpret_cast<const uint8_t*>(val.data()), val.size());
    xQueueOverwrite(xLedConfigQueue, &cfg);
  }
};
```

## Bluetooth Classic SPP: Rear-to-Front Link

The rear board transmits sensor readings to the front board over a Bluetooth Classic SPP (Serial Port Profile) link, implemented using the ESP-IDF `esp_spp_api.h`.

**Protocol:** Newline-delimited JSON, one frame per transmission cycle (30 ms):

```json
{"s0":42,"s1":87,"s2":210,"s3":255}\n
```

Fields `s0`–`s3` are the four ultrasonic sensor distances in centimeters. `255` means "no obstacle detected" (out of range). Parsing on the front board:

```cpp
// bt_classic.cpp (front board receive side)
void ParseSensorFrame(const char* json_str, SensorReading* out) {
  // Lightweight manual parse — avoid heap allocation in ISR context
  sscanf(json_str, "{\"s0\":%hhu,\"s1\":%hhu,\"s2\":%hhu,\"s3\":%hhu}",
         &out->dist[0], &out->dist[1], &out->dist[2], &out->dist[3]);
}
```

**Why SPP instead of BLE for rear-to-front?**
The front board is already acting as a BLE GATT server to the phone. Running a simultaneous BLE central (to connect to the rear board) on the same ESP32 is unstable with NimBLE due to controller scheduling conflicts. SPP runs on the Classic Bluetooth radio, which shares the 2.4 GHz band but uses a separate controller path.

## FastLED Tips

:::caution
**Never call `FastLED.show()` from more than one FreeRTOS task.** `FastLED.show()` drives the LED data line via bit-banging with interrupts disabled for the entire duration. Calling it from two tasks simultaneously corrupts the LED frame and can crash the system. The `OrchestratorAgent` is the **sole** caller of `FastLED.show()`.
:::

- `FastLED.show()` blocks for approximately **3 ms per 60 LEDs** (WS2812B protocol). Budget this in your orchestrator tick timing — a 10 ms tick with 60 LEDs spends 30% of its time in `show()`.
- Effect functions must be **non-blocking**. Use `millis()` deltas for animation timing, never `delay()` or `vTaskDelay()` inside an effect function.
- Use `CRGB` arithmetic for blending: `leds[i] = leds[i].lerp8(target, amount)`. It's faster than floating-point interpolation.
- Set brightness globally with `FastLED.setBrightness(brightness)` — do not scale individual `CRGB` values by hand unless you need per-LED brightness.

## Wokwi Simulation

The `wokwi/` directory at the repository root contains simulator diagrams for each board:

```
wokwi/
├── front/
│   └── diagram.json    # Front board: ESP32, LED strip, simulated BLE events
└── rear/
    └── diagram.json    # Rear board: ESP32, HC-SR04 × 4, LED strip
```

To use the simulator:

1. Install the **Wokwi for VS Code** extension.
2. Open `wokwi/rear/diagram.json` in VS Code.
3. Click **Start Simulation** in the Wokwi panel.
4. Interact with the simulated HC-SR04 sensors using Wokwi's GPIO slider controls to trigger proximity readings.
5. Observe the serial monitor output for sensor readings and BT Classic transmit logs.

The Wokwi simulation runs the full PlatformIO firmware binary — the same binary that flashes to real hardware. It does not simulate BT Classic RF, but it fully simulates GPIO, UART, and SPI.

## Build and Flash

Flash the **rear board first**, then the **front board**. This ensures the BT Classic SPP client is advertising before the front board's host attempts to connect.

```bash
# Build and flash front board (connect front board via USB)
cd firmware/front
pio run --target upload

# Build and flash rear board (connect rear board via USB)
cd firmware/rear
pio run --target upload
```

Build only (no flash — same as CI):

```bash
pio run
```

## Serial Monitor

```bash
# Front board
cd firmware/front
pio device monitor -b 115200

# Rear board
cd firmware/rear
pio device monitor -b 115200
```

Log output uses the format `[TASK][LEVEL] message`, e.g.:

```
[ORCH][I] Effect kNavArrow active, dist 42 cm
[BLE][I] Client connected, MTU 247
[BT][W] SPP connection attempt 2/5
```

## config.h: Single Source of Truth

All GPIO assignments, LED counts, timing constants, and UUID definitions live in `include/config.h`. **Never hard-code these values in `.cpp` files.**

```cpp
// include/config.h (front board, excerpt)
constexpr gpio_num_t kLedPin     = GPIO_NUM_5;
constexpr int        kLedCount   = 60;
constexpr uint32_t   kOrchTickMs = 10;

// BLE UUIDs
constexpr char kServiceUUID[]    = "180D";
constexpr char kNavCommandUUID[] = "2A37";
constexpr char kLedConfigUUID[]  = "2A38";
constexpr char kTelemetryUUID[]  = "2A39";
```

When you add a new GATT characteristic, the UUID constant goes in `config.h` first, then gets referenced in `gatt_ext.cpp` and in the app's `core/ble/` layer.

## Adding a New GATT Characteristic

**Firmware side:**

1. Define the UUID constant in `include/config.h`.
2. Create the characteristic in `src/gatt_ext.cpp` using `NimBLEService::createCharacteristic()` with the correct properties (`NOTIFY`, `READ`, `WRITE`).
3. Add a write callback class (if writable) that posts to the appropriate FreeRTOS queue.
4. If the characteristic sends notifications, call `pChar->notify()` from the relevant task when new data is available.

**App side (must be done in the same PR):**

1. Add the UUID constant to `core/ble/gatt_uuids.dart`.
2. Add the encode/decode codec in the relevant feature's `data/` directory.
3. Expose the new data stream or write method through `IControllerRepository`.
4. Update `BluetoothControllerRepository` and `MockControllerRepository` with the new interface method.
5. Add codec tests in `test/features/<feature>/data/<name>_codec_test.dart`.

Keeping firmware and app changes in a single pull request prevents the two sides from drifting out of sync.
