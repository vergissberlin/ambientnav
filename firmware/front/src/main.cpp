#include <Arduino.h>
#include "config.h"
#include "ble_server.h"
#include "bt_classic.h"
#include "orchestrator.h"
#include "led_effects.h"

QueueHandle_t    navQueue;
QueueHandle_t    proxQueue;
QueueHandle_t    effectQueue;
SemaphoreHandle_t sppMutex;

void setup() {
    Serial.begin(115200);
    Serial.printf("\n[AmbientNav Front] firmware %s\n", FIRMWARE_VERSION);

    navQueue    = xQueueCreate(4, sizeof(NavState));
    proxQueue   = xQueueCreate(4, sizeof(SensorData));
    effectQueue = xQueueCreate(2, sizeof(EffectCommand));
    sppMutex    = xSemaphoreCreateMutex();

    // BluetoothSerial must start before NimBLE (shared controller)
    btClassicInit();
    bleServerInit();
    ledFrontInit();
    orchestratorInit();

    // BT tasks → PRO_CPU (core 0), together with NimBLE/Bluedroid internals
    xTaskCreatePinnedToCore(taskBTClient,    "BTClient",    4096, nullptr, 4, nullptr, 0);

    // Logic + render tasks → APP_CPU (core 1)
    xTaskCreatePinnedToCore(taskOrchestrator, "Orchestrator", 4096, nullptr, 5, nullptr, 1);
    xTaskCreatePinnedToCore(taskLEDFront,     "LEDFront",     2048, nullptr, 3, nullptr, 1);
}

void loop() {
    vTaskDelay(portMAX_DELAY);
}
