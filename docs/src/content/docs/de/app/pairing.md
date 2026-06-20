---
title: Kopplung & Sicherheit
description: So koppelst du dein Smartphone mit dem AmbientNav Controller per Bluetooth LE Secure Passkey Pairing.
---

AmbientNav verwendet **Bluetooth LE Secure Passkey Pairing mit Bonding**, um Konfigurations- und Firmware-Update-Vorgänge zu schützen. Ohne ein gepaartes Bond kann die App weiterhin Navigation anzeigen und der LED-Streifen reagiert weiterhin auf Routenereignisse — Änderungen an LED-Einstellungen und OTA-Firmware-Updates sind jedoch von einem ungekoppelten Gerät aus nicht möglich.

---

## Warum Kopplung erforderlich ist

Die Kopplung stellt einen verschlüsselten, authentifizierten Kanal zwischen der App und dem ESP32 Controller her. Dies verhindert:

- Unbefugte Änderungen an LED-Helligkeit oder -Effekten
- Unerwünschte OTA-Firmware-Uploads, die den Controller beschädigen könnten
- Replay-Angriffe auf BLE-Konfigurations-Characteristics

Der auf dem Geräteaufkleber aufgedruckte Passkey wird einmalig während der Fertigung generiert und im Non-Volatile Storage (NVS) des ESP32 gespeichert. Er ändert sich nicht, solange die Firmware nicht neu geflasht wird.

---

## Voraussetzungen

Stelle vor dem Start sicher, dass:

- Die **AmbientNav-App** auf deinem Smartphone installiert ist (iOS oder Android).
- Der **vordere ESP32 Controller** eingeschaltet und in BLE-Reichweite ist (~10 m, idealerweise näher bei der ersten Kopplung).
- Bluetooth auf deinem Smartphone aktiviert ist.
- Der Controller mit einer Firmware geflasht ist, die das Passkey-Pairing unterstützt (v0.2.0 oder höher).

:::note
Du musst **nicht** die Bluetooth-Einstellungen deines Smartphones öffnen. Die App verwaltet die BLE-Verbindung und Kopplung vollständig eigenständig.
:::

---

## Schritt-für-Schritt-Kopplung

### Schritt 1 — Controller-Bildschirm öffnen

1. Starte die **AmbientNav**-App.
2. Tippe auf den Tab **Controller** in der unteren Navigationsleiste (oder auf das Controller-Symbol in der oberen rechten Ecke der Kartenansicht).
3. Der Controller-Bildschirm listet alle zuvor gekoppelten Geräte auf. Bei der ersten Nutzung ist die Liste leer.

### Schritt 2 — Neuen Controller hinzufügen

1. Tippe auf **Controller hinzufügen** (den `+`-Button in der oberen rechten Ecke des Controller-Bildschirms).
2. Die App beginnt, nach AmbientNav BLE-Geräten in der Nähe zu suchen. Ein Ladekreisel und die Beschriftung „Suche läuft …" erscheinen.

### Schritt 3 — Gerät auswählen

1. Nach wenigen Sekunden erscheinen Geräte in der Liste mit ihrem BLE-Werbename (z. B. **AmbientNav-Front**) und der aktuellen RSSI-Signalstärke.
2. Tippe auf das Gerät, das du koppeln möchtest. Sind mehrere Geräte aufgelistet (z. B. in einer Garage mit mehreren Fahrzeugen), erkennst du das richtige an seiner Signalstärke — das nächstgelegene Gerät zeigt den höchsten RSSI-Wert (näher an 0 dBm).

