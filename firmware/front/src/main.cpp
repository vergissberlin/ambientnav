#include <Arduino.h>
#include "config.h"
#include "ble_server.h"
#include "bt_classic.h"
#include "orchestrator.h"
#include "led_effects.h"
#include "battery.h"
#include "gatt_ext.h"

QueueHandle_t    navQueue;
QueueHandle_t    proxQueue;
QueueHandle_t    effectQueue;
SemaphoreHandle_t sppMutex;

// Shared runtime config, settable over BLE.
LedRuntimeConfig    g_ledConfig;
SensorRuntimeConfig g_sensorConfig;
SemaphoreHandle_t   configMutex;

// ── Telemetry: publish supply voltage ~1 Hz ───────────────────────────────────
static void taskTelemetry(void* param) {
    for (;;) {
        gattExtNotifyVoltage(batteryReadMillivolts());
        vTaskDelay(pdMS_TO_TICKS(BATTERY_NOTIFY_MS));
    }
}

void setup() {
    Serial.begin(115200);
    Serial.printf("\n[AmbientNav Front] firmware %s\n", FIRMWARE_VERSION);

    navQueue    = xQueueCreate(4, sizeof(NavState));
    proxQueue   = xQueueCreate(4, sizeof(SensorData));
    effectQueue = xQueueCreate(2, sizeof(EffectCommand));
    sppMutex    = xSemaphoreCreateMutex();
    configMutex = xSemaphoreCreateMutex();

    // Runtime config defaults (mirror compile-time strip settings).
    g_ledConfig    = {FRONT_LED_COUNT, FRONT_BRIGHTNESS, EFF_AMBIENT, {0, 0, 0, 0}};
    g_sensorConfig = {3 /*fused*/, 0, 400};

    batteryInit();

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
    xTaskCreatePinnedToCore(taskTelemetry,    "Telemetry",    3072, nullptr, 2, nullptr, 1);
}

void loop() {
    vTaskDelay(portMAX_DELAY);
}
