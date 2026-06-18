#include "bt_classic.h"
#include "config.h"
#include <BluetoothSerial.h>
#include <ArduinoJson.h>

static BluetoothSerial SerialBT;
static char            rxBuf[256];
static int             rxPos = 0;

void btClassicServerInit() {
    // No second argument = SPP server mode (slave, listens for incoming connections)
    SerialBT.begin(SPP_DEVICE_NAME);
    Serial.printf("[SPP] server started as \"%s\"\n", SPP_DEVICE_NAME);
}

bool sppSend(const char* json) {
    if (!SerialBT.connected()) return false;
    if (xSemaphoreTake(sppMutex, pdMS_TO_TICKS(20)) != pdTRUE) return false;
    SerialBT.println(json);
    xSemaphoreGive(sppMutex);
    return true;
}

void taskBTServer(void* param) {
    for (;;) {
        if (!SerialBT.connected()) {
            vTaskDelay(pdMS_TO_TICKS(100));
            continue;
        }

        while (SerialBT.available()) {
            char c = (char)SerialBT.read();
            if (c == '\n' || rxPos >= (int)sizeof(rxBuf) - 1) {
                rxBuf[rxPos] = '\0';
                rxPos = 0;

                StaticJsonDocument<128> doc;
                if (deserializeJson(doc, rxBuf) == DeserializationError::Ok) {
                    const char* cmd = doc["cmd"] | "";
                    if (strcmp(cmd, "reverse") == 0) {
                        bool active = doc["active"] | false;
                        xQueueOverwrite(cmdQueue, &active);

                        // Acknowledge
                        sppSend("{\"type\":\"ack\",\"cmd\":\"reverse\"}");
                        Serial.printf("[SPP] reverse %s\n", active ? "ON" : "OFF");
                    } else if (strcmp(cmd, "sensorcfg") == 0) {
                        // Sensor config forwarded from the phone via the front board.
                        if (xSemaphoreTake(configMutex, pdMS_TO_TICKS(20)) == pdTRUE) {
                            g_sensorConfig.active_sensor =
                                (uint8_t)(doc["sensor"] | SENSOR_FUSED);
                            g_sensorConfig.calib_offset_cm =
                                (int16_t)(doc["calib_cm"] | 0);
                            g_sensorConfig.max_range_cm =
                                (uint16_t)(doc["max_range_cm"] | 400);
                            xSemaphoreGive(configMutex);
                        }
                        sensorConfigSave();
                        sppSend("{\"type\":\"ack\",\"cmd\":\"sensorcfg\"}");
                        Serial.println("[SPP] sensor config updated + saved");
                    } else if (strcmp(cmd, "getcfg") == 0) {
                        char out[128];
                        if (xSemaphoreTake(configMutex, pdMS_TO_TICKS(20)) == pdTRUE) {
                            snprintf(out, sizeof(out),
                                     "{\"type\":\"sensorcfg\",\"sensor\":%u,"
                                     "\"calib_cm\":%d,\"max_range_cm\":%u}",
                                     g_sensorConfig.active_sensor,
                                     g_sensorConfig.calib_offset_cm,
                                     g_sensorConfig.max_range_cm);
                            xSemaphoreGive(configMutex);
                            sppSend(out);
                        }
                    }
                }
            } else {
                rxBuf[rxPos++] = c;
            }
        }

        vTaskDelay(pdMS_TO_TICKS(5));
    }
}
