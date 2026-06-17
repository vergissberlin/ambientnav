---
title: Wiring
description: Pin assignments and wiring diagrams for the ESP32 front and rear boards.
---

## Front ESP32 (Master)

The front board handles BLE communication with the iPhone and drives the front LED strip.

```mermaid
graph LR
    iPhone["📱 iPhone"]
    PSU["🔌 5V / 3A\nStep-Down"]

    subgraph FRONT["ESP32 Front (Master)"]
        BLE["BLE Stack\n(internal)"]
        BTC["BT Classic\n(internal)"]
        G5F["GPIO 5\nLED Data"]
        VIN_F["VIN + GND"]
    end

    R330F["330 Ω"]
    LED_F["💡 WS2812B\nFront Strip"]
    ESP32R["ESP32 Rear\n(Slave)"]

    iPhone <-->|Bluetooth LE| BLE
    BTC <-->|BT Classic SPP| ESP32R
    PSU -->|5V| VIN_F
    G5F --> R330F --> LED_F
    PSU -->|5V + GND| LED_F
```

### Pin Table — Front

| Pin       | Direction | Connected to               |
|-----------|-----------|----------------------------|
| GPIO 5    | OUT       | WS2812B DIN (via 330 Ω)    |
| VIN       | IN        | 5 V step-down output       |
| GND       | —         | Common ground              |
| Internal  | BLE       | iPhone (CoreBluetooth)     |
| Internal  | BT Classic| ESP32 Rear (SPP)           |

:::note
Avoid GPIO 0, 2, and 15 for general I/O — these are strapping pins that influence the ESP32 boot mode.
:::

---

## Rear ESP32 (Slave)

The rear board reads three HC-SR04 distance sensors and drives the rear LED strip.

```mermaid
graph LR
    ESP32F["ESP32 Front\n(Master)"]
    PSU["🔌 5V / 3A\nStep-Down"]

    subgraph REAR["ESP32 Rear (Slave)"]
        BTC_R["BT Classic\n(internal)"]
        G5R["GPIO 5\nLED Data"]
        VIN_R["VIN + GND"]
        T1["GPIO 12 TRIG"]
        E1["GPIO 13 ECHO"]
        T2["GPIO 14 TRIG"]
        E2["GPIO 27 ECHO"]
        T3["GPIO 26 TRIG"]
        E3["GPIO 25 ECHO"]
    end

    R330R["330 Ω"]
    LED_R["💡 WS2812B\nRear Strip"]
    USL["HC-SR04\nLeft"]
    USC["HC-SR04\nCenter"]
    USR["HC-SR04\nRight"]

    ESP32F <-->|BT Classic SPP| BTC_R
    PSU -->|5V| VIN_R
    G5R --> R330R --> LED_R
    PSU -->|5V + GND| LED_R

    T1 -->|TRIG| USL
    USL -->|ECHO| E1
    T2 -->|TRIG| USC
    USC -->|ECHO| E2
    T3 -->|TRIG| USR
    USR -->|ECHO| E3
```

### Pin Table — Rear

| Pin       | Direction | Connected to                  |
|-----------|-----------|-------------------------------|
| GPIO 5    | OUT       | WS2812B DIN (via 330 Ω)       |
| GPIO 12   | OUT       | HC-SR04 Left — TRIG           |
| GPIO 13   | IN        | HC-SR04 Left — ECHO           |
| GPIO 14   | OUT       | HC-SR04 Center — TRIG         |
| GPIO 27   | IN        | HC-SR04 Center — ECHO         |
| GPIO 26   | OUT       | HC-SR04 Right — TRIG          |
| GPIO 25   | IN        | HC-SR04 Right — ECHO          |
| VIN       | IN        | 5 V step-down output          |
| GND       | —         | Common ground                 |
| Internal  | BT Classic| ESP32 Front (SPP)             |

---

## Power Distribution

```mermaid
graph TD
    CAR["🚗 12V Car Line"]
    FUSE["Fuse 3A"]
    SD["Step-Down\n12V → 5V / 3A"]
    ESP_F["ESP32 Front VIN"]
    ESP_R["ESP32 Rear VIN"]
    LED_F2["WS2812B Front\n5V + GND"]
    LED_R2["WS2812B Rear\n5V + GND"]
    CAP_F["1000 µF Cap"]
    CAP_R["1000 µF Cap"]

    CAR --> FUSE --> SD
    SD -->|5V| ESP_F
    SD -->|5V| ESP_R
    SD -->|5V| CAP_F --> LED_F2
    SD -->|5V| CAP_R --> LED_R2
```

Place a **1000 µF / 6.3 V capacitor** across 5 V and GND directly at each LED strip connector to absorb inrush current during brightness transitions.
