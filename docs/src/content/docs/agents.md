---
title: Agents
description: Reference for the five logical agents in AmbientNav — responsibilities, inputs, outputs, and state machines.
---

AmbientNav is structured around five logical agents. Each agent has a single, well-defined responsibility and communicates with others through typed interfaces.

```
NavAgent (iOS) ──BLE──▶ OrchestratorAgent (ESP32 Front)
                                │                   ▲
                        EffectAgent (Front)   BT Classic
                                          ProximityAgent (ESP32 Rear)
                                                    │
                                          EffectAgent (Rear)
```

---

## NavAgent — iOS

**Location:** `ios/AmbientNav/Navigation/`  
**Runtime:** iPhone, foreground  
**Language:** Swift

Reads live navigation data from the Valhalla routing engine via MapLibre Navigation iOS. Extracts the next maneuver and publishes compact BLE packets to the front ESP32. Publishes **only on change** (delta-driven) to minimise BLE traffic.

### Inputs

| Source | Data |
|---|---|
| MapLibre / Valhalla SDK | Next maneuver type, distance to maneuver |
| iOS turn-signal API | Indicator state (left / right / off) |

### Outputs

| Destination | Protocol | Format |
|---|---|---|
| OrchestratorAgent | Bluetooth LE — GATT Write | `[direction, distance_m, indicator]` — 3 bytes |

### States

```
IDLE ──start_nav──▶ NAVIGATING ──arrive──▶ IDLE
                         │
                    maneuver event
                         │
                    PUBLISHING → back to NAVIGATING
```

Falls back to `direction = 0x00` (none) if GPS signal is lost for more than 3 seconds.

---

## ProximityAgent — ESP32 Rear

**Location:** `firmware/rear/src/`  
**Runtime:** ESP32 Slave, FreeRTOS task  
**Language:** C++ (Arduino / ESP-IDF)

Drives three HC-SR04 sensors sequentially (30 ms gap between triggers to avoid cross-talk). Applies a 3-reading median filter per sensor. Sends the fused distance triplet to the OrchestratorAgent at **10 Hz** while in reverse mode. Also renders the rear LED strip directly.

### Inputs

| Source | Interface | Signal |
|---|---|---|
| HC-SR04 Left | GPIO (TRIG + ECHO) | Time-of-flight pulse |
| HC-SR04 Center | GPIO (TRIG + ECHO) | Time-of-flight pulse |
| HC-SR04 Right | GPIO (TRIG + ECHO) | Time-of-flight pulse |
| OrchestratorAgent | BT Classic SPP | `{ "cmd": "reverse", "active": bool }` |

### Outputs

| Destination | Protocol | Format |
|---|---|---|
| OrchestratorAgent | BT Classic SPP | `{ "type": "sensors", "left": cm, "center": cm, "right": cm }` |
| Rear LED strip | FastLED (GPIO) | Direct pixel writes |

### States

```
STANDBY ──reverse(active=true)──▶ MEASURING ──reverse(active=false)──▶ STANDBY
              │
        sensor cycle (30 ms)
              │
          REPORTING → back to MEASURING
```

Out-of-range readings (> 400 cm or echo timeout) are replaced with `999` (no obstacle).

---

## OrchestratorAgent — ESP32 Front

**Location:** `firmware/front/src/`  
**Runtime:** ESP32 Master, FreeRTOS task (10 ms tick)  
**Language:** C++ (Arduino / ESP-IDF)

The central decision-maker. Merges navigation commands from the iPhone and sensor data from the rear ESP32. Determines the correct LED effect for both strips and dispatches render commands to the EffectAgents.

### Inputs

| Source | Protocol | Data |
|---|---|---|
| NavAgent | BLE GATT Write | `[direction, distance_m, indicator]` |
| ProximityAgent | BT Classic SPP | `{ "type": "sensors", ... }` |

### Outputs

| Destination | Protocol | Data |
|---|---|---|
| Front EffectAgent | Internal queue | `EffectCommand { type, color, intensity }` |
| Rear EffectAgent | BT Classic SPP | `{ "cmd": "effect", "type": "...", "params": {...} }` |

### Priority Rules

When multiple inputs arrive simultaneously:

1. **Reverse active** — parking aid overrides all other rear strip effects
2. **Active maneuver** (distance < 200 m) — navigation effect on front strip
3. **Indicator active** — indicator animation on front strip
4. **Idle** — slow ambient breathing on both strips

### States

```
BOOT ──bt_paired──▶ CONNECTED ──ble_paired──▶ READY
                                                  │
                                         event loop (10 ms tick)
                                                  │
                                  ┌───────────────┴───────────────┐
                              nav event                      sensor event
                                  │                               │
                            update nav state              update prox state
                                  └───────────────┬───────────────┘
                                           evaluate priority
                                                  │
                                           dispatch effects
```

---

## EffectAgent — Front LED Strip

**Location:** `firmware/front/src/led_effects.cpp`  
**Runtime:** ESP32 Front, called synchronously from OrchestratorAgent

Translates abstract `EffectCommand` structs into WS2812B pixel data.

| Effect ID | Trigger | Description |
|---|---|---|
| `NAV_LEFT` | Turn left < 200 m | Amber sweep center → left, 600 ms cycle |
| `NAV_RIGHT` | Turn right < 200 m | Amber sweep center → right, 600 ms cycle |
| `NAV_STRAIGHT` | Continue straight | White pulse forward, 800 ms |
| `INDICATOR_LEFT` | Left indicator | Fast amber blink on left half, 400 ms on/off |
| `INDICATOR_RIGHT` | Right indicator | Fast amber blink on right half, 400 ms on/off |
| `HAZARD` | Hazard lights | Full strip amber blink, 400 ms on/off |
| `AMBIENT` | Idle | Slow breathing, configurable color (default: 20 % white) |

---

## EffectAgent — Rear LED Strip

**Location:** `firmware/rear/src/led_effects.cpp`  
**Runtime:** ESP32 Rear, commanded by OrchestratorAgent via SPP

Renders parking-aid visualizations. The strip is divided into three equal zones (left / center / right), each driven by its corresponding HC-SR04 sensor.

| Distance | Fill % of zone | Color |
|---|---|---|
| > 150 cm | 100 % | Green |
| 100–150 cm | 80 % | Yellow-green |
| 50–100 cm | 50 % | Amber |
| 20–50 cm | 20 % | Orange |
| < 20 cm | 10 % + blink | Red |

Zone fill formula:

```
fill = clamp((distance_cm - 20) / 130, 0.1, 1.0)
```

---

## Failure Modes

| Failure | Detected by | Recovery |
|---|---|---|
| BLE link drops | OrchestratorAgent (GATT disconnect) | Front strip → AMBIENT after 5 s |
| BT Classic link drops | OrchestratorAgent (SPP disconnect) | Disable reverse mode; reconnect every 5 s |
| HC-SR04 echo timeout | ProximityAgent | Replace reading with `999`; continue |
| Stale sensor data (> 500 ms) | OrchestratorAgent (timestamp check) | Treat all sensor values as `999` |
