#include "battery.h"
#include "config.h"
#include <Arduino.h>

void batteryInit() {
    analogReadResolution(12);          // 0–4095
    analogSetPinAttenuation(BATTERY_SENSE_PIN, ADC_11db);  // full 0–3.3 V range
}

uint16_t batteryReadMillivolts() {
    // Average a few samples to reduce ADC noise.
    uint32_t acc = 0;
    const int n = 8;
    for (int i = 0; i < n; i++) {
        acc += analogReadMilliVolts(BATTERY_SENSE_PIN);
    }
    float pin_mv = (float)acc / n;
    float supply_mv = pin_mv * BATTERY_DIVIDER;
    if (supply_mv < 0) supply_mv = 0;
    if (supply_mv > 65535.0f) supply_mv = 65535.0f;
    return (uint16_t)supply_mv;
}
