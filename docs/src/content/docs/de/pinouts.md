---
title: Pin-Belegung & Verkabelung
description: GPIO-Pin-Belegung und Verkabelungsanleitung für die AmbientNav ESP32-Boards.
---

Diese Seite zeigt genau, welche Leitung wo an jedem ESP32-Board angeschlossen wird. Folge den Tabellen unten und beide Boards sind korrekt verdrahtet.

---

## ESP32 Front-Board (Master)

Das vordere Board verbindet sich über Bluetooth LE mit dem iPhone und steuert den vorderen LED-Streifen.

| Funktion | GPIO | Leitungsfarbe |
|---|---|---|
| LED-Streifen Data | **5** | Weiß |
| Rückwärtsgang-Signal *(optional)* | **4** | Gelb |
| 5-V-Versorgung | **VIN** | Rot |
| Masse | **GND** | Schwarz |

### 30-Pin ESP32 DevKit — Pin-Belegung Front

```
                    ┌──────────────────┐
              EN ──┤ EN           D23 ├── (frei)
       (frei) D36 ──┤ VP           D22 ├── (frei)
       (frei) D39 ──┤ VN           TX0 ├── Seriell TX (Debug)
       (frei) D34 ──┤ D34          RX0 ├── Seriell RX (Debug)
       (frei) D35 ──┤ D35          D21 ├── (frei)
       (frei) D32 ──┤ D32          D19 ├── (frei)
       (frei) D33 ──┤ D33          D18 ├── (frei)
       (frei) D25 ──┤ D25           D5 ├──── LED-Data  ◄ WEISS
       (frei) D26 ──┤ D26          TX2 ├── (frei)
       (frei) D27 ──┤ D27          RX2 ├── (frei)
  Rückw.-Sig. D14 ──┤ D14          D4  ├──── Rückw.-Sig. ◄ GELB  (opt.)
       (frei) D12 ──┤ D12          D2  ├── (frei)
       (frei) D13 ──┤ D13          D15 ├── (frei)
         GND GND ──┤ GND          GND ├──── Masse ◄ SCHWARZ
         +5V VIN ──┤ VIN          3V3 ├── (3,3-V-Ausgang — nicht für LED-Versorgung)
                    └──────────────────┘
```

### Anschluss des vorderen LED-Streifens

Den **330-Ω-Widerstand** in Reihe auf der Datenleitung nahe dem ESP32 einbauen.  
Den **1000-µF-Kondensator** zwischen 5 V und GND am LED-Streifen-Eingang platzieren.

```
  ESP32 GPIO 5 ──[330 Ω]──── LED Din
  5-V-Versorgung ──┬──────── LED 5V
                   └──[1000 µF]─ LED GND
  GND ────────────────────── LED GND
```

---

## ESP32 Rear-Board (Slave)

Das hintere Board empfängt Befehle vom Front-Board über Bluetooth Classic, steuert den hinteren LED-Streifen und liest drei HC-SR04-Ultraschallsensoren aus.

| Funktion | GPIO | Leitungsfarbe |
|---|---|---|
| LED-Streifen Data | **18** | Weiß |
| HC-SR04 Links — TRIG | **25** | Orange |
| HC-SR04 Links — ECHO | **34** | Grün |
| HC-SR04 Mitte — TRIG | **26** | Orange |
| HC-SR04 Mitte — ECHO | **35** | Grün |
| HC-SR04 Rechts — TRIG | **27** | Orange |
| HC-SR04 Rechts — ECHO | **36** | Grün |
| 5-V-Versorgung | **VIN** | Rot |
| Masse | **GND** | Schwarz |

### 30-Pin ESP32 DevKit — Pin-Belegung Rear

```
                    ┌──────────────────┐
              EN ──┤ EN           D23 ├── (frei)
Echo L    D36/VP ──┤ VP           D22 ├── (frei)
Echo C    D39/VN ──┤ VN           TX0 ├── Seriell TX (Debug)
Echo R      D34 ──┤ D34          RX0 ├── Seriell RX (Debug)
            D35 ──┤ D35          D21 ├── (frei)
            D32 ──┤ D32          D19 ├── (frei)
            D33 ──┤ D33          D18 ├──── LED-Data  ◄ WEISS
  Trig L    D25 ──┤ D25           D5 ├── (frei)
  Trig C    D26 ──┤ D26          TX2 ├── (frei)
  Trig R    D27 ──┤ D27          RX2 ├── (frei)
            D14 ──┤ D14           D4 ├── (frei)
            D12 ──┤ D12           D2 ├── (frei)
            D13 ──┤ D13          D15 ├── (frei)
        GND GND ──┤ GND          GND ├──── Masse ◄ SCHWARZ
        +5V VIN ──┤ VIN          3V3 ├── 3,3 V für HC-SR04 VCC
                    └──────────────────┘
```

