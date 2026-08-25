#include "sensor_math.h"

uint16_t sensorMedian3(uint16_t a, uint16_t b, uint16_t c) {
    if (a > b) { uint16_t t = a; a = b; b = t; }
    if (b > c) { uint16_t t = b; b = c; c = t; }
    if (a > b) { uint16_t t = a; a = b; b = t; }
    return b;
}

uint16_t sensorApplyCalibration(
    uint16_t cm,
    int16_t calibOffsetCm,
    uint16_t maxRangeCm
) {
    if (cm == SENSOR_NO_OBSTACLE_CM) return SENSOR_NO_OBSTACLE_CM;

    int32_t value = (int32_t)cm + calibOffsetCm;
    if (value < 0) value = 0;
    if (value > maxRangeCm) return SENSOR_NO_OBSTACLE_CM;
    return (uint16_t)value;
}

bool sensorIsEnabled(uint8_t activeSensor, uint8_t sensor) {
    return activeSensor == 3 || activeSensor == sensor;
}
