# AGENTS.md — AmbientNav

This file describes the logical agents (autonomous processing units) within the AmbientNav system, their responsibilities, inputs, outputs, and interaction contracts.

---

## Agent Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                          AmbientNav System                          │
│                                                                     │
│  ┌─────────────────┐        ┌─────────────────┐                    │
│  │  NavAgent (iOS) │        │ ProximityAgent  │                    │
│  │                 │        │ (ESP32 Rear)    │                    │
│  │  - Route decode │        │ - HC-SR04 poll  │                    │
│  │  - BLE publish  │        │ - Distance fuse │                    │
│  └────────┬────────┘        └────────┬────────┘                    │
│           │ BLE                      │ BT Classic                  │
│           ▼                          ▼                              │
│  ┌─────────────────────────────────────────────────────────┐       │
│  │                 OrchestratorAgent (ESP32 Front)          │       │
│  │                                                         │       │
│  │  - Merge navigation + proximity data                    │       │
│  │  - Decide LED effect per strip                          │       │
│  │  - Dispatch to front EffectAgent                        │       │
│  │  - Forward commands to rear EffectAgent                 │       │
│  └──────────┬────────────────────────────────┬─────────────┘       │
│             │ FastLED (local)                │ BT Classic          │
│             ▼                                ▼                      │
│  ┌──────────────────┐              ┌──────────────────┐            │
│  │  EffectAgent     │              │  EffectAgent     │            │
│  │  (Front LEDs)    │              │  (Rear LEDs)     │            │
│  └──────────────────┘              └──────────────────┘            │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Agent Definitions

### 1. NavAgent — iOS

**Location:** `ios/AmbientNav/Navigation/`  
**Runtime:** iPhone, foreground process  
**Language:** Swift

#### Responsibility
Reads live navigation data from the routing engine (Valhalla) via MapLibre Navigation iOS, extracts the next maneuver instruction, and publishes compact BLE commands to the front ESP32.

#### Inputs

| Source | Data |
|---|---|
| MapLibre / Valhalla SDK | Current leg, next step, distance to maneuver, maneuver type |
| iOS turn-signal API (if accessible) | Blinker state (left / right / off) |
| User gesture | Manual override (ambient color, brightness) |

#### Outputs

| Destination | Protocol | Format |
|---|---|---|
| OrchestratorAgent (ESP32 Front) | Bluetooth LE — GATT Write | `[direction, distance_m, blinker]` 3-byte packet |

#### States

```
IDLE ──start_nav──▶ NAVIGATING ──arrive──▶ IDLE
                         │
                    maneuver event
                         │
                         ▼
                    PUBLISHING (sends BLE packet, returns to NAVIGATING)
```

#### Key decisions
- Publishes only on **change** (delta-driven), not on a fixed timer, to reduce BLE traffic.
- Quantizes distance to 1-metre resolution before encoding.
- Falls back to `direction=0x00` (none) if GPS signal is lost for > 3 s.

---

### 2. ProximityAgent — ESP32 Rear

**Location:** `firmware/rear/src/`  
**Runtime:** ESP32 (Slave), FreeRTOS tasks  
**Language:** C++ (Arduino / ESP-IDF)

#### Responsibility
Drives three HC-SR04 ultrasonic sensors, fuses the raw readings into a cleaned distance triplet, and forwards the result to the OrchestratorAgent via Bluetooth Classic SPP. Also drives the rear LED strip directly for parking-aid effects.

#### Inputs

| Source | Interface | Signal |
|---|---|---|
| HC-SR04 Left | GPIO (TRIG + ECHO) | Raw time-of-flight pulse |
| HC-SR04 Center | GPIO (TRIG + ECHO) | Raw time-of-flight pulse |
| HC-SR04 Right | GPIO (TRIG + ECHO) | Raw time-of-flight pulse |
| OrchestratorAgent | BT Classic SPP | `{ "cmd": "reverse", "active": bool }` |

#### Outputs

| Destination | Protocol | Format |
|---|---|---|
| OrchestratorAgent | BT Classic SPP | `{ "type": "sensors", "left": cm, "center": cm, "right": cm }` |
| Rear LED strip | FastLED (GPIO) | Direct pixel writes |

