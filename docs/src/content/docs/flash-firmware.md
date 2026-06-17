---
title: Flash Firmware
description: How to flash pre-built AmbientNav firmware binaries onto the ESP32 boards without a development environment.
---

Download the pre-built binaries from the [Releases page](https://github.com/vergissberlin/ambientnav/releases/latest) before you begin. For a fresh install you need the two **merged** files — they bundle the bootloader, partition table, and application firmware into a single image:

- `ambientnav-rear-vX.X.X-merged.bin`
- `ambientnav-front-vX.X.X-merged.bin`

The plain `.bin` files (without `-merged`) contain only the application firmware and are intended for OTA updates or PlatformIO users who manage the other parts separately.

:::caution[Flash order matters]
Always flash the **rear board first**. On first boot the front board scans for the rear board's Bluetooth Classic address. If the front board boots before the rear board is flashed and running, the automatic pairing step is skipped and you will need to re-flash the front board.
:::

---

## Method 1 — esptool.py (recommended)

Works on Windows, macOS, and Linux. Requires Python 3.

### Install esptool

```bash
pip install esptool
```

### Flash the rear board

Connect the rear ESP32 via USB, then run:

```bash
esptool.py --chip esp32 --port /dev/ttyUSB0 --baud 921600 \
  write_flash 0x0 ambientnav-rear-vX.X.X-merged.bin
```

### Flash the front board

Disconnect the rear board, connect the front board, then run:

```bash
esptool.py --chip esp32 --port /dev/ttyUSB0 --baud 921600 \
  write_flash 0x0 ambientnav-front-vX.X.X-merged.bin
```

Replace `vX.X.X` with the version you downloaded.

### Port names by platform

| Platform | Typical port |
|---|---|
| Linux | `/dev/ttyUSB0` or `/dev/ttyACM0` |
| macOS | `/dev/cu.usbserial-*` or `/dev/cu.SLAB_USBtoUART` |
| Windows | `COM3`, `COM4`, etc. — check Device Manager under "Ports (COM & LPT)" |

:::note
**Linux permission error:** Add your user to the `dialout` group and log out / back in:
```bash
sudo usermod -aG dialout $USER
```

**Board not detected:** Hold the **BOOT** button on the ESP32, press and release **EN (Reset)**, then release **BOOT**. Run the esptool command while the board is in this download mode.
:::

---

## Method 2 — Browser-based (ESP Web Flasher)

No installation required. Works in **Chrome or Edge only** (requires Web Serial API).

1. Open **[esp.huhn.me](https://esp.huhn.me)** in Chrome or Edge.
2. Click **Connect** and select the COM/USB serial port for your ESP32.
3. Click **Add file**, set the address to `0x0`, and select the downloaded `-merged.bin` file.
4. Click **Program** and wait for the progress bar to complete.
5. Disconnect the rear board and repeat for the front board.

:::note
Flash the rear board first — connect it, flash it, disconnect, then connect the front board.
:::

---

## Method 3 — PlatformIO

If you have the repository cloned and PlatformIO installed, you can build and flash directly from source:

```bash
cd firmware/rear && pio run --target upload
cd firmware/front && pio run --target upload
```

See [Getting Started](/getting-started/) for full environment setup instructions.
