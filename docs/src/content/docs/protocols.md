---
title: Protocols
description: Full specification of the BLE GATT and Bluetooth Classic SPP communication protocols used in AmbientNav.
---

AmbientNav uses two wireless protocols internally:

| Link | Protocol | Direction |
|---|---|---|
| iPhone ↔ ESP32 Front | Bluetooth LE (GATT) | iPhone writes to ESP32 |
| ESP32 Front ↔ ESP32 Rear | Bluetooth Classic (SPP) | Bidirectional |

---

## BLE — GATT (iPhone ↔ ESP32 Front)

The iOS app acts as a **BLE Central**. The front ESP32 exposes a **GATT Peripheral** with a single custom service and characteristic.

### Service & Characteristic

```
Service UUID:      12345678-1234-5678-1234-56789ABCDEF0
Characteristic:    12345678-1234-5678-1234-56789ABCDEF1
  Properties:      Write Without Response
  Security:        None (pairing optional)
  Payload:         3 bytes
```

### Payload Format

| Byte | Field | Values |
|---|---|---|
| `[0]` | Direction | `0x00` none / idle · `0x01` turn left · `0x02` turn right · `0x03` straight |
| `[1]` | Distance | Metres to next maneuver, capped at `0xFF` (255 m) |
| `[2]` | Indicator | `0x00` off · `0x01` left · `0x02` right · `0x03` hazard |

### Example Packets

```
Left turn in 120 m:      01 78 01
Right turn in 45 m:      02 2D 02
Continue straight:        03 FF 00
Hazard lights:            00 00 03
Idle / no navigation:     00 00 00
```

### Connection Behaviour

- The iOS app scans for the service UUID on launch and connects automatically.
- The app publishes only on **state changes** — not on a fixed interval.
- On BLE disconnect, the front ESP32 fades the LED strip to `AMBIENT` after 5 seconds.

---

## Bluetooth Classic SPP (ESP32 Front ↔ ESP32 Rear)

The front ESP32 acts as the **SPP Client** and initiates the connection. The rear ESP32 runs the **SPP Server**.

All messages are UTF-8 JSON terminated by a newline (`\n`). There is no framing beyond the newline delimiter.

### Front → Rear Messages

#### Enter / exit reverse mode

```json
{ "cmd": "reverse", "active": true }
{ "cmd": "reverse", "active": false }
```

#### Set a specific effect on the rear strip

```json
{
  "cmd": "effect",
  "type": "AMBIENT",
  "params": {
    "color": [255, 255, 255],
    "brightness": 20
  }
}
```

#### Synchronise clock (optional)

```json
{ "cmd": "sync", "ts": 1718000000 }
```

### Rear → Front Messages

#### Sensor distances

Sent at 10 Hz while reverse mode is active. All values in centimetres. `999` means no obstacle detected.

```json
{ "type": "sensors", "left": 120, "center": 85, "right": 134 }
{ "type": "sensors", "left": 999, "center": 42, "right": 999 }
```

#### Command acknowledgement

```json
{ "type": "ack", "cmd": "reverse" }
```

### Connection Behaviour

- The front ESP32 pairs with the rear ESP32's MAC address stored in flash on first boot.
- On SPP disconnect, the front ESP32 disables reverse mode and attempts reconnection every 5 seconds.
- Messages larger than 512 bytes are not expected and should be treated as malformed.

---

## Timing Constraints

| Constraint | Value | Notes |
|---|---|---|
| BLE packet rate | On change only | Avoids BLE congestion |
| SPP sensor rate | 10 Hz (100 ms) | While reverse mode active |
| HC-SR04 sensor cycle | 30 ms / sensor | Staggered to avoid cross-talk |
| OrchestratorAgent tick | 10 ms | FreeRTOS task period |
| FastLED `show()` blocking time | ~3 ms | On a 60-LED strip at 800 kHz |
| Stale sensor threshold | 500 ms | Sensor data older than this → treat as `999` |
