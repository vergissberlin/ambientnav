#include <Arduino.h>
#include "config.h"
#include "bt_classic.h"
#include "ultrasonic.h"
#include "led_effects.h"

QueueHandle_t    cmdQueue;
QueueHandle_t    sensorQueue;
SemaphoreHandle_t sppMutex;

SensorRuntimeConfig g_sensorConfig;
SemaphoreHandle_t   configMutex;

void setup() {
    Serial.begin(115200);
    Serial.printf("\n[AmbientNav Rear] firmware %s\n", FIRMWARE_VERSION);

    cmdQueue    = xQueueCreate(4, sizeof(bool));
    sensorQueue = xQueueCreate(4, sizeof(SensorData));
    sppMutex    = xSemaphoreCreateMutex();
    configMutex = xSemaphoreCreateMutex();

    g_sensorConfig = {SENSOR_FUSED, 0, 400};
    sensorConfigLoad();

    ultrasonicInit();
    btClassicServerInit();
    ledRearInit();

    // SPP server task → PRO_CPU (core 0)
    xTaskCreatePinnedToCore(taskBTServer,   "BTServer",   4096, nullptr, 4, nullptr, 0);

    // Sensor + render tasks → APP_CPU (core 1)
    xTaskCreatePinnedToCore(taskUltrasonic, "Ultrasonic", 2048, nullptr, 4, nullptr, 1);
    xTaskCreatePinnedToCore(taskLEDRear,    "LEDRear",    2048, nullptr, 3, nullptr, 1);
}

void loop() {
    vTaskDelay(portMAX_DELAY);
}
