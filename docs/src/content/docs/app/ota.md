---
title: Firmware Updates (OTA)
description: Update ESP32 firmware wirelessly from the AmbientNav app over Bluetooth LE.
---

Over-the-Air (OTA) firmware updates let you upload new ESP32 firmware directly from your phone over the bonded BLE connection — no USB cable, no computer, no toolchain required. The ESP32 writes the new firmware to its secondary OTA partition while continuing to run the current firmware, then reboots into the new version.

---

## When to Use OTA

| Reason | Action |
|---|---|
| A new AmbientNav release is available on GitHub | Download the latest `firmware-front.bin` and flash via OTA |
| You are experiencing a bug fixed in a newer version | Check the GitHub release notes, then update |
| You want to verify the currently installed version | Open the Status tab on the Controller Detail screen |

The installed firmware version is visible in **Controllers → [your device] → Status → Firmware Version**. Compare it with the [latest GitHub Release](https://github.com/vergissberlin/ambientnav/releases/latest) to decide whether an update is needed.

---

## Prerequisites

Before starting an OTA update, confirm all of the following:

| Requirement | Why it matters |
|---|---|
| Device is **paired and bonded** | OTA writes are gated behind the authenticated BLE bond |
| Phone is within **~1 m** of the device | BLE throughput drops sharply beyond 1–2 m; OTA may stall |
| Device is on **stable power** (mains or vehicle battery, not just USB bus power) | A brownout mid-update can corrupt the OTA partition |
| Phone has sufficient **battery or is charging** | A dead phone during OTA leaves the device in an incomplete state |
| You have the correct firmware binary | Front and rear boards use different binaries; do not mix them up |

:::caution
Do **not** disconnect the BLE connection, power off the device, or force-close the app while an OTA update is in progress. The ESP32 will not commit the new firmware until the entire image has been received and verified. If the connection is interrupted, the device reboots back to its previous firmware and the incomplete image is discarded — but restarting the update unnecessarily wastes time.
:::

---

## Step-by-Step OTA Update

### Step 1 — Open the Firmware Update Tab

1. Tap the **Controllers** tab in the bottom navigation bar.
2. Tap the row of your paired controller.
3. On the Controller Detail screen, tap the **Firmware Update** tab.

The tab shows the currently installed firmware version and a button to begin the update.

### Step 2 — Obtain the Firmware File

Choose one of two methods:

**Method A — Download from GitHub Releases (recommended)**

1. Tap **Download Latest Firmware**.
2. The app fetches the latest release from the GitHub API, shows the release tag and changelog summary, and downloads `firmware-front.bin` to a temporary location.
3. Tap **Use This File** when the download is complete.

**Method B — Pick a File**

1. Tap **Choose File**.
2. The system file picker opens.
3. Navigate to the `.bin` firmware file you downloaded manually (e.g., from `ambientnav-v0.3.0-firmware-front.bin`).
4. Select the file.

The Firmware Update tab shows the selected file name and its size (typically around **400 KB**).

### Step 3 — Start the Update

1. Confirm the file name and size look correct.
2. Tap **Begin Update**.
3. A confirmation dialog appears: "This will update firmware on AmbientNav-Front. The device will reboot after the update. Continue?"
4. Tap **Update**.

### Step 4 — Monitor Progress

A progress bar fills as blocks of firmware are transferred over BLE.

| Phase | What you see |
|---|---|
| **Transferring** | Progress bar fills from 0 % to 100 % with a byte counter |
| **Verifying** | Brief pause at 100 % while the ESP32 checks the image checksum |
| **Committing** | "Committing update…" message — the ESP32 marks the new partition as bootable |
| **Rebooting** | "Device rebooting…" — BLE connection drops momentarily |
| **Reconnecting** | App automatically reconnects; version number on the Status tab updates |

The entire process typically takes **1 to 2 minutes** for a ~400 KB image. The effective BLE throughput is approximately **5–15 KB/s** depending on signal quality and phone model.

:::note
BLE OTA is intentionally slow compared to USB flashing. This is normal. Do not assume the process has stalled unless the progress bar has not moved for more than 30 seconds.
:::

### Step 5 — Verify the Update

1. After the device reboots, the app reconnects automatically (usually within 5–10 seconds).
2. Open the **Status** tab on the Controller Detail screen.
3. Confirm that **Firmware Version** shows the new version number (e.g., `0.3.0`).

---

## Timing Reference

| Image size | Throughput | Estimated time |
|---|---|---|
| 400 KB | 5 KB/s (weak signal) | ~80 seconds |
| 400 KB | 10 KB/s (good signal) | ~40 seconds |
| 400 KB | 15 KB/s (excellent signal) | ~27 seconds |

Signal quality is the primary factor. Moving the phone to within 30–50 cm of the controller will noticeably improve throughput.

---

## What Happens if the Update Fails

The ESP32 uses a **dual-partition OTA scheme**. Firmware is always written to the inactive partition; the active partition continues running until the new image is verified and committed. This means:

- If the transfer is interrupted (BLE drop, power loss), the active partition is untouched and the device reboots normally into its previous firmware.
- If the image checksum fails verification, the commit step is skipped and the device reboots into the previous firmware.
- In both cases the LED strip returns to its ambient breathing effect after reboot — this confirms the device is running and the previous firmware is intact.

To retry after a failed update:

1. Wait for the device to reconnect (green indicator in the Controllers list).
2. Move the phone closer to the device.
3. Return to **Firmware Update** and tap **Begin Update** again.

:::caution
If the device does **not** reconnect after a failed update and the LED strip shows no activity (dark strip), the OTA partition may have been partially corrupted. In this case, use a USB cable and the [browser-based flash tool](/flash/) or [PlatformIO](/flash-firmware/) to reflash the firmware over USB, which bypasses OTA entirely.
:::

---

## Front vs. Rear Firmware

The front and rear ESP32 boards run different firmware images.

| Board | Binary file | OTA via app |
|---|---|---|
| Front (Master) | `firmware-front.bin` | Yes — use the app |
| Rear (Slave) | `firmware-rear.bin` | Not yet — use USB |

The rear board currently does not expose a BLE OTA interface. Update it using the browser-based flash tool at [Flash Firmware](/flash/) or with PlatformIO over USB.
