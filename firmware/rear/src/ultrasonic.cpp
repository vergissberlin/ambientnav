#include "ultrasonic.h"
#include "config.h"
#include "bt_classic.h"

static uint16_t measureOne(uint8_t trigPin, uint8_t echoPin) {
    digitalWrite(trigPin, LOW);
    delayMicroseconds(2);
    digitalWrite(trigPin, HIGH);
    delayMicroseconds(10);
    digitalWrite(trigPin, LOW);

    uint32_t duration = pulseIn(echoPin, HIGH, SENSOR_TIMEOUT_US);
    if (duration == 0) return 999;

    uint16_t cm = (uint16_t)(duration * 0.034f / 2.0f);
    return (cm > 400) ? 999 : cm;
}

static uint16_t median3(uint16_t a, uint16_t b, uint16_t c) {
    if (a > b) { uint16_t t = a; a = b; b = t; }
    if (b > c) { uint16_t t = b; b = c; c = t; }
    if (a > b) { uint16_t t = a; a = b; b = t; }
    return b;
}

// Apply calibration offset and the configured max range to a reading (cm).
// 999 means "no obstacle" and is left untouched.
static void applyConfig(uint16_t& cm, const SensorRuntimeConfig& cfg) {
    if (cm == 999) return;
    int32_t v = (int32_t)cm + cfg.calib_offset_cm;
    if (v < 0) v = 0;
    if (v > cfg.max_range_cm) { cm = 999; return; }
    cm = (uint16_t)v;
}

void ultrasonicInit() {
    pinMode(TRIG_L, OUTPUT); pinMode(ECHO_L, INPUT);
    pinMode(TRIG_C, OUTPUT); pinMode(ECHO_C, INPUT);
    pinMode(TRIG_R, OUTPUT); pinMode(ECHO_R, INPUT);
    digitalWrite(TRIG_L, LOW);
    digitalWrite(TRIG_C, LOW);
    digitalWrite(TRIG_R, LOW);
}

void taskUltrasonic(void* param) {
    bool     reverseActive  = false;
    uint32_t lastSendMs     = 0;
    char     sppBuf[80];

    for (;;) {
        bool newActive;
        while (xQueueReceive(cmdQueue, &newActive, 0) == pdTRUE) {
            reverseActive = newActive;
        }

        if (!reverseActive) {
            vTaskDelay(pdMS_TO_TICKS(50));
            continue;
        }

        // Measure each sensor with inter-sensor gap to prevent cross-talk
        uint16_t rawL[3], rawC[3], rawR[3];
        for (int i = 0; i < SENSOR_MEDIAN_N; i++) {
            rawL[i] = measureOne(TRIG_L, ECHO_L);
            vTaskDelay(pdMS_TO_TICKS(SENSOR_GAP_MS));
            rawC[i] = measureOne(TRIG_C, ECHO_C);
            vTaskDelay(pdMS_TO_TICKS(SENSOR_GAP_MS));
            rawR[i] = measureOne(TRIG_R, ECHO_R);
            vTaskDelay(pdMS_TO_TICKS(SENSOR_GAP_MS));
        }

        SensorData data;
        data.left_cm   = median3(rawL[0], rawL[1], rawL[2]);
        data.center_cm = median3(rawC[0], rawC[1], rawC[2]);
        data.right_cm  = median3(rawR[0], rawR[1], rawR[2]);

        // Apply runtime calibration / range / active-sensor selection.
        SensorRuntimeConfig cfg;
        if (xSemaphoreTake(configMutex, pdMS_TO_TICKS(5)) == pdTRUE) {
            cfg = g_sensorConfig;
            xSemaphoreGive(configMutex);
        } else {
            cfg = {SENSOR_FUSED, 0, 400};
        }
        applyConfig(data.left_cm, cfg);
        applyConfig(data.center_cm, cfg);
        applyConfig(data.right_cm, cfg);
        if (cfg.active_sensor != SENSOR_FUSED) {
            if (cfg.active_sensor != SENSOR_LEFT)   data.left_cm   = 999;
            if (cfg.active_sensor != SENSOR_CENTER) data.center_cm = 999;
            if (cfg.active_sensor != SENSOR_RIGHT)  data.right_cm  = 999;
        }

        xQueueOverwrite(sensorQueue, &data);

        // Transmit at 10 Hz
        if (millis() - lastSendMs >= SENSOR_RATE_MS) {
            lastSendMs = millis();
            snprintf(sppBuf, sizeof(sppBuf),
                     "{\"type\":\"sensors\",\"left\":%u,\"center\":%u,\"right\":%u}",
                     data.left_cm, data.center_cm, data.right_cm);
            sppSend(sppBuf);
        }
    }
}
