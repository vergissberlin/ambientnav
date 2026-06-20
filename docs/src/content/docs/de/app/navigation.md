---
title: Navigation
description: So verwendest du die Turn-by-Turn-Navigation in der AmbientNav-App.
---

Die AmbientNav-App bietet Echtzeit-Navigation mit Sprachansagen und synchronem LED-Feedback auf dem vorderen Streifen. Diese Seite erklärt alles vom Öffnen der Karte bis zum Beenden einer Route.

---

## Karte öffnen

Wenn du AmbientNav startest, ist die Kartenansicht die Standardansicht. Die Karte wird von MapLibre betrieben und lädt Vektorkacheln vom konfigurierten Tile-Server.

- Deine aktuelle GPS-Position wird als blauer Punkt mit einem Richtungskegel angezeigt.
- Hat die App noch keine Standortberechtigung, erscheint oben ein Banner. Tippe darauf, um die Berechtigung in den Einstellungen zu erteilen.
- Ist ein Controller bereits gekoppelt und in der Nähe, zeigt der BLE-Verbindungsindikator in der oberen rechten Ecke grün. Navigationsanweisungen werden automatisch an den LED-Streifen gesendet, sobald eine Route aktiv ist.

:::note
Die Kartenansicht erfordert die Standortberechtigung **„Bei Nutzung der App"** oder **„Immer"**. Ohne diese Berechtigung kann die App keine Route von deiner aktuellen Position berechnen.
:::

---

## Ziel suchen

1. Tippe auf die **Suchleiste** oben in der Kartenansicht.
2. Beginne, eine Straßenadresse, einen Ortsnamen oder einen Point of Interest einzutippen.
3. Die App sendet eine Anfrage an den Geocoder und zeigt eine nach Relevanz sortierte Trefferliste unter der Suchleiste an.
4. Tippe auf ein Ergebnis, um es auf der Karte in der Vorschau anzuzeigen — eine Markierung erscheint am ausgewählten Ort und eine Übersichtskarte schiebt sich von unten ins Bild.
5. Prüfe die Adresse in der Übersichtskarte und tippe dann auf **Navigieren**, um eine Route zu berechnen.

