#pragma once
#include <stdint.h>

void batteryInit();

// Supply/battery voltage in millivolts, read from BATTERY_SENSE_PIN through the
// external divider. Returns a smoothed value.
uint16_t batteryReadMillivolts();
