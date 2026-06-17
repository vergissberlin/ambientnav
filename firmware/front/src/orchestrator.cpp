#include "orchestrator.h"
#include "config.h"
#include "bt_classic.h"

static NavState    currentNav     = {};
static SensorData  currentSensors = { 999, 999, 999, 0 };
static bool        reverseActive  = false;
static EffectType  lastEffect     = EFF_AMBIENT;

static EffectType chooseEffect() {
    bool navFresh    = (millis() - currentNav.timestamp_ms) < BLE_FADE_TIMEOUT_MS
                       && currentNav.timestamp_ms > 0;
    bool activeMnvr  = navFresh
                       && currentNav.direction != DIR_NONE
                       && currentNav.distance_m < 200;
    bool blinkerOn   = navFresh && currentNav.blinker != BLINKER_OFF;

    if (reverseActive)           return EFF_AMBIENT;        // rear handles parking aid
    if (activeMnvr) {
        if (currentNav.direction == DIR_LEFT)     return EFF_NAV_LEFT;
        if (currentNav.direction == DIR_RIGHT)    return EFF_NAV_RIGHT;
        return EFF_NAV_STRAIGHT;
    }
    if (navFresh) {
        if (currentNav.blinker == BLINKER_HAZARD) return EFF_HAZARD;
        if (currentNav.blinker == BLINKER_LEFT)   return EFF_BLINKER_LEFT;
        if (currentNav.blinker == BLINKER_RIGHT)  return EFF_BLINKER_RIGHT;
    }
    return EFF_AMBIENT;
}

void orchestratorInit() {
    pinMode(REVERSE_SIGNAL_PIN, INPUT);
}

void taskOrchestrator(void* param) {
    TickType_t lastWake = xTaskGetTickCount();
    char       sppBuf[64];
    bool       prevReverse = false;

    for (;;) {
        // Drain nav queue
        NavState newNav;
        while (xQueueReceive(navQueue, &newNav, 0) == pdTRUE) {
            currentNav = newNav;
        }

        // Drain sensor queue
        SensorData newSensors;
        while (xQueueReceive(proxQueue, &newSensors, 0) == pdTRUE) {
            currentSensors = newSensors;
        }

        // Sensor staleness guard
        if (millis() - currentSensors.timestamp_ms > SENSOR_STALE_MS) {
            currentSensors.left_cm   = 999;
            currentSensors.center_cm = 999;
            currentSensors.right_cm  = 999;
        }

        // Reverse detection: hardware GPIO OR future BLE extension
        reverseActive = (digitalRead(REVERSE_SIGNAL_PIN) == HIGH);

        // Notify rear board when reverse state changes
        if (reverseActive != prevReverse) {
            snprintf(sppBuf, sizeof(sppBuf),
                     "{\"cmd\":\"reverse\",\"active\":%s}",
                     reverseActive ? "true" : "false");
            sppSend(sppBuf);
            prevReverse = reverseActive;
        }

        // Evaluate and dispatch effect
        EffectType effect = chooseEffect();
        if (effect != lastEffect) {
            EffectCommand cmd = { effect, CRGB::White, 255 };
            xQueueOverwrite(effectQueue, &cmd);
            lastEffect = effect;
        }

        vTaskDelayUntil(&lastWake, pdMS_TO_TICKS(ORCH_TICK_MS));
    }
}
