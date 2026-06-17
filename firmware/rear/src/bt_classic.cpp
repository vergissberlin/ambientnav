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
                    }
                }
            } else {
                rxBuf[rxPos++] = c;
            }
        }

        vTaskDelay(pdMS_TO_TICKS(5));
    }
}
