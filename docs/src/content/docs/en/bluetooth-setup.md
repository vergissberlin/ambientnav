---
title: Bluetooth Setup
description: Step-by-step guide for connecting the AmbientNav boards and pairing with the iPhone app.
---

AmbientNav uses two independent Bluetooth links:

| Link | Technology | Who connects |
|---|---|---|
| iPhone ↔ Front board | Bluetooth LE (BLE) | iPhone initiates pairing via the app |
| Front board ↔ Rear board | Bluetooth Classic | Front board connects automatically |

You only need to configure the BLE link manually. The Bluetooth Classic link between the two boards is handled automatically by the firmware.

---

## First-time setup

Follow these steps **in order** when flashing the boards for the first time.

### Step 1 — Flash and power on the rear board first

1. Flash the rear firmware (`firmware-rear.bin`) to the rear ESP32.
2. Power on the rear board.
3. Wait 5 seconds for it to fully boot. It will now be discoverable as **AmbientNav-Rear** via Bluetooth Classic.

### Step 2 — Flash and power on the front board

1. Flash the front firmware (`firmware-front.bin`) to the front ESP32.
2. Power on the front board.
3. The front board automatically searches for **AmbientNav-Rear** and connects.  
   On first boot, this Bluetooth Classic pairing happens in the background — no PIN or confirmation required.
4. Once paired, the LED strip on the front board will begin the slow ambient breathing effect. The pairing result is stored on the board and survives power cycles.

### Step 3 — Pair the iPhone with the front board

1. Open the **AmbientNav** app on your iPhone.
2. Tap **Connect** (or the Bluetooth icon).
3. The app scans for devices named **AmbientNav-Front** and connects automatically.
4. When the connection is established, the front LED strip changes to match the current navigation state.

:::note
You do **not** need to open iOS Bluetooth settings — the app handles the BLE connection directly.
:::

---

## Everyday use

On subsequent starts you do not need to do anything:

- Power on the rear board first (or at the same time as the front board).
- The front board reconnects to the rear board within ~1 second.
- Open the AmbientNav app; it reconnects to the front board automatically.

---

## LED status guide

| Front LED state | Meaning |
|---|---|
| Slow white breathing | Idle / ambient — boards running, no navigation active |
| Amber sweep left or right | Navigation turn coming up |
| Fast amber blink (left half) | Left blinker active |
| Fast amber blink (right half) | Right blinker active |
| Full strip amber blink | Hazard lights active |

| Rear LED state | Meaning |
|---|---|
| Slow white breathing | Standby — not in reverse |
| Coloured zone fill (green → red) | Reverse mode — distance display active |
| Red zone blinking rapidly | Obstacle closer than 20 cm — stop immediately |

---

## Troubleshooting

### Front board does not connect to rear board

- Make sure the rear board is powered on and fully booted **before** the front board.
- The front board retries the connection every 5 seconds. Wait up to 30 seconds.
- If the connection still fails, power-cycle both boards starting with the rear.

### iPhone does not see AmbientNav-Front

- Confirm the front board is powered on and the front LED is breathing (ambient effect).
- Force-close the AmbientNav app and reopen it.
- Confirm Bluetooth is enabled on the iPhone (Settings → Bluetooth).
- If the device still does not appear, go to **iOS Settings → Bluetooth**, find **AmbientNav-Front** in the list, tap the ⓘ and choose **Forget this device**, then reconnect through the app.

### Rear sensors not showing in parking mode

- Check that the front-to-rear Bluetooth Classic link is established (front LEDs show ambient, not error state).
- Confirm the rear board is receiving 5 V and the HC-SR04 sensors are wired correctly — see [Pinouts & Wiring](/pinouts/).
- Confirm you are in reverse gear (or that the reverse signal GPIO is wired and receiving a HIGH signal).

### How to factory-reset the Bluetooth pairing

To clear the stored Bluetooth Classic pairing on the front board, flash the firmware again. The pairing data is stored in ESP32 NVS (non-volatile storage) and is cleared on a full firmware re-flash.
