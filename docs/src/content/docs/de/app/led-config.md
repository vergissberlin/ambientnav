---
title: LED-Konfiguration
description: LED-Anzahl, Helligkeit und Ruhezustand-Effekte direkt in der AmbientNav-App anpassen.
---

Die AmbientNav-App ermöglicht es dir, den vorderen LED-Streifen direkt vom Smartphone aus über die gebondete BLE-Verbindung zu konfigurieren. Änderungen werden an den ESP32 gesendet, sofort übernommen und im Non-Volatile Storage gespeichert — deine Einstellungen überleben Neustarts.

:::note
Für die LED-Konfiguration ist eine **gekoppelte und gebondete** Verbindung erforderlich. Erscheint der Controller in der Controller-Liste mit grauem Indikator, warte auf die automatische Wiederverbindung oder gehe näher an das Gerät heran.
:::

---

## Was du konfigurieren kannst

| Parameter | Bereich | Standard | Wirkung |
|---|---|---|---|
| **LED-Anzahl** | 1–144 | 60 | Muss der tatsächlichen Anzahl der LEDs auf dem Streifen entsprechen |
| **Helligkeit** | 0–255 | 128 (50 %) | Globale Helligkeitsobergrenze für alle Effekte |
| **Ruhezustand-Effekt** | Ambient (Atmen) | Ambient | Effekt, der angezeigt wird, wenn keine Navigation aktiv ist |
| **Effektfarbe** | Vollständiges RGB | Cyan `#19E3FF` | Farbe des Ambient-Atemeffekts |
| **Effektgeschwindigkeit** | Langsam / Mittel / Schnell | Mittel | Atemzyklusdauer des Ambient-Effekts |

Navigationseffekte (Abbiegesweeps, Blinker) sind immer bernsteinfarben und nicht vom Benutzer konfigurierbar — sie sind durch das Navigationsprotokoll festgelegt.

---

## Controller-Detailbildschirm öffnen

1. Tippe auf den Tab **Controller** in der unteren Navigationsleiste.
2. Tippe auf die Zeile deines gekoppelten Controllers (z. B. **AmbientNav-Front**).
3. Der Controller-Detailbildschirm öffnet sich. Er hat zwei Tabs oben:
   - **Status** — zeigt Live-RSSI, Firmware-Version, Betriebszeit und Sensorwerte.
   - **LED-Konfig** — das LED-Konfigurationsformular.
4. Tippe auf den Tab **LED-Konfig**.

Das Formular wird automatisch mit den aktuell auf dem ESP32 gespeicherten Werten befüllt. Während die App die aktuelle Konfiguration über BLE liest, siehst du kurz einen Ladekreisel.

---

## LED-Anzahl

Das Feld „LED-Anzahl" teilt der Firmware mit, wie viele LEDs physisch auf dem vorderen Streifen vorhanden sind.

- Der Standardwert ist **60**, passend zu einem 1 m langen Abschnitt eines WS2812B-Streifens mit 60 LEDs/m.
- Ist dein Streifen länger oder kürzer, passe diesen Wert entsprechend an.
- Ist die eingestellte Anzahl höher als die tatsächliche Streifenlänge, versucht das Animationsmuster, nicht vorhandene Pixel anzusprechen — der Effekt bricht ab oder wiederholt sich unbemerkt, die Animationen können jedoch ungleichmäßig wirken.
- Ist die eingestellte Anzahl niedriger als die Streifenlänge, ist das unbedenklich; die übrigen LEDs am Ende bleiben einfach aus.

**Häufige Werte:**

| Streifenlänge | LEDs/m | LED-Anzahl |
|---|---|---|
| 0,5 m | 60 | 30 |
| 1,0 m | 60 | 60 (Standard) |
| 1,5 m | 60 | 90 |
| 1,0 m | 144 | 144 |