#### Sampling strategy
- Sensors are triggered in sequence (left → center → right) with a 30 ms gap to avoid cross-talk.
- Each reading is the median of 3 consecutive raw measurements.
- Out-of-range readings (> 400 cm or echo timeout) are replaced with `999` (no obstacle).
- Sensor data is sent to the front ESP32 at **10 Hz** while in reverse mode.

#### States

```
STANDBY ──reverse_cmd(active=true)──▶ MEASURING ──reverse_cmd(active=false)──▶ STANDBY
              │
          sensor_cycle (30 ms)
              │
              ▼
          REPORTING (publishes JSON, returns to MEASURING)
```

---

### 3. OrchestratorAgent — ESP32 Front (Master)

**Location:** `firmware/front/src/`  
**Runtime:** ESP32 (Master), FreeRTOS tasks  
**Language:** C++ (Arduino / ESP-IDF)

#### Responsibility
Central decision-maker. Merges navigation commands from the iPhone and sensor data from the rear ESP32. Determines the correct LED effect for both strips and dispatches render commands to the respective EffectAgents.

#### Inputs

| Source | Protocol | Data |
|---|---|---|
| NavAgent (iPhone) | BLE GATT Write | `[direction, distance_m, blinker]` |
| ProximityAgent (ESP32 Rear) | BT Classic SPP | `{ "type": "sensors", ... }` |

#### Outputs

| Destination | Protocol | Data |
|---|---|---|
| Front EffectAgent | Internal (function call / queue) | `EffectCommand { type, color, intensity }` |
| Rear EffectAgent | BT Classic SPP | `{ "cmd": "effect", "type": "...", "params": {...} }` |

#### Priority rules

When multiple inputs arrive simultaneously, the orchestrator applies this priority order:

1. **Reverse active** — parking aid overrides all other effects on the rear strip.
2. **Active maneuver** (distance < 200 m) — navigation effect on front strip.
3. **Blinker active** — blinker animation on front strip.
4. **Ambient / idle** — calm breathing effect on both strips.

#### States

```
BOOT ──bt_paired──▶ CONNECTED ──ble_paired──▶ READY
                                                  │
                                          event loop (10 ms tick)
                                                  │
                                         ┌────────┴────────┐
                                     nav event          sensor event
                                         │                  │
                                   update nav state   update prox state
                                         └────────┬────────┘
                                              evaluate priority
                                                  │
                                           dispatch effects
```

---

### 4. EffectAgent — Front LED Strip

**Location:** `firmware/front/src/led_effects.cpp`  
**Runtime:** ESP32 Front, called from OrchestratorAgent  
**Language:** C++ with FastLED

#### Responsibility
Translates abstract `EffectCommand` structs into concrete WS2812B pixel data on the front LED strip.

#### Effect catalogue

| Effect ID | Trigger | Description |
|---|---|---|
| `NAV_LEFT` | Turn left < 200 m | Amber sweep from center to left edge, 600 ms cycle |
| `NAV_RIGHT` | Turn right < 200 m | Amber sweep from center to right edge, 600 ms cycle |
| `NAV_STRAIGHT` | Continue straight | Single white pulse forward, 800 ms cycle |
| `BLINKER_LEFT` | Left blinker | Fast amber blink on left half, 400 ms on/off |
| `BLINKER_RIGHT` | Right blinker | Fast amber blink on right half, 400 ms on/off |
| `HAZARD` | Hazard lights | Full strip amber blink, 400 ms on/off |
| `AMBIENT` | Idle | Slow breathing, configurable color (default: white 20%) |

---

### 5. EffectAgent — Rear LED Strip

**Location:** `firmware/rear/src/led_effects.cpp`  
**Runtime:** ESP32 Rear, commanded by OrchestratorAgent via SPP  
**Language:** C++ with FastLED

#### Responsibility
Renders parking-aid visualizations on the rear LED strip based on the fused sensor distances received from the ProximityAgent.

#### Effect: Parking Aid

The strip is divided into three equal zones (left / center / right). Each zone independently reflects its corresponding sensor.

