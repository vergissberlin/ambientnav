---
title: Protokolle
description: Vollständige Spezifikation der BLE GATT und Bluetooth Classic SPP
  Kommunikationsprotokolle in AmbientNav.
slug: de/0.1/protocols
---

AmbientNav verwendet intern zwei drahtlose Protokolle:

| Verbindung | Protokoll | Richtung |
|---|---|---|
| iPhone ↔ ESP32 Vorne | Bluetooth LE (GATT) | iPhone schreibt zum ESP32 |
| ESP32 Vorne ↔ ESP32 Hinten | Bluetooth Classic (SPP) | Bidirektional |

***

## BLE — GATT (iPhone ↔ ESP32 Vorne)

Die iOS App fungiert als **BLE Central**. Der vordere ESP32 exponiert ein **GATT Peripheral** mit einem einzigen Custom-Service und einer Characteristic.

### Service & Characteristic

```
Service UUID:      12345678-1234-5678-1234-56789ABCDEF0
Characteristic:    12345678-1234-5678-1234-56789ABCDEF1
  Properties:      Write Without Response
  Sicherheit:      Keine (Pairing optional)
  Nutzlast:        3 Bytes
```

### Nutzlastformat

| Byte | Feld | Werte |
|---|---|---|
| `[0]` | Richtung | `0x00` keine / Leerlauf · `0x01` links abbiegen · `0x02` rechts abbiegen · `0x03` geradeaus |
| `[1]` | Abstand | Meter zum nächsten Manöver, begrenzt auf `0xFF` (255 m) |
| `[2]` | Indicator | `0x00` aus · `0x01` links · `0x02` rechts · `0x03` Warnblinker |

### Beispielpakete

```
Links abbiegen in 120 m:    01 78 01
Rechts abbiegen in 45 m:    02 2D 02
Geradeaus weiterfahren:      03 FF 00
Warnblinker:                 00 00 03
Leerlauf / keine Navigation: 00 00 00
```

### Verbindungsverhalten

* Die iOS App scannt beim Start nach der Service-UUID und verbindet sich automatisch.
* Die App veröffentlicht nur bei **Zustandsänderungen** — nicht in festen Intervallen.
* Bei BLE-Verbindungsunterbrechung blendet der vordere ESP32 den LED-Streifen nach 5 Sekunden auf `AMBIENT` ab.

***

## Bluetooth Classic SPP (ESP32 Vorne ↔ ESP32 Hinten)

Der vordere ESP32 agiert als **SPP Client** und initiiert die Verbindung. Der hintere ESP32 betreibt den **SPP Server**.

Alle Nachrichten sind UTF-8 JSON, abgeschlossen durch ein Zeilenumbruchzeichen (`\n`). Es gibt kein Framing über das Newline-Trennzeichen hinaus.

### Vorne → Hinten Nachrichten

#### Rückfahrmodus ein-/ausschalten

```json
{ "cmd": "reverse", "active": true }
{ "cmd": "reverse", "active": false }
```

#### Bestimmten Effekt auf dem hinteren Streifen setzen

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

#### Uhr synchronisieren (optional)

```json
{ "cmd": "sync", "ts": 1718000000 }
```

### Hinten → Vorne Nachrichten

#### Sensorabstände

Bei aktivem Rückfahrmodus mit 10 Hz gesendet. Alle Werte in Zentimetern. `999` bedeutet kein Hindernis erkannt.

```json
{ "type": "sensors", "left": 120, "center": 85, "right": 134 }
{ "type": "sensors", "left": 999, "center": 42, "right": 999 }
```

#### Befehlsbestätigung

```json
{ "type": "ack", "cmd": "reverse" }
```

### Verbindungsverhalten

* Der vordere ESP32 pairt beim ersten Start mit der im Flash gespeicherten MAC-Adresse des hinteren ESP32.
* Bei SPP-Verbindungsunterbrechung deaktiviert der vordere ESP32 den Rückfahrmodus und versucht alle 5 Sekunden eine Wiederverbindung.
* Nachrichten größer als 512 Bytes werden nicht erwartet und sollten als fehlerhaft behandelt werden.

***

## Zeitliche Anforderungen

| Einschränkung | Wert | Hinweise |
|---|---|---|
| BLE-Paketrate | Nur bei Änderung | Vermeidet BLE-Überlastung |
| SPP Sensorrate | 10 Hz (100 ms) | Bei aktivem Rückfahrmodus |
| HC-SR04 Sensorzyklus | 30 ms / Sensor | Versetzt zur Vermeidung von Übersprechen |
| OrchestratorAgent Takt | 10 ms | FreeRTOS-Task-Periode |
| FastLED `show()` Blockierzeit | ~3 ms | Bei 60-LED-Streifen mit 800 kHz |
| Schwellenwert für veraltete Sensordaten | 500 ms | Ältere Sensordaten → als `999` behandeln |
