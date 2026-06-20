---
title: Pinouts & Wiring
description: GPIO pin assignments and wiring guide for the AmbientNav ESP32 boards.
---

This page shows exactly which wire goes where on each ESP32 board. Follow the tables below and you will have both boards correctly wired.

---

## ESP32 Front Board (Master)

The front board connects to the iPhone via Bluetooth LE and drives the front LED strip.

| Function | GPIO | Wire colour |
|---|---|---|
| LED strip data | **5** | White |
| Reverse-signal input *(optional)* | **4** | Yellow |
| 5 V power | **VIN** | Red |
| Ground | **GND** | Black |

### 30-pin ESP32 DevKit — Front board pinout

```
                    ┌──────────────────┐
              EN ──┤ EN           D23 ├── (free)
       (free) D36 ──┤ VP           D22 ├── (free)
       (free) D39 ──┤ VN           TX0 ├── Serial TX (debug)
       (free) D34 ──┤ D34          RX0 ├── Serial RX (debug)
       (free) D35 ──┤ D35          D21 ├── (free)
       (free) D32 ──┤ D32          D19 ├── (free)
       (free) D33 ──┤ D33          D18 ├── (free)
       (free) D25 ──┤ D25           D5 ├──── LED data  ◄ WHITE
       (free) D26 ──┤ D26          TX2 ├── (free)
       (free) D27 ──┤ D27          RX2 ├── (free)
  Rev. signal D14 ──┤ D14          D4  ├──── Rev. signal ◄ YELLOW  (opt.)
       (free) D12 ──┤ D12          D2  ├── (free)
       (free) D13 ──┤ D13          D15 ├── (free)
         GND GND ──┤ GND          GND ├──── Ground ◄ BLACK
         +5V VIN ──┤ VIN          3V3 ├── (3.3 V out — do not use for LED power)
                    └──────────────────┘
```

### Front LED strip connection

Connect the **330 Ω resistor** in series on the data line, close to the ESP32.  
Connect the **1000 µF capacitor** between 5 V and GND at the LED strip input.

```
  ESP32 GPIO 5 ──[330 Ω]──── LED Din
  5 V supply ──┬──────────── LED 5V
               └──[1000 µF]─ LED GND
  GND ─────────────────────── LED GND
```

---

## ESP32 Rear Board (Slave)

The rear board listens for commands from the front board via Bluetooth Classic and drives the rear LED strip and three HC-SR04 ultrasonic sensors.

| Function | GPIO | Wire colour |
|---|---|---|
| LED strip data | **18** | White |
| HC-SR04 Left — TRIG | **25** | Orange |
| HC-SR04 Left — ECHO | **34** | Green |
| HC-SR04 Center — TRIG | **26** | Orange |
| HC-SR04 Center — ECHO | **35** | Green |
| HC-SR04 Right — TRIG | **27** | Orange |
| HC-SR04 Right — ECHO | **36** | Green |
| 5 V power | **VIN** | Red |
| Ground | **GND** | Black |

### 30-pin ESP32 DevKit — Rear board pinout

```
                    ┌──────────────────┐
              EN ──┤ EN           D23 ├── (free)
Echo L    D36/VP ──┤ VP           D22 ├── (free)
Echo C    D39/VN ──┤ VN           TX0 ├── Serial TX (debug)
Echo R      D34 ──┤ D34          RX0 ├── Serial RX (debug)
            D35 ──┤ D35          D21 ├── (free)
            D32 ──┤ D32          D19 ├── (free)
            D33 ──┤ D33          D18 ├──── LED data  ◄ WHITE
  Trig L    D25 ──┤ D25           D5 ├── (free)
  Trig C    D26 ──┤ D26          TX2 ├── (free)
  Trig R    D27 ──┤ D27          RX2 ├── (free)
            D14 ──┤ D14           D4 ├── (free)
            D12 ──┤ D12           D2 ├── (free)
            D13 ──┤ D13          D15 ├── (free)
        GND GND ──┤ GND          GND ├──── Ground ◄ BLACK
        +5V VIN ──┤ VIN          3V3 ├── 3.3 V for HC-SR04 VCC
                    └──────────────────┘
```

### HC-SR04 wiring (per sensor)

:::caution[Voltage warning]
HC-SR04 ECHO output is 5 V. The ESP32 GPIO is only 3.3 V tolerant.  
Use a voltage divider (1 kΩ + 2 kΩ) or a logic-level shifter on each ECHO line.
:::

```
  HC-SR04 VCC  ──── 3.3 V (ESP32 3V3 pin)
  HC-SR04 GND  ──── GND
  HC-SR04 TRIG ──── ESP32 TRIG pin (direct, 3.3 V signal is sufficient)
  HC-SR04 ECHO ──[1 kΩ]──┬──── ESP32 ECHO pin
                          └──[2 kΩ]──── GND
```

Repeat for all three sensors (Left, Center, Right) using the GPIO pairs in the table above.

---

## Power supply

The LEDs dominate the power budget. Use a dedicated **5 V / 3 A** DC-DC converter for each board. Do not power the LED strips from the ESP32 VIN pin on a USB connection.

| Component | Current (typical) |
|---|---|
| ESP32 (active, Bluetooth on) | ~240 mA |
| WS2812B, 60 LEDs @ 50 % white | ~900 mA |
| 3× HC-SR04 (rear only) | ~45 mA |
| **Total per board** | **~1.2 – 1.4 A** |

Keep power and signal GND connected together at a single point (star topology) to prevent ground loops.

---

## WokWi Simulator

[WokWi](https://wokwi.com) is a free browser-based electronics simulator that supports the ESP32, WS2812B NeoPixels, and HC-SR04 sensors used in this project. Use the diagrams below to simulate the circuits without physical hardware.

**How to open a diagram in WokWi:**
1. Go to [wokwi.com](https://wokwi.com) and create a new ESP32 project.
2. Click the `diagram.json` tab and replace its contents with the JSON below.
3. Press **Start Simulation**.

The `diagram.json` files are also stored in the repository under `wokwi/front/` and `wokwi/rear/`.

### Front board — `wokwi/front/diagram.json`

Three NeoPixels represent a segment of the WS2812B LED strip. GPIO 5 drives the data line through a 330 Ω resistor.

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

### Rear board — `wokwi/rear/diagram.json`

Three HC-SR04 sensors connect via TRIG lines (GPIO 25/26/27). Each ECHO line passes through a 1 kΩ + 2 kΩ voltage divider before reaching the ESP32 input-only pins (GPIO 34/35/36). Three NeoPixels represent the LED strip zones.

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