### HC-SR04-Verdrahtung (pro Sensor)

:::caution[Spannungswarnung]
Der HC-SR04 ECHO-Ausgang gibt 5 V aus. Der ESP32-GPIO verträgt nur 3,3 V.  
Verwende einen Spannungsteiler (1 kΩ + 2 kΩ) oder einen Pegelwandler auf jeder ECHO-Leitung.
:::

```
  HC-SR04 VCC  ──── 3,3 V (ESP32 3V3-Pin)
  HC-SR04 GND  ──── GND
  HC-SR04 TRIG ──── ESP32 TRIG-Pin (direkt, 3,3-V-Signal ist ausreichend)
  HC-SR04 ECHO ──[1 kΩ]──┬──── ESP32 ECHO-Pin
                          └──[2 kΩ]──── GND
```

Für alle drei Sensoren (Links, Mitte, Rechts) mit den GPIO-Paaren aus der obigen Tabelle wiederholen.

---

## Stromversorgung

Die LEDs dominieren den Strombedarf. Einen dedizierten **5-V / 3-A** DC-DC-Wandler für jedes Board verwenden. Den LED-Streifen nicht über den VIN-Pin des ESP32 an einer USB-Verbindung betreiben.

| Komponente | Strom (typisch) |
|---|---|
| ESP32 (aktiv, Bluetooth ein) | ~240 mA |
| WS2812B, 60 LEDs @ 50 % weiß | ~900 mA |
| 3× HC-SR04 (nur hinten) | ~45 mA |
| **Gesamt pro Board** | **~1,2 – 1,4 A** |

Versorgungs- und Signal-GND an einem einzigen Punkt verbinden (Stern-Topologie), um Erdschleifen zu vermeiden.

---

## WokWi-Simulator

