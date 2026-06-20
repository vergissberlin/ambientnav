---
title: Pairing & Security
description: How to pair your phone with the AmbientNav controller using Bluetooth LE secure passkey pairing.
---

AmbientNav uses **Bluetooth LE secure passkey pairing with bonding** to protect configuration and firmware update operations. Without a paired bond, the app can still display navigation and the LED strip still reacts to route events — but you cannot change LED settings or perform OTA firmware updates from an unpaired device.

---

## Why Pairing Is Required

Pairing establishes an encrypted, authenticated channel between the app and the ESP32 controller. This prevents:

- Unauthorized changes to LED brightness or effects
- Rogue OTA firmware uploads that could damage the controller
- Replay attacks on BLE configuration characteristics

The passkey printed on the device sticker is generated once during manufacturing and stored in the ESP32's non-volatile storage (NVS). It never changes unless the firmware is reflashed.

---

## Prerequisites

Before you begin, confirm:

- The **AmbientNav app** is installed on your phone (iOS or Android).
- The **front ESP32 controller** is powered on and within BLE range (~10 m, ideally closer during initial pairing).
- Bluetooth is enabled on your phone.
- The controller has been flashed with firmware that includes the passkey pairing feature (v0.2.0 or later).

:::note
You do **not** need to open your phone's system Bluetooth settings. The app manages the BLE connection and pairing entirely on its own.
:::

---

## Step-by-Step Pairing

### Step 1 — Open the Controllers Screen

1. Launch the **AmbientNav** app.
2. Tap the **Controllers** tab in the bottom navigation bar (or the controller icon in the top-right corner of the map screen).
3. The Controllers screen lists all previously paired devices. On first use the list is empty.

### Step 2 — Add a New Controller

1. Tap **Add Controller** (the `+` button in the top-right corner of the Controllers screen).
2. The app starts scanning for nearby AmbientNav BLE devices. A spinner and the label "Scanning…" appear.

### Step 3 — Select Your Device

1. After a few seconds, devices appear in the list with their BLE advertisement name (e.g., **AmbientNav-Front**) and the current RSSI signal strength.
2. Tap the device you want to pair. If multiple devices are listed (for example in a garage with several vehicles), identify the correct one by its signal strength — the closest device shows the highest RSSI value (closest to 0 dBm).

:::note
If the device does not appear after 15 seconds, see [Troubleshooting](#troubleshooting) below.
:::

### Step 4 — Enter the 6-Digit Passkey

1. A passkey entry dialog appears on screen.
2. Enter the **6-digit numeric passkey** printed on the white sticker on the ESP32 controller housing (e.g., `482 916`).
3. Tap **Confirm**.

:::caution
The passkey is case-sensitive and numeric only. Do not confuse the digit `0` (zero) with the letter `O`, or the digit `1` (one) with the letter `l`. The sticker uses a font that distinguishes these clearly.
:::

### Step 5 — Pairing Complete

If the passkey is correct, the app and the controller exchange keys and create a **bond**. You will see:

- A success toast: "Paired with AmbientNav-Front"
- The device appears in the Controllers list with a **green connected indicator**
- The RSSI value updates in real time

The bond is stored on both the phone and the ESP32. Future reconnects happen automatically — you do not need to enter the passkey again.

---

## Connection Status Indicators

The Controllers screen shows live connection state for each paired device.

| Indicator | Meaning |
|---|---|
| Green dot + RSSI value (e.g., `-52 dBm`) | Connected and bonded |
| Yellow dot | Connecting / reconnecting |
| Grey dot | Not in range or not powered on |
| Red dot | Connection error (tap to retry) |

### RSSI signal strength guide

| RSSI range | Signal quality | Notes |
|---|---|---|
| `-40 dBm` to `0 dBm` | Excellent | Device is very close (<1 m) |
| `-60 dBm` to `-41 dBm` | Good | Reliable for all operations including OTA |
| `-75 dBm` to `-61 dBm` | Fair | Navigation and config work; OTA may be slower |
| Below `-75 dBm` | Weak | Move closer; OTA updates are not recommended |

---

## Automatic Reconnection

Once bonded, the app reconnects to the controller automatically every time:

- The app is opened while the controller is powered on
- The controller powers on while the app is already running
- A temporary BLE connection drop is recovered (the app retries every 5 seconds)

You will see the indicator briefly show yellow during reconnection, then switch back to green.

---

## Unpairing / Forgetting a Device

To remove a paired device from the app:

1. Go to **Controllers**.
2. Swipe left on the device row (iOS) or long-press it (Android).
3. Tap **Remove** (iOS) or **Forget** (Android).
4. Confirm the action in the dialog.

This removes the bond from the app's database. The bond record on the ESP32 itself is **not** cleared automatically — the controller will still try to reconnect to the phone. To fully clear the bond on the ESP32 side, either:

- Use the **Factory Reset** option in the controller detail screen (requires an active connection), or
- Reflash the firmware (clears all NVS data including the bond and the pairing counter).

---

## Troubleshooting

### The device does not appear during scanning

- Confirm the front ESP32 is powered on. The front LED strip should show the ambient breathing effect.
- Check that Bluetooth is enabled on your phone.
- Move closer to the device (within 2 m) during the initial scan.
- Restart the scan by tapping **Add Controller** again.
- If the controller was previously bonded to a different phone, it may be ignoring advertisements from new devices. Reflash the firmware to reset the bond state.

### Wrong passkey entered

- The app shows: "Pairing failed — incorrect passkey". Tap **Try Again** to re-enter.
- You have a limited number of attempts before the ESP32 temporarily blocks pairing requests (60-second cooldown). Wait, then try again.
- Double-check the sticker — the passkey is 6 digits with no letters.

### Device shows as "Already bonded" but will not connect

This can happen if the bond record on the phone was deleted (e.g., through a phone reset) while the ESP32 still holds the old bond.

1. On iOS: go to **Settings → Bluetooth**, find the device in the list, tap ⓘ, and choose **Forget This Device**.
2. On Android: go to **Settings → Connected Devices → Previously Connected Devices**, find the device, and tap **Forget**.
3. Reflash the ESP32 firmware to clear its bond record.
4. Pair again from scratch following the steps above.

### Pairing dialog does not appear

- Force-close the app and reopen it, then start the scan again.
- On Android, confirm the app has **Nearby devices** (BLUETOOTH_CONNECT and BLUETOOTH_SCAN) permissions in Settings → Apps → AmbientNav → Permissions.
