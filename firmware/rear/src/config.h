#pragma once
#include <Arduino.h>

#define FIRMWARE_VERSION "0.1.0"

// ── Bluetooth Classic SPP ─────────────────────────────────────────────────────
#define SPP_DEVICE_NAME  "AmbientNav-Rear"

// ── Rear LED strip ────────────────────────────────────────────────────────────
#define REAR_LED_PIN     18
#define REAR_LED_COUNT   60
#define ZONE_LED_COUNT   20   // 60 LEDs / 3 zones
#define REAR_BRIGHTNESS  128

// ── HC-SR04 GPIO assignments ──────────────────────────────────────────────────
// ECHO pins 34/35/36 are input-only on ESP32, ideal for pulse capture.
#define TRIG_L  25
#define ECHO_L  34
#define TRIG_C  26
#define ECHO_C  35
#define TRIG_R  27
#define ECHO_R  36

// ── Ultrasonic timing ─────────────────────────────────────────────────────────
// 25 ms timeout ≈ 430 cm round-trip; beyond range → report 999
#define SENSOR_TIMEOUT_US 25000
#define SENSOR_MEDIAN_N   3
#define SENSOR_GAP_MS     30   // gap between sensors to avoid cross-talk
#define SENSOR_RATE_MS    100  // 10 Hz transmit rate

// ── Shared data structures ────────────────────────────────────────────────────
struct SensorData {
    uint16_t left_cm;
    uint16_t center_cm;
    uint16_t right_cm;
};

// Runtime sensor configuration, set from the phone app (forwarded by the front
// controller over SPP) and persisted to NVS.
enum ActiveSensor : uint8_t {
    SENSOR_LEFT   = 0,
    SENSOR_CENTER = 1,
    SENSOR_RIGHT  = 2,
    SENSOR_FUSED  = 3
};

struct SensorRuntimeConfig {
    uint8_t  active_sensor;     // ActiveSensor
    int16_t  calib_offset_cm;   // signed offset applied to raw readings
    uint16_t max_range_cm;      // beyond this → 999 (no obstacle)
};

// ── FreeRTOS handles (defined in main.cpp) ────────────────────────────────────
extern QueueHandle_t   cmdQueue;    // bool reverseActive, depth 4
extern QueueHandle_t   sensorQueue; // SensorData, depth 4
extern SemaphoreHandle_t sppMutex;

// Shared sensor config (guarded by configMutex; defined in main.cpp)
extern SensorRuntimeConfig g_sensorConfig;
extern SemaphoreHandle_t   configMutex;

// Persistence (defined in sensor_store.cpp)
void sensorConfigLoad();
void sensorConfigSave();