:::note
Erscheint das Gerät nach 15 Sekunden nicht, lies den Abschnitt [Fehlerbehebung](#fehlerbehebung) weiter unten.
:::

### Schritt 4 — 6-stelligen Passkey eingeben

1. Ein Passkey-Eingabedialog erscheint auf dem Bildschirm.
2. Gib den **6-stelligen numerischen Passkey** ein, der auf dem weißen Aufkleber am Gehäuse des ESP32 Controllers aufgedruckt ist (z. B. `482 916`).
3. Tippe auf **Bestätigen**.

:::caution
Der Passkey besteht ausschließlich aus Ziffern. Verwechsle nicht die Ziffer `0` (null) mit dem Buchstaben `O` oder die Ziffer `1` (eins) mit dem Buchstaben `l`. Der Aufkleber verwendet eine Schriftart, die diese Zeichen eindeutig unterscheidet.
:::

### Schritt 5 — Kopplung abgeschlossen

Ist der Passkey korrekt, tauschen App und Controller Schlüssel aus und erstellen ein **Bond**. Du siehst:

- Eine Erfolgsmeldung: „Mit AmbientNav-Front gekoppelt"
- Das Gerät erscheint in der Controller-Liste mit einem **grünen Verbindungsindikator**
- Der RSSI-Wert aktualisiert sich in Echtzeit

Das Bond wird sowohl auf dem Smartphone als auch auf dem ESP32 gespeichert. Zukünftige Verbindungen erfolgen automatisch — du musst den Passkey nicht erneut eingeben.

---

## Verbindungsstatus-Indikatoren

Der Controller-Bildschirm zeigt den Live-Verbindungsstatus für jedes gekoppelte Gerät.

| Indikator | Bedeutung |
|---|---|
| Grüner Punkt + RSSI-Wert (z. B. `-52 dBm`) | Verbunden und gebondet |
| Gelber Punkt | Verbindung wird hergestellt / wiederhergestellt |
| Grauer Punkt | Nicht in Reichweite oder nicht eingeschaltet |
| Roter Punkt | Verbindungsfehler (tippe, um es erneut zu versuchen) |

### RSSI-Signalstärke-Übersicht

| RSSI-Bereich | Signalqualität | Hinweise |
|---|---|---|
| `-40 dBm` bis `0 dBm` | Ausgezeichnet | Gerät ist sehr nah (<1 m) |
| `-60 dBm` bis `-41 dBm` | Gut | Zuverlässig für alle Vorgänge einschließlich OTA |
| `-75 dBm` bis `-61 dBm` | Ausreichend | Navigation und Konfiguration funktionieren; OTA kann langsamer sein |
| Unter `-75 dBm` | Schwach | Näher herangehen; OTA-Updates werden nicht empfohlen |

---

## Automatische Wiederverbindung

Nach dem Bonding verbindet sich die App in folgenden Situationen automatisch wieder mit dem Controller:

- Die App wird geöffnet, während der Controller eingeschaltet ist
- Der Controller schaltet sich ein, während die App bereits läuft
- Ein kurzzeitiger BLE-Verbindungsabbruch wird behoben (die App versucht es alle 5 Sekunden erneut)

Der Indikator zeigt während der Wiederverbindung kurz gelb an und wechselt dann wieder auf grün.

---

## Kopplung aufheben / Gerät vergessen

So entfernst du ein gekoppeltes Gerät aus der App:

1. Gehe zu **Controller**.
2. Wische auf der Gerätezeile nach links (iOS) oder halte sie gedrückt (Android).
3. Tippe auf **Entfernen** (iOS) oder **Vergessen** (Android).
4. Bestätige die Aktion im Dialog.

Damit wird das Bond aus der App-Datenbank gelöscht. Der Bond-Eintrag auf dem ESP32 selbst wird **nicht** automatisch gelöscht — der Controller versucht weiterhin, sich mit dem Smartphone zu verbinden. Um das Bond auch auf der ESP32-Seite vollständig zu löschen, gibt es zwei Möglichkeiten:

- Nutze die Option **Werksreset** im Controller-Detailbildschirm (erfordert eine aktive Verbindung), oder
- Flash die Firmware neu (löscht alle NVS-Daten einschließlich des Bonds und des Pairing-Zählers).

---

## Fehlerbehebung

### Das Gerät erscheint beim Scannen nicht

- Stelle sicher, dass der vordere ESP32 eingeschaltet ist. Der vordere LED-Streifen sollte den Ambient-Atemeffekt anzeigen.
- Prüfe, ob Bluetooth auf deinem Smartphone aktiviert ist.
- Gehe beim ersten Scan näher an das Gerät heran (innerhalb von 2 m).
- Starte den Scan neu, indem du erneut auf **Controller hinzufügen** tippst.
- War der Controller zuvor mit einem anderen Smartphone gekoppelt, ignoriert er möglicherweise Werbepakete von neuen Geräten. Flash die Firmware neu, um den Bond-Zustand zurückzusetzen.

### Falscher Passkey eingegeben

- Die App zeigt: „Kopplung fehlgeschlagen — falscher Passkey". Tippe auf **Erneut versuchen**, um ihn neu einzugeben.
- Nach einer begrenzten Anzahl von Versuchen blockiert der ESP32 vorübergehend weitere Kopplungsanfragen (60 Sekunden Abkühlung). Warte, dann versuch es erneut.
- Überprüfe den Aufkleber nochmals — der Passkey besteht aus genau 6 Ziffern ohne Buchstaben.

### Gerät wird als „Bereits gekoppelt" angezeigt, verbindet sich aber nicht

Dies kann passieren, wenn der Bond-Eintrag auf dem Smartphone gelöscht wurde (z. B. durch einen Smartphone-Reset), der ESP32 aber noch das alte Bond gespeichert hat.

1. Unter iOS: gehe zu **Einstellungen → Bluetooth**, suche das Gerät in der Liste, tippe auf ⓘ und wähle **Dieses Gerät vergessen**.
2. Unter Android: gehe zu **Einstellungen → Verbundene Geräte → Zuvor verbundene Geräte**, suche das Gerät und tippe auf **Vergessen**.
3. Flash die ESP32-Firmware neu, um den dortigen Bond-Eintrag zu löschen.
4. Starte die Kopplung von vorne gemäß den obigen Schritten.

### Kopplungsdialog erscheint nicht

- Beende die App vollständig und öffne sie erneut, dann starte den Scan erneut.
- Stelle unter Android sicher, dass die App die Berechtigungen **Geräte in der Nähe** (BLUETOOTH_CONNECT und BLUETOOTH_SCAN) besitzt: Einstellungen → Apps → AmbientNav → Berechtigungen.
