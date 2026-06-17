---
title: Firmware flashen
description: Anleitung zum Flashen der vorgebauten AmbientNav-Firmware auf die ESP32-Boards ohne Entwicklungsumgebung.
---

Lade die vorgebauten Binaries von der [Releases-Seite](https://github.com/vergissberlin/ambientnav/releases/latest) herunter. Für eine Erstinstallation werden die beiden **Merged**-Dateien benötigt — sie bündeln Bootloader, Partition Table und Anwendungs-Firmware in einem einzigen Image:

- `ambientnav-rear-vX.X.X-merged.bin`
- `ambientnav-front-vX.X.X-merged.bin`

Die einfachen `.bin`-Dateien (ohne `-merged`) enthalten nur die Anwendungs-Firmware und sind für OTA-Updates oder PlatformIO-Nutzer gedacht, die die übrigen Teile separat verwalten.

:::caution[Reihenfolge beachten]
Immer zuerst das **hintere Board** flashen. Das vordere Board sucht beim ersten Start nach der Bluetooth-Classic-Adresse des hinteren Boards. Wenn das vordere Board bootet, bevor das hintere Board geflasht und gestartet ist, wird der automatische Pairing-Schritt übersprungen und das vordere Board muss erneut geflasht werden.
:::

---

## Methode 1 — esptool.py (empfohlen)

Funktioniert unter Windows, macOS und Linux. Erfordert Python 3.

### esptool installieren

```bash
pip install esptool
```

### Hinteres Board flashen

Den hinteren ESP32 per USB verbinden und ausführen:

```bash
esptool.py --chip esp32 --port /dev/ttyUSB0 --baud 921600 \
  write_flash 0x0 ambientnav-rear-vX.X.X-merged.bin
```

### Vorderes Board flashen

Das hintere Board trennen, das vordere Board anschließen und ausführen:

```bash
esptool.py --chip esp32 --port /dev/ttyUSB0 --baud 921600 \
  write_flash 0x0 ambientnav-front-vX.X.X-merged.bin
```

`vX.X.X` durch die heruntergeladene Version ersetzen.

### Port-Namen nach Plattform

| Plattform | Typischer Port |
|---|---|
| Linux | `/dev/ttyUSB0` oder `/dev/ttyACM0` |
| macOS | `/dev/cu.usbserial-*` oder `/dev/cu.SLAB_USBtoUART` |
| Windows | `COM3`, `COM4` usw. — im Geräte-Manager unter „Anschlüsse (COM & LPT)" nachsehen |

:::note
**Berechtigungsfehler unter Linux:** Den Benutzer zur Gruppe `dialout` hinzufügen und ab- sowie wieder anmelden:
```bash
sudo usermod -aG dialout $USER
```

**Board wird nicht erkannt:** Die **BOOT**-Taste am ESP32 gedrückt halten, **EN (Reset)** kurz drücken und loslassen, dann **BOOT** loslassen. Den esptool-Befehl ausführen, während sich das Board im Download-Modus befindet.
:::

---

## Methode 2 — Browser-basiert (ESP Web Flasher)

Keine Installation erforderlich. Funktioniert nur in **Chrome oder Edge** (erfordert Web Serial API).

1. **[esp.huhn.me](https://esp.huhn.me)** in Chrome oder Edge öffnen.
2. Auf **Connect** klicken und den COM-/USB-Seriell-Port des ESP32 auswählen.
3. Auf **Add file** klicken, die Adresse `0x0` setzen und die heruntergeladene `-merged.bin`-Datei auswählen.
4. Auf **Program** klicken und den Fortschrittsbalken abwarten.
5. Das hintere Board trennen und den Vorgang für das vordere Board wiederholen.

:::note
Zuerst das hintere Board flashen — anschließen, flashen, trennen, dann das vordere Board anschließen.
:::

---

## Methode 3 — PlatformIO

Falls bereits ein Repository-Klon und PlatformIO vorhanden sind, kann direkt aus dem Quellcode gebaut und geflasht werden:

```bash
cd firmware/rear && pio run --target upload
cd firmware/front && pio run --target upload
```

Vollständige Einrichtungsanleitung unter [Erste Schritte](/de/getting-started/).
