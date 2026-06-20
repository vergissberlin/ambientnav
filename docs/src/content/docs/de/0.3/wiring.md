---
title: Verkabelung
description: Pin-Belegung und Verdrahtungsdiagramme für den vorderen und hinteren ESP32.
slug: de/0.1/wiring
---

## Vorderer ESP32 (Master)

Das vordere Board übernimmt die BLE-Kommunikation mit dem iPhone und steuert den vorderen LED-Streifen.

```mermaid
graph LR
    iPhone["📱 iPhone"]
    PSU["🔌 5V / 3A\nStep-Down"]

    subgraph FRONT["ESP32 Vorne (Master)"]
        BLE["BLE Stack\n(intern)"]
        BTC["BT Classic\n(intern)"]
        G5F["GPIO 5\nLED Data"]
        VIN_F["VIN + GND"]
    end

    R330F["330 Ω"]
    LED_F["💡 WS2812B\nVorderer Streifen"]
    ESP32R["ESP32 Hinten\n(Slave)"]

    iPhone <-->|Bluetooth LE| BLE
    BTC <-->|BT Classic SPP| ESP32R
    PSU -->|5V| VIN_F
    G5F --> R330F --> LED_F
    PSU -->|5V + GND| LED_F
```

### Pin-Tabelle — Vorne

| Pin       | Richtung | Verbunden mit                   |
|-----------|----------|---------------------------------|
| GPIO 5    | OUT      | WS2812B DIN (über 330 Ω)        |
| VIN       | IN       | 5V Step-Down Ausgang            |
| GND       | —        | Gemeinsame Masse                |
| Intern    | BLE      | iPhone (CoreBluetooth)          |
| Intern    | BT Classic| ESP32 Hinten (SPP)             |

:::note
GPIO 0, 2 und 15 nicht für allgemeine I/O verwenden — diese Strapping-Pins beeinflussen den Boot-Modus des ESP32.
:::

***

## Hinterer ESP32 (Slave)

Das hintere Board liest drei HC-SR04-Distanzsensoren aus und steuert den hinteren LED-Streifen.

```mermaid
graph LR
    ESP32F["ESP32 Vorne\n(Master)"]
    PSU["🔌 5V / 3A\nStep-Down"]

    subgraph REAR["ESP32 Hinten (Slave)"]
        BTC_R["BT Classic\n(intern)"]
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
    LED_R["💡 WS2812B\nHinterer Streifen"]
    USL["HC-SR04\nLinks"]
    USC["HC-SR04\nMitte"]
    USR["HC-SR04\nRechts"]

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

### Pin-Tabelle — Hinten

| Pin       | Richtung | Verbunden mit                    |
|-----------|----------|----------------------------------|
| GPIO 5    | OUT      | WS2812B DIN (über 330 Ω)         |
| GPIO 12   | OUT      | HC-SR04 Links — TRIG             |
| GPIO 13   | IN       | HC-SR04 Links — ECHO             |
| GPIO 14   | OUT      | HC-SR04 Mitte — TRIG             |
| GPIO 27   | IN       | HC-SR04 Mitte — ECHO             |
| GPIO 26   | OUT      | HC-SR04 Rechts — TRIG            |
| GPIO 25   | IN       | HC-SR04 Rechts — ECHO            |
| VIN       | IN       | 5V Step-Down Ausgang             |
| GND       | —        | Gemeinsame Masse                 |
| Intern    | BT Classic| ESP32 Vorne (SPP)               |

***

## Stromversorgung

```mermaid
graph TD
    CAR["🚗 12V Bordnetz"]
    FUSE["Sicherung 3A"]
    SD["Step-Down\n12V → 5V / 3A"]
    ESP_F["ESP32 Vorne VIN"]
    ESP_R["ESP32 Hinten VIN"]
    LED_F2["WS2812B Vorne\n5V + GND"]
    LED_R2["WS2812B Hinten\n5V + GND"]
    CAP_F["1000 µF Kondensator"]
    CAP_R["1000 µF Kondensator"]

    CAR --> FUSE --> SD
    SD -->|5V| ESP_F
    SD -->|5V| ESP_R
    SD -->|5V| CAP_F --> LED_F2
    SD -->|5V| CAP_R --> LED_R2
```

Einen **1000 µF / 6,3 V Kondensator** direkt am Steckverbinder jedes LED-Streifens zwischen 5V und GND platzieren, um Einschaltstromspitzen bei Helligkeitswechseln zu dämpfen.
