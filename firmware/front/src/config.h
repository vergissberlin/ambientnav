#pragma once
#include <Arduino.h>
#include <FastLED.h>

#define FIRMWARE_VERSION "0.1.0"

// ── BLE ──────────────────────────────────────────────────────────────────────
#define BLE_DEVICE_NAME  "AmbientNav-Front"
#define BLE_SERVICE_UUID "12345678-1234-5678-1234-56789ABCDEF0"
#define BLE_CHAR_UUID    "12345678-1234-5678-1234-56789ABCDEF1"

// ── Bluetooth Classic SPP ─────────────────────────────────────────────────────
#define SPP_PEER_NAME    "AmbientNav-Rear"

// ── Front LED strip ───────────────────────────────────────────────────────────
#define FRONT_LED_PIN    5
#define FRONT_LED_COUNT  60
#define FRONT_BRIGHTNESS 128  // 50 % global cap (power budget)

// ── Optional reverse-gear signal input ───────────────────────────────────────
// Connect reverse lamp signal (5 V) via voltage divider to this pin.
// Leave unconnected (pin stays LOW) to disable hardware reverse detection.
#define REVERSE_SIGNAL_PIN 4

// ── Timing constants (milliseconds) ──────────────────────────────────────────
#define ORCH_TICK_MS         10
#define BLE_FADE_TIMEOUT_MS  5000
#define SPP_RECONNECT_MS     5000
#define SENSOR_STALE_MS       500

// ── Enums ─────────────────────────────────────────────────────────────────────
enum Direction : uint8_t {
    DIR_NONE     = 0x00,
    DIR_LEFT     = 0x01,
    DIR_RIGHT    = 0x02,
    DIR_STRAIGHT = 0x03
};

enum BlinkerState : uint8_t {
    BLINKER_OFF    = 0x00,
    BLINKER_LEFT   = 0x01,
    BLINKER_RIGHT  = 0x02,
    BLINKER_HAZARD = 0x03
};

enum EffectType {
    EFF_AMBIENT,
    EFF_NAV_LEFT,
    EFF_NAV_RIGHT,
    EFF_NAV_STRAIGHT,
    EFF_BLINKER_LEFT,
    EFF_BLINKER_RIGHT,
    EFF_HAZARD
};

// ── Shared data structures ────────────────────────────────────────────────────
struct NavState {
    Direction    direction;
    uint8_t      distance_m;   // metres, 255 = unknown / far
    BlinkerState blinker;
    uint32_t     timestamp_ms;
};

struct SensorData {
    uint16_t left_cm;
    uint16_t center_cm;
    uint16_t right_cm;
    uint32_t timestamp_ms;
};

struct EffectCommand {
    EffectType type;
    CRGB       color;      // ignored by fixed-colour effects
    uint8_t    intensity;  // 0–255, relative to global brightness cap
};

// ── FreeRTOS handles (defined in main.cpp) ────────────────────────────────────
extern QueueHandle_t   navQueue;    // NavState,      depth 4
extern QueueHandle_t   proxQueue;   // SensorData,    depth 4
extern QueueHandle_t   effectQueue; // EffectCommand, depth 2
extern SemaphoreHandle_t sppMutex;