:::note
Die Geocodierung erfordert eine Internetverbindung. Ist das Gerät offline, stehen nur zuvor gecachte Suchanfragen zur Verfügung. Im Offline-Routing-Modus wird die Route dennoch lokal berechnet — siehe [Online- vs. Offline-Modus](#online--vs-offline-modus) weiter unten.
:::

---

## Navigation starten

### Online- vs. Offline-Modus

| Modus | Routing-Engine | Voraussetzungen |
|---|---|---|
| **Online** | Valhalla (Cloud-gehostet) | Aktive Internetverbindung |
| **Offline** | OSRM (lokales Kartenpaket) | Offline-Kartenpaket für deine Region installiert |

Die App wählt automatisch die passende Engine basierend auf der Netzwerkverfügbarkeit. Du kannst den Modus auch manuell unter **Einstellungen → Routing** festlegen.

So startest du die Navigation:

1. Wähle ein Ziel aus und tippe bei sichtbarer Übersichtskarte auf **Navigieren**.
2. Die App berechnet die Route (im Online-Modus meist unter zwei Sekunden; OSRM ist ähnlich schnell, sobald die Kacheln geladen sind).
3. Die Karte passt sich deiner Fahrtrichtung an. Die Route wird als blaue Linie auf der Karte angezeigt.
4. Das Abbiegepanel erscheint oben auf dem Bildschirm.
5. Der vordere LED-Streifen wechselt vom Ambient-Ruhezustand zum ersten Navigationseffekt.

---

## Das Abbiegepanel verstehen

Das Abbiegepanel wird während einer Navigation oben in der Kartenansicht eingeblendet.

| Panelelement | Anzeige |
|---|---|
| **Abbiegesymbol** | Pfeilgrafik für das nächste Manöver (links, rechts, geradeaus, Wenden usw.) |
| **Entfernung** | Verbleibende Distanz bis zum nächsten Manöver (z. B. „180 m") |
| **Straßenname** | Name der Straße, in die du abbiegen wirst |
| **ETA-Leiste** (unten) | Gesamte verbleibende Strecke und voraussichtliche Ankunftszeit |

Das Panel aktualisiert sich in Echtzeit, während du die Route entlangfährst. Ist ein Manöver weniger als **200 m** entfernt, beginnt der vordere LED-Streifen mit dem Richtungs-Sweep-Effekt (siehe unten).

---

## Wie der LED-Streifen auf die Navigation reagiert

Der vordere Streifen spiegelt jede Abbiegeanweisung direkt in deinem Sichtfeld wider.

| Manöver | LED-Effekt |
|---|---|
| Innerhalb 200 m links abbiegen | Bernsteinfarbener Punkt wandert von der Mitte zur linken Kante |
| Innerhalb 200 m rechts abbiegen | Bernsteinfarbener Punkt wandert von der Mitte zur rechten Kante |
| Innerhalb 200 m geradeaus weiterfahren | Weißer Puls wächst und verblasst in der Streifenmitte |
| Linker Blinker aktiv | Linke Hälfte des Streifens blinkt bernsteinfarben |
| Rechter Blinker aktiv | Rechte Hälfte des Streifens blinkt bernsteinfarben |
| Warnblinkanlage aktiv | Gesamter Streifen blinkt bernsteinfarben |
| Kein aktives Manöver | Langsames Ambient-Atmen (konfigurierbare Farbe und Helligkeit) |

Der LED-Zustand wird jedes Mal aktualisiert, wenn die Navigations-Engine eine neue Anweisung ausgibt. Es gibt keine spürbare Verzögerung zwischen der Aktualisierung des Abbiegepanels und der LED-Änderung.

Eine ausführliche Erklärung aller Effekte und des zugrundeliegenden BLE-Paketformats findest du unter [Vorderer Navigations-LED-Streifen](/modules/front-led-strip/).

---

## Sprachführung (TTS)

AmbientNav verwendet die integrierte Text-to-Speech-Engine des Geräts (`flutter_tts`), um bevorstehende Manöver anzukündigen.

### Ansage-Trigger

| Abstand zum Manöver | Ansage |
|---|---|
| ~500 m | „In 500 Metern links abbiegen auf die Hauptstraße" |
| ~200 m | „In 200 Metern links abbiegen" |
| Am Manöver | „Jetzt links abbiegen" |

### Sprachführung anpassen

- **Lautstärke** — wird durch die Medienlautstärke deines Smartphones gesteuert.
- **Sprache** — die TTS-Engine verwendet automatisch die Systemsprache. Um eine andere Sprache zu nutzen, ändere sie unter **Einstellungen → Sprachführung** in der App.
- **Sprachführung deaktivieren** — deaktiviere **Sprachführung** unter **Einstellungen → Sprachführung**, um ausschließlich den LED-Streifen als Navigationshinweis zu verwenden.

:::note
Die Sprachführung wird standardmäßig über den Lautsprecher des Smartphones ausgegeben. Verbinde dein Smartphone mit dem Bluetooth-Audiosystem deines Fahrzeugs oder schließe es über den AUX-Eingang an, um Ansagen beim Fahren laut und deutlich zu hören.
:::

### Unterstützte Sprachen

Jede Sprache, die auf deinem Gerät als TTS-Stimme installiert ist, wird unterstützt. Gängige Optionen sind Deutsch, Englisch (US, UK, AU), Französisch, Spanisch, Italienisch und Niederländisch. Weitere Stimmen lassen sich in den Bedienungshilfen oder Spracheinstellungen deines Smartphones installieren.

---

## Navigation beenden

So beendest du eine Navigationssitzung jederzeit:

1. Tippe auf das **Stopp-Symbol** (Quadrat) in der unteren rechten Ecke der Kartenansicht, oder
2. Wische das Abbiegepanel nach oben und tippe im erscheinenden Sheet auf **Route beenden**.

Nach dem Beenden:

- Die Routenlinie verschwindet von der Karte.
- Das Abbiegepanel wird ausgeblendet.
- Der vordere LED-Streifen kehrt innerhalb einer Sekunde zum Ambient-Ruhezustand zurück.
- Die Sprachführung wird sofort beendet.

Die App beendet die Navigation **nicht** automatisch bei Ankunft — sie kündigt die Ankunft an und verbleibt auf dem Ankunftsbildschirm, bis du ihn schließt. So kannst du das Ziel noch einmal auf der Karte überprüfen, bevor der Streifen in den Ambient-Modus zurückkehrt.

---

## Tipps für das beste Erlebnis

| Tipp | Grund |
|---|---|
| Bildschirm eingeschaltet lassen (Einstellung „Bildschirm aktiv halten" in den Einstellungen aktivieren) | Auf manchen Geräten werden LED-Updates und das Routen-Tracking pausiert, wenn der Bildschirm sperrt |
| Smartphone auf Augenhöhe oder am Armaturenbrett befestigen | Einfacherer Blick auf das Abbiegepanel; weniger Kopfbewegung |
| Vor dem Navigationsstart mit dem Fahrzeugaudio verbinden | Sprachansagen sind trotz Motor- und Fahrgeräuschen klar zu hören |
| Offline-Kartenpaket vor langen Fahrten herunterladen | Stellt sicher, dass die Navigation in Tunneln, Parkhäusern oder Gebieten ohne Netzempfang funktioniert |
| Navigation von zu Hause aus starten, nicht vom Parkplatz | Die Route wird berechnet, bevor du dich bewegst; spart Zeit beim Hantieren mit dem Smartphone |

:::note
Die App fragt nach der Standortberechtigung „Immer", wenn du das Hintergrund-Routen-Tracking aktivierst. Dies ist optional — „Bei Nutzung der App" reicht für den typischen Einsatz im Fahrzeug mit eingeschaltetem Bildschirm aus.
:::
