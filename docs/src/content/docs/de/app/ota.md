---
title: Firmware-Updates (OTA)
description: ESP32-Firmware kabellos über Bluetooth LE direkt aus der AmbientNav-App aktualisieren.
---

Over-the-Air (OTA) Firmware-Updates ermöglichen es dir, neue ESP32-Firmware direkt vom Smartphone über die gebondete BLE-Verbindung aufzuspielen — kein USB-Kabel, kein Computer, keine Toolchain erforderlich. Der ESP32 schreibt die neue Firmware in seine sekundäre OTA-Partition, während die aktuelle Firmware weiterläuft, und startet dann in die neue Version neu.

---

## Wann du OTA verwenden solltest

| Grund | Aktion |
|---|---|
| Eine neue AmbientNav-Version ist auf GitHub verfügbar | Lade die aktuelle `firmware-front.bin` herunter und flashe sie per OTA |
| Du erlebst einen Fehler, der in einer neueren Version behoben ist | Prüfe die GitHub-Release-Notes und führe dann das Update durch |
| Du möchtest die aktuell installierte Version prüfen | Öffne den Status-Tab im Controller-Detailbildschirm |

Die installierte Firmware-Version ist unter **Controller → [dein Gerät] → Status → Firmware-Version** sichtbar. Vergleiche sie mit dem [aktuellen GitHub-Release](https://github.com/vergissberlin/ambientnav/releases/latest), um zu entscheiden, ob ein Update nötig ist.

---

## Voraussetzungen

Stelle vor dem Start eines OTA-Updates sicher, dass alle folgenden Bedingungen erfüllt sind:

| Anforderung | Warum das wichtig ist |
|---|---|
| Gerät ist **gekoppelt und gebondet** | OTA-Schreibvorgänge sind hinter dem authentifizierten BLE-Bond gesichert |
| Smartphone ist **~1 m** vom Gerät entfernt | Der BLE-Durchsatz sinkt ab 1–2 m deutlich; OTA kann ins Stocken geraten |
| Gerät hat **stabile Stromversorgung** (Netz oder Fahrzeugbatterie, nicht nur USB-Bus) | Ein Spannungseinbruch mitten im Update kann die OTA-Partition beschädigen |
| Smartphone hat ausreichend **Akku oder ist am Laden** | Ein leerer Akku während OTA lässt das Gerät in einem unvollständigen Zustand |
| Du hast die korrekte Firmware-Binärdatei | Vordere und hintere Platinen verwenden unterschiedliche Binärdateien; nicht verwechseln |

:::caution
**Trenne die BLE-Verbindung nicht, schalte das Gerät nicht aus und beende die App nicht zwangsweise**, während ein OTA-Update läuft. Der ESP32 bestätigt die neue Firmware erst, wenn das vollständige Image empfangen und verifiziert wurde. Wird die Verbindung unterbrochen, startet das Gerät mit der vorherigen Firmware neu und das unvollständige Image wird verworfen — aber ein unnötiger Neustart des Updates kostet Zeit.
:::

---

## Schritt-für-Schritt OTA-Update

### Schritt 1 — Firmware-Update-Tab öffnen

1. Tippe auf den Tab **Controller** in der unteren Navigationsleiste.
2. Tippe auf die Zeile deines gekoppelten Controllers.
3. Tippe im Controller-Detailbildschirm auf den Tab **Firmware-Update**.

Der Tab zeigt die aktuell installierte Firmware-Version und einen Button zum Starten des Updates.

### Schritt 2 — Firmware-Datei beschaffen

Wähle eine von zwei Methoden:

**Methode A — Von GitHub Releases herunterladen (empfohlen)**

1. Tippe auf **Aktuelle Firmware herunterladen**.
2. Die App ruft das neueste Release von der GitHub-API ab, zeigt den Release-Tag und eine Changelog-Zusammenfassung an und lädt `firmware-front.bin` an einen temporären Speicherort herunter.
3. Tippe auf **Diese Datei verwenden**, wenn der Download abgeschlossen ist.

**Methode B — Datei auswählen**

1. Tippe auf **Datei auswählen**.
2. Der Systemdatei-Picker öffnet sich.
3. Navigiere zur `.bin`-Firmware-Datei, die du manuell heruntergeladen hast (z. B. `ambientnav-v0.3.0-firmware-front.bin`).
4. Wähle die Datei aus.

Der Firmware-Update-Tab zeigt den ausgewählten Dateinamen und die Dateigröße an (typischerweise ca. **400 KB**).

### Schritt 3 — Update starten

1. Prüfe, ob Dateiname und Dateigröße korrekt aussehen.
2. Tippe auf **Update starten**.
3. Ein Bestätigungsdialog erscheint: „Die Firmware auf AmbientNav-Front wird aktualisiert. Das Gerät startet nach dem Update neu. Fortfahren?"
4. Tippe auf **Aktualisieren**.

### Schritt 4 — Fortschritt beobachten

Ein Fortschrittsbalken füllt sich, während Firmware-Blöcke über BLE übertragen werden.

| Phase | Was du siehst |
|---|---|
| **Übertragung** | Fortschrittsbalken füllt sich von 0 % auf 100 % mit Byte-Zähler |
| **Verifizierung** | Kurze Pause bei 100 %, während der ESP32 die Prüfsumme des Images verifiziert |
| **Bestätigung** | Meldung „Update wird bestätigt …" — der ESP32 markiert die neue Partition als startfähig |
| **Neustart** | „Gerät startet neu …" — BLE-Verbindung trennt sich kurz |
| **Wiederverbindung** | App verbindet sich automatisch neu; Versionsnummer im Status-Tab aktualisiert sich |

Der gesamte Prozess dauert für ein ~400 KB Image typischerweise **1 bis 2 Minuten**. Der effektive BLE-Durchsatz beträgt je nach Signalqualität und Smartphone-Modell ca. **5–15 KB/s**.

:::note
BLE OTA ist im Vergleich zum USB-Flashen bewusst langsamer. Das ist normal. Nimm nicht an, dass der Prozess hängt, solange der Fortschrittsbalken sich in den letzten 30 Sekunden bewegt hat.
:::

### Schritt 5 — Update verifizieren

1. Nach dem Neustart des Geräts verbindet sich die App automatisch neu (in der Regel innerhalb von 5–10 Sekunden).
2. Öffne den Tab **Status** im Controller-Detailbildschirm.
3. Prüfe, ob unter **Firmware-Version** die neue Versionsnummer steht (z. B. `0.3.0`).

---

## Zeitreferenz

| Image-Größe | Durchsatz | Geschätzte Dauer |
|---|---|---|
| 400 KB | 5 KB/s (schwaches Signal) | ~80 Sekunden |
| 400 KB | 10 KB/s (gutes Signal) | ~40 Sekunden |
| 400 KB | 15 KB/s (ausgezeichnetes Signal) | ~27 Sekunden |

Die Signalqualität ist der entscheidende Faktor. Hältst du das Smartphone 30–50 cm vor den Controller, verbessert sich der Durchsatz spürbar.

---

## Was passiert, wenn das Update fehlschlägt

Der ESP32 verwendet ein **Dual-Partition OTA-Schema**. Firmware wird immer in die inaktive Partition geschrieben; die aktive Partition läuft weiter, bis das neue Image verifiziert und bestätigt wurde. Das bedeutet:

- Wird die Übertragung unterbrochen (BLE-Abbruch, Stromausfall), bleibt die aktive Partition unberührt und das Gerät startet normal mit der vorherigen Firmware neu.
- Schlägt die Prüfsummenverifizierung des Images fehl, wird der Bestätigungsschritt übersprungen und das Gerät startet mit der vorherigen Firmware neu.
- In beiden Fällen kehrt der LED-Streifen nach dem Neustart zum Ambient-Atemeffekt zurück — das bestätigt, dass das Gerät läuft und die vorherige Firmware intakt ist.

So wiederholst du das Update nach einem Fehlschlag:

1. Warte, bis sich das Gerät wieder verbindet (grüner Indikator in der Controller-Liste).
2. Halte das Smartphone näher an das Gerät.
3. Gehe zurück zu **Firmware-Update** und tippe erneut auf **Update starten**.

:::caution
Verbindet sich das Gerät nach einem fehlgeschlagenen Update **nicht** wieder und der LED-Streifen zeigt keine Aktivität (dunkler Streifen), könnte die OTA-Partition teilweise beschädigt sein. Verwende in diesem Fall ein USB-Kabel und das [browserbasierte Flash-Tool](/flash/) oder [PlatformIO](/flash-firmware/), um die Firmware über USB neu zu flashen — das umgeht OTA vollständig.
:::

---

## Vordere vs. hintere Firmware

Die vorderen und hinteren ESP32-Platinen verwenden unterschiedliche Firmware-Images.

| Platine | Binärdatei | OTA über App |
|---|---|---|
| Vorne (Master) | `firmware-front.bin` | Ja — über die App |
| Hinten (Slave) | `firmware-rear.bin` | Noch nicht — USB verwenden |

Die hintere Platine bietet derzeit keine BLE-OTA-Schnittstelle. Aktualisiere sie mit dem browserbasierten Flash-Tool unter [Firmware flashen](/flash/) oder mit PlatformIO über USB.