[WokWi](https://wokwi.com) ist ein kostenloser Browser-Elektroniksimulator, der den ESP32, WS2812B NeoPixel und HC-SR04-Sensoren unterstützt. Mit den folgenden Diagrammen können die Schaltkreise ohne physische Hardware simuliert werden.

**Diagramm in WokWi öffnen:**
1. Auf [wokwi.com](https://wokwi.com) ein neues ESP32-Projekt erstellen.
2. Den Tab `diagram.json` anklicken und den Inhalt durch das JSON unten ersetzen.
3. **Simulation starten** drücken.

Die `diagram.json`-Dateien befinden sich auch im Repository unter `wokwi/front/` und `wokwi/rear/`.

### Front-Board — `wokwi/front/diagram.json`

Drei NeoPixel repräsentieren einen Abschnitt des WS2812B-LED-Streifens. GPIO 5 treibt die Datenleitung über einen 330-Ω-Widerstand.

```json
{
  "version": 1,
  "author": "AmbientNav",
  "editor": "wokwi",
  "parts": [
    {
      "type": "wokwi-esp32-devkit-v1",
      "id": "esp32",
      "top": 32,
      "left": 208,
      "attrs": {}
    },
    {
      "type": "wokwi-resistor",
      "id": "r_led",
      "top": 174.72,
      "left": 64,
      "rotate": 90,
      "attrs": { "value": "330" }
    },
    {
      "type": "wokwi-neopixel",
      "id": "px1",
      "top": 128,
      "left": -64,
      "attrs": {}
    },
    {
      "type": "wokwi-neopixel",
      "id": "px2",
      "top": 176,
      "left": -64,
      "attrs": {}
    },
    {
      "type": "wokwi-neopixel",
      "id": "px3",
      "top": 224,
      "left": -64,
      "attrs": {}
    }
  ],
  "connections": [
    ["esp32:D5",    "r_led:1",  "white",  ["h-32"]],
    ["r_led:2",     "px1:DIN",  "white",  ["h-32"]],
    ["px1:DOUT",    "px2:DIN",  "white",  []],
    ["px2:DOUT",    "px3:DIN",  "white",  []],
    ["esp32:VIN",   "px1:VCC",  "red",    ["h-170", "v-80"]],
    ["px1:VCC",     "px2:VCC",  "red",    []],
    ["px2:VCC",     "px3:VCC",  "red",    []],
    ["esp32:GND.1", "px1:GND",  "black",  ["h-170", "v-60"]],
    ["px1:GND",     "px2:GND",  "black",  []],
    ["px2:GND",     "px3:GND",  "black",  []]
  ]
}
```

### Rear-Board — `wokwi/rear/diagram.json`

Drei HC-SR04-Sensoren sind über TRIG-Leitungen (GPIO 25/26/27) angeschlossen. Jede ECHO-Leitung durchläuft einen 1-kΩ + 2-kΩ-Spannungsteiler, bevor sie die input-only-Pins des ESP32 (GPIO 34/35/36) erreicht. Drei NeoPixel repräsentieren die LED-Streifen-Zonen.

```json
{
  "version": 1,
  "author": "AmbientNav",
  "editor": "wokwi",
  "parts": [
    {
      "type": "wokwi-esp32-devkit-v1",
      "id": "esp32",
      "top": 96,
      "left": 192,
      "attrs": {}
    },
    { "type": "wokwi-hc-sr04", "id": "us_l", "top": 32,  "left": -192, "attrs": {} },
    { "type": "wokwi-hc-sr04", "id": "us_c", "top": 224, "left": -192, "attrs": {} },
    { "type": "wokwi-hc-sr04", "id": "us_r", "top": 416, "left": -192, "attrs": {} },
    { "type": "wokwi-resistor", "id": "r_el1", "top": 62.72,  "left": 32, "rotate": 90, "attrs": { "value": "1000" } },
    { "type": "wokwi-resistor", "id": "r_el2", "top": 62.72,  "left": 80, "rotate": 90, "attrs": { "value": "2000" } },
    { "type": "wokwi-resistor", "id": "r_ec1", "top": 254.72, "left": 32, "rotate": 90, "attrs": { "value": "1000" } },
    { "type": "wokwi-resistor", "id": "r_ec2", "top": 254.72, "left": 80, "rotate": 90, "attrs": { "value": "2000" } },
    { "type": "wokwi-resistor", "id": "r_er1", "top": 446.72, "left": 32, "rotate": 90, "attrs": { "value": "1000" } },
    { "type": "wokwi-resistor", "id": "r_er2", "top": 446.72, "left": 80, "rotate": 90, "attrs": { "value": "2000" } },
    { "type": "wokwi-resistor", "id": "r_led", "top": 350.72, "left": 448, "rotate": 90, "attrs": { "value": "330" } },
    { "type": "wokwi-neopixel", "id": "px1", "top": 320, "left": 560, "attrs": {} },
    { "type": "wokwi-neopixel", "id": "px2", "top": 368, "left": 560, "attrs": {} },
    { "type": "wokwi-neopixel", "id": "px3", "top": 416, "left": 560, "attrs": {} }
  ],
  "connections": [
    ["esp32:3V3",    "us_l:VCC",  "red",    ["h-300"]],
    ["esp32:3V3",    "us_c:VCC",  "red",    ["h-300"]],
    ["esp32:3V3",    "us_r:VCC",  "red",    ["h-300"]],
    ["esp32:GND.1",  "us_l:GND",  "black",  ["h-270"]],
    ["esp32:GND.1",  "us_c:GND",  "black",  ["h-270"]],
    ["esp32:GND.1",  "us_r:GND",  "black",  ["h-270"]],
    ["esp32:D25",    "us_l:TRIG", "orange", ["h-30", "v-90", "h-370"]],
    ["esp32:D26",    "us_c:TRIG", "orange", ["h-30", "v-90", "h-370"]],
    ["esp32:D27",    "us_r:TRIG", "orange", ["h-30", "v-90", "h-370"]],
    ["us_l:ECHO",    "r_el1:1",   "green",  []],
    ["r_el1:2",      "esp32:D34", "green",  []],
    ["r_el1:2",      "r_el2:1",   "green",  []],
    ["r_el2:2",      "esp32:GND.1","black", []],
    ["us_c:ECHO",    "r_ec1:1",   "green",  []],
    ["r_ec1:2",      "esp32:D35", "green",  []],
    ["r_ec1:2",      "r_ec2:1",   "green",  []],
    ["r_ec2:2",      "esp32:GND.1","black", []],
    ["us_r:ECHO",    "r_er1:1",   "green",  []],
    ["r_er1:2",      "esp32:VP",  "green",  []],
    ["r_er1:2",      "r_er2:1",   "green",  []],
    ["r_er2:2",      "esp32:GND.1","black", []],
    ["esp32:D18",    "r_led:1",   "white",  []],
    ["r_led:2",      "px1:DIN",   "white",  []],
    ["px1:DOUT",     "px2:DIN",   "white",  []],
    ["px2:DOUT",     "px3:DIN",   "white",  []],
    ["esp32:VIN",    "px1:VCC",   "red",    []],
    ["px1:VCC",      "px2:VCC",   "red",    []],
    ["px2:VCC",      "px3:VCC",   "red",    []],
    ["esp32:GND.2",  "px1:GND",   "black",  []],
    ["px1:GND",      "px2:GND",   "black",  []],
    ["px2:GND",      "px3:GND",   "black",  []]
  ]
}
```