```
Distance (cm)   LED fill (% of zone)   Color
─────────────   ────────────────────   ──────────────
> 150           100 %                  Green
100–150          80 %                  Yellow-green
 50–100          50 %                  Amber
 20– 50          20 %                  Orange
   < 20          10 % + blink          Red
```

The zone fill is calculated as:

```
fill = clamp((distance - 20) / 130, 0.1, 1.0)   // 20 cm = minimum, 150 cm = full
```

---

## Inter-Agent Communication Reference

### BLE GATT (NavAgent → OrchestratorAgent)

```
Service UUID:    12345678-1234-5678-1234-56789ABCDEF0
Characteristic:  12345678-1234-5678-1234-56789ABCDEF1
  Properties:    Write Without Response
  Payload:       3 bytes
    Byte 0 — direction
      0x00  none / idle
      0x01  turn left
      0x02  turn right
      0x03  continue straight
    Byte 1 — distance to maneuver (metres, capped at 255)
    Byte 2 — blinker state
      0x00  off
      0x01  blinker left
      0x02  blinker right
      0x03  hazard
```

### Bluetooth Classic SPP (OrchestratorAgent ↔ ProximityAgent)

All messages are UTF-8 JSON terminated by `\n`.

```jsonc
// OrchestratorAgent → ProximityAgent
{ "cmd": "reverse", "active": true }          // enter parking mode
{ "cmd": "reverse", "active": false }         // exit parking mode
{ "cmd": "effect", "type": "AMBIENT", "params": { "color": [255,255,255], "brightness": 20 } }

// ProximityAgent → OrchestratorAgent
{ "type": "sensors", "left": 120, "center": 85, "right": 134 }  // distances in cm
{ "type": "ack",     "cmd": "reverse" }                          // command acknowledged
```

---

## Failure Modes & Recovery

| Failure | Detected by | Recovery |
|---|---|---|
| BLE link drops (iPhone out of range) | OrchestratorAgent (GATT disconnect event) | Front strip fades to `AMBIENT` after 5 s |
| BT Classic link drops (rear ESP32 unreachable) | OrchestratorAgent (SPP disconnect event) | Disable reverse mode, log warning, attempt reconnect every 5 s |
| HC-SR04 echo timeout | ProximityAgent | Replace reading with `999` (no obstacle), continue |
| ProximityAgent sends stale data (> 500 ms) | OrchestratorAgent (timestamp check) | Treat all sensor values as `999` |
| FastLED write corruption | EffectAgent | Re-initialize FastLED and redraw on next tick |

---

## Development Notes

- All ESP32 firmware tasks run under FreeRTOS. Use queues (not shared globals) to pass data between tasks.
- The OrchestratorAgent runs at 10 ms tick rate; EffectAgents are called synchronously within the tick.
- The ProximityAgent sensor cycle is 30 ms (3 sensors × 10 ms per sensor). It runs in a dedicated FreeRTOS task.
- FastLED `show()` blocks for ~3 ms on a 60-LED strip at 800 kHz. Account for this in tick budgeting.
- For BLE on ESP32, prefer **NimBLE** (via Arduino NimBLE-Arduino library) over the classic Bluedroid stack — lower memory footprint, simpler API.
- For BT Classic SPP, use the ESP-IDF SPP API directly; the Arduino `BluetoothSerial` wrapper is sufficient for prototyping.

---

## Repository Workflow

This project uses **trunk-based development** on `main`.

- Work directly on `main`. Do not create feature, fix, or chore branches.
- Do not suggest branch-based workflows (`git checkout -b …`, PRs from feature branches).
- Keep changes small and commit often on `main`.
- Pull or rebase onto the latest `main` before pushing.
- Push to `origin/main` when asked to push.
- Stay on `main` before making changes; never run `git checkout -b`, `git switch -c`, or equivalent branch-creation commands unless explicitly overridden.
- When asked for a PR, prefer pushing commits to `main` and note that this repo uses trunk-based development — only create a PR if explicitly requested.

**Exception:** Automated CI branches (e.g. bot-created translation branches) are allowed.
