#pragma once
#include <stdint.h>

class NimBLEServer;

// Registers the extended AmbientNav GATT services (telemetry, LED config,
// sensor config, OTA) on an already-created NimBLE server. Config/OTA
// characteristics require an encrypted, authenticated (bonded) link.
void gattExtInit(NimBLEServer* server);

// Push the latest supply voltage (millivolts) to subscribed centrals.
void gattExtNotifyVoltage(uint16_t millivolts);
