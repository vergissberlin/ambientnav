---
title: Protocols
description: Full specification of the BLE GATT and Bluetooth Classic SPP communication protocols used in AmbientNav.
---

AmbientNav uses two wireless protocols internally:

| Link | Protocol | Direction |
|---|---|---|
| App (phone) ↔ ESP32 Front | Bluetooth LE (GATT) | App reads/writes ESP32 |
| ESP32 Front ↔ ESP32 Rear | Bluetooth Classic (SPP) | Bidirectional |

---

## BLE — GATT (App ↔ ESP32 Front)

The phone app (Flutter, `flutter_blue_plus`) acts as a **BLE Central**. The front ESP32 exposes a **GATT Peripheral**. The original navigation service/characteristic is unchanged; the app additionally uses an **extended protocol** (telemetry, configuration, OTA) described below.

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

- The app scans for the service UUID on launch and connects automatically.
- The app publishes navigation packets only on **state changes** — not on a fixed interval.
- On BLE disconnect, the front ESP32 fades the LED strip to `AMBIENT` after 5 seconds.

---

## BLE — Extended Protocol (App ↔ Controller)

Beyond navigation, the app manages controllers (telemetry, configuration, OTA)
over additional GATT services on the same peripheral. All UUIDs extend the base
`12345678-1234-5678-1234-56789ABCDExx`; **all multi-byte values are little-endian**.

> **Status:** The app implements and unit-tests these codecs against this
> specification with a mock layer. Firmware implementation of the new services
> is a follow-up; the navigation service above is already implemented.

| Service / Characteristic | UUID suffix | Properties | Payload |
|---|---|---|---|
| **Navigation** (existing) | service `…F0`, char `…F1` | Write Without Response | `[direction, distance_m, blinker]` (3 bytes) |
| **Telemetry** service | `…F2` | | |
| — Battery voltage | char `…F3` | Read, Notify | `uint16` millivolts (≈1 Hz) |
| — Device info | char `…F4` | Read | `[role(u8: 0=front,1=rear)] + UTF-8 firmware version` |
| **LED Config** service | `…F5` | | |
| — LED config | char `…F6` | Read, Write¹ | `[ledCount(u16), brightness(u8), effect(u8), p0,p1,p2,p3(u8)]` (8 bytes) |
| **Sensor Config** service | `…F7` | | |
| — Sensor config | char `…F8` | Read, Write¹ | `[activeSensor(u8), calibrationOffset(i16, cm), maxRange(u16, cm)]` (5 bytes) |
| **OTA** service | `…F9` | | |
| — OTA control | char `…FA` | Write¹, Notify | begin: `[op(0), totalLen(u32), crc32(u32)]` · abort `[1]` · commit `[2]`; notify = status/ack |
| — OTA data | char `…FB` | Write Without Response¹ | `[seq(u16), chunk(≤ MTU-3)]` |

¹ Requires an encrypted, authenticated (bonded) link — see *Security* below.

- **Signal strength (RSSI)** is read by the central (phone) natively — there is
  **no** RSSI characteristic; firmware must not add one.
- **LED config** read-back lets the app auto-populate its editor on connect, so
  the user edits the controller's *current* configuration.
- **OTA**: the begin frame carries the total length and a **CRC-32** of the
  image; the firmware (ESP-IDF `esp_ota`) verifies the CRC before committing and
  rebooting. OTA over BLE is throughput-limited (~5–15 KB/s) and needs sequence
  windowing / flow control — the highest-risk firmware item.

### Security — Passkey pairing + bonding

To prevent anyone in range from connecting and pushing configuration or
firmware, the front controller uses **LE Secure Connections with a 6-digit
passkey and bonding** (encrypted + authenticated link, MITM protection — works
on the display-less ESP32).

- The controller stores a fixed per-device passkey (flash/NVS, printed on a
  sticker) and advertises with bonding + MITM + SC flags (NimBLE
  `setSecurityAuth` / `setSecurityPasskey`).
- **All write/OTA/config characteristics require an encrypted, authenticated
  link** (`READ_ENC | WRITE_ENC | WRITE_AUTHEN`); telemetry/device-info reads may
  stay open. Config and OTA are therefore unreachable until the user has paired
  with the correct passkey.
- The app validates the passkey format locally, triggers the OS pairing flow,
  and the OS persists the bond so later reconnects are seamless. The UI surfaces
  *not paired / wrong passkey* states and locks mutating actions until paired
  (least privilege).

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
