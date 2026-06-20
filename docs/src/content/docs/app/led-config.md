---
title: LED Configuration
description: Adjust LED strip count, brightness, and idle effects from within the AmbientNav app.
---

The AmbientNav app lets you configure the front LED strip directly from your phone over the bonded BLE connection. Changes are sent to the ESP32, applied instantly, and persisted in non-volatile storage — your settings survive power cycles.

:::note
LED configuration requires a **paired and bonded** connection. If the controller appears in the Controllers list but shows a grey indicator, wait for it to reconnect or move closer to the device.
:::

---

## What You Can Configure

| Parameter | Range | Default | Effect |
|---|---|---|---|
| **LED Count** | 1–144 | 60 | Must match the physical number of LEDs on the strip |
| **Brightness** | 0–255 | 128 (50 %) | Global brightness cap applied to all effects |
| **Idle Effect** | Ambient (breathing) | Ambient | The effect shown when no navigation is active |
| **Effect Color** | Full RGB | Cyan `#19E3FF` | Color used by the idle breathing effect |
| **Effect Speed** | Slow / Medium / Fast | Medium | Breathing cycle period for the ambient effect |

Navigation effects (turn sweeps, blinker blinks) are always amber and are not user-configurable — they are defined by the navigation protocol.

---

## Opening the Controller Detail Screen

1. Tap the **Controllers** tab in the bottom navigation bar.
2. Tap the row of your paired controller (e.g., **AmbientNav-Front**).
3. The Controller Detail screen opens. It has two tabs at the top:
   - **Status** — shows live RSSI, firmware version, uptime, and sensor readings.
   - **LED Config** — the LED configuration form.
4. Tap the **LED Config** tab.

The form is automatically populated with the values currently stored on the ESP32. You will see a brief loading spinner while the app reads the current configuration over BLE.

---

## LED Count

The LED Count field tells the firmware how many LEDs are physically on the front strip.

- The default is **60**, matching a 1 m section of a 60-LED/m WS2812B strip.
- If your strip is longer or shorter, change this value to match.
- Setting a count higher than the actual strip length causes the last LEDs in the animation pattern to address pixels that do not exist — the effect wraps or clips silently, but the animations may look uneven.
- Setting a count lower than the strip length is safe; the extra LEDs at the end simply remain off.

**Common values:**

| Strip length | LEDs/m | LED Count |
|---|---|---|
| 0.5 m | 60 | 30 |
| 1.0 m | 60 | 60 (default) |
| 1.5 m | 60 | 90 |
| 1.0 m | 144 | 144 |

Enter the value in the **LED Count** numeric field and proceed to save (see [Saving the Configuration](#saving--applying-the-configuration)).

---

## Brightness

The brightness slider controls the global intensity cap for all effects.

- The scale is **0–255**, where 255 is maximum brightness (all channels at full power) and 0 is off.
- The default is **128** (~50 %), which provides good visibility in daylight while staying within a conservative power budget.
- The slider updates a live preview widget on screen so you can judge the brightness before saving.

### Power draw at high brightness

Each WS2812B LED draws up to 60 mA at full white. At 60 LEDs and full brightness:

| Brightness | Approx. current (60 LEDs, white) |
|---|---|
| 64 (25 %) | ~450 mA |
| 128 (50 %) | ~900 mA |
| 192 (75 %) | ~1 350 mA |
| 255 (100 %) | ~1 800 mA |

:::caution
Brightness values above **200** may exceed the 3 A capacity of the 5 V step-down converter if the strip is showing full white. Make sure a **1 000 µF bulk capacitor** is installed at the LED strip connector to absorb current peaks. Running at full brightness for extended periods without adequate power supply headroom can cause voltage brownouts and ESP32 resets.
:::

---

## Idle Effect

The idle effect is displayed on the front strip whenever no navigation maneuver is active. Tap the **Effect** dropdown to select from the available options.

| Effect name | Description |
|---|---|
| **Ambient (Breathing)** | A slow sine-wave fade from off to full color and back. Default. |
| **Solid** | Strip stays at a constant color at the configured brightness. |
| **Color Wipe** | A single LED sweeps from one end to the other, leaving the color behind. |
| **Sparkle** | Random LEDs flash briefly at full brightness against a dark background. |

:::note
Navigation effects always override the idle effect when a maneuver is within 200 m. The idle effect resumes automatically when the maneuver is complete.
:::

---

## Effect Color and Speed

When the **Ambient (Breathing)** or **Solid** idle effect is selected, two additional controls appear:

### Color picker

Tap the color swatch to open the color picker. You can:

- Drag the hue/saturation wheel
- Enter an RGB value manually (three 0–255 fields)
- Enter a hex code directly (e.g., `#19E3FF`)

The live preview widget updates as you drag. The chosen color is used only by the idle effect; navigation effects use their own fixed amber color.

### Speed selector (Ambient Breathing only)

| Speed | Breathing period |
|---|---|
| Slow | ~4 seconds |
| Medium | ~2.5 seconds (default) |
| Fast | ~1.2 seconds |

A faster breathing period is more eye-catching but can be distracting while driving. Medium or Slow are recommended for everyday use.

---

## Reading Back the Current Configuration

Every time you open the **LED Config** tab, the app issues a BLE read request to the ESP32 and populates all form fields with the values currently stored on the device. This takes approximately 0.5–1 second over a typical BLE connection.

If the form fields show zeros or appear blank, the read failed — this usually means the connection dropped. Check the connection indicator in the top-right of the detail screen and wait for it to turn green, then pull down to refresh.

---

## Saving / Applying the Configuration

1. After adjusting any field, the **Apply** button at the bottom of the form becomes active (turns from grey to the accent color).
2. Tap **Apply**.
3. The app encodes the configuration into a BLE write to the config characteristic on the ESP32.
4. The ESP32 saves the values to NVS and immediately re-initializes the LED driver with the new parameters.
5. A confirmation toast appears: "Configuration saved".

Changes to **brightness** and **effect color** take effect on the LED strip within one render tick (~10 ms) — you will see the strip change almost instantly.

Changes to **LED Count** or **Idle Effect** take a fraction of a second longer as the firmware reinitializes the FastLED buffer.

:::note
You do not need to restart the ESP32 after saving. The new configuration is active immediately and will persist across power cycles.
:::
