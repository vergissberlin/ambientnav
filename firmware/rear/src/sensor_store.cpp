#include "config.h"
#include <Preferences.h>

// Persists the runtime sensor configuration in NVS so calibration survives
// reboots and battery swaps.
static Preferences prefs;
static const char* NS = "ambientnav";

void sensorConfigLoad() {
    prefs.begin(NS, true /*read-only*/);
    if (xSemaphoreTake(configMutex, portMAX_DELAY) == pdTRUE) {
        g_sensorConfig.active_sensor   = prefs.getUChar("sensor", SENSOR_FUSED);
        g_sensorConfig.calib_offset_cm = prefs.getShort("calib", 0);
        g_sensorConfig.max_range_cm    = prefs.getUShort("range", 400);
        xSemaphoreGive(configMutex);
    }
    prefs.end();
}

void sensorConfigSave() {
    prefs.begin(NS, false /*read-write*/);
    if (xSemaphoreTake(configMutex, portMAX_DELAY) == pdTRUE) {
        prefs.putUChar("sensor", g_sensorConfig.active_sensor);
        prefs.putShort("calib", g_sensorConfig.calib_offset_cm);
        prefs.putUShort("range", g_sensorConfig.max_range_cm);
        xSemaphoreGive(configMutex);
    }
    prefs.end();
}
