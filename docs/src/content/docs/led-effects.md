---
title: LED Effects
description: Complete catalogue of navigation and parking-aid LED effects for the front and rear WS2812B strips.
---

AmbientNav drives two independent WS2812B LED strips via FastLED. The front strip handles navigation and blinker feedback; the rear strip handles parking assistance.

---

## Front Strip — Navigation Effects

The front strip is driven by the EffectAgent running on the front ESP32. Effects are triggered by navigation commands from the iOS app.

| Effect ID | Trigger | Color | Timing |
|---|---|---|---|
| `NAV_LEFT` | Turn left, distance < 200 m | Amber `#FFA500` | Sweep center → left edge, 600 ms cycle |
| `NAV_RIGHT` | Turn right, distance < 200 m | Amber `#FFA500` | Sweep center → right edge, 600 ms cycle |
| `NAV_STRAIGHT` | Continue straight | White `#FFFFFF` | Single pulse toward center, 800 ms |
| `BLINKER_LEFT` | Left blinker active | Amber `#FFA500` | Fast blink, left half only, 400 ms on/off |
| `BLINKER_RIGHT` | Right blinker active | Amber `#FFA500` | Fast blink, right half only, 400 ms on/off |
| `HAZARD` | Hazard lights | Amber `#FFA500` | Full strip blink, 400 ms on/off |
| `AMBIENT` | Idle / no navigation | Configurable | Slow sine-wave breathing, 3 s period |

### Priority

When the navigation app signals an upcoming turn **and** the blinker is active simultaneously, `NAV_LEFT` / `NAV_RIGHT` take priority over `BLINKER_LEFT` / `BLINKER_RIGHT` because they carry additional distance context.

### Sweep Animation

The `NAV_LEFT` and `NAV_RIGHT` sweeps use a moving dot that starts at the strip center and travels toward the edge. Dot width is 15 % of total LED count, with a soft fade tail.

```
NAV_LEFT:   ████░░░░░░░░░  →  ░░░░░░░░░████
            center             left edge
```

---

## Rear Strip — Parking Aid

The rear strip is divided into three equal zones, each driven independently by its corresponding HC-SR04 sensor. The zones reflect obstacle proximity for left, center, and right.

### Zone Fill by Distance

| Distance | Fill % | Color | Blink |
|---|---|---|---|
| > 150 cm | 100 % | Green `#00FF00` | No |
| 100–150 cm | 80 % | Yellow-green `#AAFF00` | No |
| 50–100 cm | 50 % | Amber `#FFA500` | No |
| 20–50 cm | 20 % | Orange `#FF4400` | No |
| < 20 cm | 10 % | Red `#FF0000` | 200 ms on/off |

### Fill Formula

Zone fill is calculated per sensor independently:

```
fill = clamp((distance_cm - 20) / 130, 0.1, 1.0)
```

This maps:
- `distance = 150 cm` → `fill = 1.0` (100 %, full bar)
- `distance = 20 cm`  → `fill = 0.1` (10 %, minimal bar)
- `distance < 20 cm`  → clamped to `0.1`, plus fast blink
- `distance = 999`     → `fill = 1.0` (no obstacle, full green bar)

### Zone Layout

```
Rear of vehicle:

 Left zone          Center zone         Right zone
[██████████]       [██████████]       [██████████]
 HC-SR04 L          HC-SR04 C          HC-SR04 R
```

Each zone occupies one third of the total LED count. The zones are independent — the center zone can be critical distance while the side zones are clear.

### Reverse Mode Activation

The rear strip parking-aid effect is only active when the front ESP32 sends `{ "cmd": "reverse", "active": true }`. Outside of reverse mode, the rear strip shows the `AMBIENT` effect.

---

## FastLED Configuration

Both strips use WS2812B LEDs at 5 V with the 800 kHz data protocol.

```cpp
// Front strip
#define FRONT_LED_PIN   5
#define FRONT_LED_COUNT 60
CRGB frontLeds[FRONT_LED_COUNT];
FastLED.addLeds<WS2812B, FRONT_LED_PIN, GRB>(frontLeds, FRONT_LED_COUNT).setCorrection(TypicalLEDStrip);

// Rear strip
#define REAR_LED_PIN    18
#define REAR_LED_COUNT  60
CRGB rearLeds[REAR_LED_COUNT];
FastLED.addLeds<WS2812B, REAR_LED_PIN, GRB>(rearLeds, REAR_LED_COUNT).setCorrection(TypicalLEDStrip);
```

`FastLED.setBrightness(128)` caps global brightness at 50 % to stay within the 3 A power budget. Individual effect brightness is scaled relative to this global cap.
