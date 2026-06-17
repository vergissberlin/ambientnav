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
