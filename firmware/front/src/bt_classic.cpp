#include "bt_classic.h"
#include "config.h"
#include <BluetoothSerial.h>
#include <ArduinoJson.h>

static BluetoothSerial SerialBT;
static char            rxBuf[256];
static int             rxPos = 0;

void btClassicInit() {
    // true = initiate (master/client) mode
    SerialBT.begin("AmbientNav-Front", true);
    Serial.println("[SPP] client initialised, will connect to " SPP_PEER_NAME);
}

bool sppSend(const char* json) {
    if (!SerialBT.connected()) return false;
    if (xSemaphoreTake(sppMutex, pdMS_TO_TICKS(20)) != pdTRUE) return false;
    SerialBT.println(json);
    xSemaphoreGive(sppMutex);
    return true;
}

void taskBTClient(void* param) {
    uint32_t lastConnectAttempt = 0;

    for (;;) {
        if (!SerialBT.connected()) {
            uint32_t now = millis();
            if (now - lastConnectAttempt >= SPP_RECONNECT_MS) {
                lastConnectAttempt = now;
                Serial.println("[SPP] connecting to " SPP_PEER_NAME " ...");
                if (SerialBT.connect(SPP_PEER_NAME)) {
                    Serial.println("[SPP] connected");
                } else {
                    Serial.println("[SPP] connect failed, retry in 5 s");
                }
            }
            vTaskDelay(pdMS_TO_TICKS(100));
            continue;
        }

        // Read available bytes, accumulate until newline
        while (SerialBT.available()) {
            char c = (char)SerialBT.read();
            if (c == '\n' || rxPos >= (int)sizeof(rxBuf) - 1) {
                rxBuf[rxPos] = '\0';
                rxPos = 0;

                StaticJsonDocument<256> doc;
                if (deserializeJson(doc, rxBuf) == DeserializationError::Ok) {
                    const char* type = doc["type"] | "";
                    if (strcmp(type, "sensors") == 0) {
                        SensorData d;
                        d.left_cm      = doc["left"]   | 999;
                        d.center_cm    = doc["center"] | 999;
                        d.right_cm     = doc["right"]  | 999;
                        d.timestamp_ms = millis();
                        xQueueOverwrite(proxQueue, &d);
                    }
                }
            } else {
                rxBuf[rxPos++] = c;
            }
        }

        vTaskDelay(pdMS_TO_TICKS(5));
    }
}