Gib den Wert in das numerische Feld **LED-Anzahl** ein und fahre mit dem Speichern fort (siehe [Konfiguration speichern und anwenden](#konfiguration-speichern-und-anwenden)).

---

## Helligkeit

Der Helligkeitsregler steuert die globale Intensitätsobergrenze für alle Effekte.

- Die Skala reicht von **0 bis 255**, wobei 255 maximale Helligkeit (alle Kanäle auf voller Leistung) und 0 Ausgeschaltet bedeutet.
- Der Standardwert ist **128** (~50 %), was bei Tageslicht gut sichtbar ist und dabei den Stromverbrauch in einem vernünftigen Rahmen hält.
- Der Regler aktualisiert eine Live-Vorschau auf dem Bildschirm, sodass du die Helligkeit vor dem Speichern beurteilen kannst.

### Stromverbrauch bei hoher Helligkeit

Jede WS2812B-LED zieht bei vollem Weiß bis zu 60 mA. Bei 60 LEDs und voller Helligkeit:

| Helligkeit | Ungefährer Strom (60 LEDs, weiß) |
|---|---|
| 64 (25 %) | ~450 mA |
| 128 (50 %) | ~900 mA |
| 192 (75 %) | ~1 350 mA |
| 255 (100 %) | ~1 800 mA |

:::caution
Helligkeitswerte über **200** können die 3-A-Kapazität des 5-V-Step-Down-Wandlers überschreiten, wenn der Streifen volles Weiß anzeigt. Stelle sicher, dass ein **1 000 µF Bulk-Kondensator** am LED-Streifen-Anschluss installiert ist, um Stromspitzen abzufangen. Dauerbetrieb bei voller Helligkeit ohne ausreichend dimensionierte Stromversorgung kann zu Spannungseinbrüchen und ESP32-Resets führen.
:::

---

## Ruhezustand-Effekt

Der Ruhezustand-Effekt wird auf dem vorderen Streifen angezeigt, wenn kein Navigationsmanöver aktiv ist. Tippe auf das Dropdown **Effekt**, um aus den verfügbaren Optionen zu wählen.

| Effektname | Beschreibung |
|---|---|
| **Ambient (Atmen)** | Langsames Sinuswellen-Fade von aus bis zur vollen Farbe und zurück. Standard. |
| **Einfarbig** | Der Streifen bleibt bei der konfigurierten Helligkeit in einer konstanten Farbe. |
| **Color Wipe** | Eine einzelne LED wandert von einem Ende zum anderen und hinterlässt die Farbe. |
| **Sparkle** | Zufällige LEDs blitzen kurz bei voller Helligkeit vor einem dunklen Hintergrund auf. |

:::note
Navigationseffekte überschreiben immer den Ruhezustand-Effekt, wenn ein Manöver innerhalb von 200 m liegt. Der Ruhezustand-Effekt wird automatisch wieder aufgenommen, wenn das Manöver abgeschlossen ist.
:::

---

## Effektfarbe und -geschwindigkeit

Wenn der Ruhezustand-Effekt **Ambient (Atmen)** oder **Einfarbig** ausgewählt ist, erscheinen zwei zusätzliche Bedienelemente:

### Farbauswahl

Tippe auf das Farbfeld, um den Farbwähler zu öffnen. Du kannst:

- Das Farbton-/Sättigungsrad verschieben
- Einen RGB-Wert manuell eingeben (drei Felder mit Werten von 0–255)
- Direkt einen Hex-Code eingeben (z. B. `#19E3FF`)

Das Live-Vorschau-Widget aktualisiert sich beim Verschieben. Die gewählte Farbe wird ausschließlich vom Ruhezustand-Effekt verwendet; Navigationseffekte verwenden ihre eigene, fest definierte bernsteinfarbene Farbe.

### Geschwindigkeitsauswahl (nur Ambient-Atmen)

| Geschwindigkeit | Atemzyklusdauer |
|---|---|
| Langsam | ~4 Sekunden |
| Mittel | ~2,5 Sekunden (Standard) |
| Schnell | ~1,2 Sekunden |

Ein schnelleres Atemmuster ist auffälliger, kann beim Fahren aber ablenken. Mittel oder Langsam werden für den Alltagseinsatz empfohlen.

---

## Aktuelle Konfiguration auslesen

Jedes Mal, wenn du den Tab **LED-Konfig** öffnest, stellt die App eine BLE-Leseanfrage an den ESP32 und befüllt alle Formularfelder mit den aktuell auf dem Gerät gespeicherten Werten. Dies dauert über eine typische BLE-Verbindung ca. 0,5–1 Sekunde.

Zeigen die Formularfelder Nullen an oder erscheinen sie leer, ist das Lesen fehlgeschlagen — das bedeutet in der Regel, dass die Verbindung getrennt wurde. Prüfe den Verbindungsindikator oben rechts im Detailbildschirm und warte, bis er grün wird, dann ziehe zum Aktualisieren nach unten.

---

## Konfiguration speichern und anwenden

1. Nachdem du ein Feld angepasst hast, wird der **Übernehmen**-Button am unteren Ende des Formulars aktiv (wechselt von Grau zur Akzentfarbe).
2. Tippe auf **Übernehmen**.
3. Die App kodiert die Konfiguration in einen BLE-Schreibvorgang auf die Konfigurations-Characteristic des ESP32.
4. Der ESP32 speichert die Werte im NVS und initialisiert den LED-Treiber sofort mit den neuen Parametern neu.
5. Eine Bestätigungsmeldung erscheint: „Konfiguration gespeichert".

Änderungen an **Helligkeit** und **Effektfarbe** wirken sich auf den LED-Streifen innerhalb eines Render-Ticks (~10 ms) aus — du siehst die Änderung nahezu sofort.

Änderungen an **LED-Anzahl** oder **Ruhezustand-Effekt** benötigen einen kleinen Moment länger, da die Firmware den FastLED-Puffer neu initialisiert.

:::note
Du musst den ESP32 nach dem Speichern nicht neu starten. Die neue Konfiguration ist sofort aktiv und bleibt über Neustarts hinweg erhalten.
:::
