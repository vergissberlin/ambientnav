#pragma once

#include <stdint.h>

static const uint16_t SENSOR_NO_OBSTACLE_CM = 999;

uint16_t sensorMedian3(uint16_t a, uint16_t b, uint16_t c);
uint16_t sensorApplyCalibration(
    uint16_t cm,
    int16_t calibOffsetCm,
    uint16_t maxRangeCm
);
bool sensorIsEnabled(uint8_t activeSensor, uint8_t sensor);
