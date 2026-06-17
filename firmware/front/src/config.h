#pragma once
#include <Arduino.h>
#include <FastLED.h>

#define FIRMWARE_VERSION "0.1.0"

// ── BLE ──────────────────────────────────────────────────────────────────────
#define BLE_DEVICE_NAME  "AmbientNav-Front"
#define BLE_SERVICE_UUID "12345678-1234-5678-1234-56789ABCDEF0"
#define BLE_CHAR_UUID    "12345678-1234-5678-1234-56789ABCDEF1"

// Extended GATT (see docs/protocols.md). All multi-byte values little-endian.
#define BLE_SVC_TELEMETRY  "12345678-1234-5678-1234-56789ABCDEF2"
#define BLE_CHR_VOLTAGE    "12345678-1234-5678-1234-56789ABCDEF3" // Read/Notify u16 mV
#define BLE_CHR_DEVINFO    "12345678-1234-5678-1234-56789ABCDEF4" // Read role+fw
#define BLE_SVC_LEDCFG     "12345678-1234-5678-1234-56789ABCDEF5"
#define BLE_CHR_LEDCFG     "12345678-1234-5678-1234-56789ABCDEF6" // Read/Write
#define BLE_SVC_SENSORCFG  "12345678-1234-5678-1234-56789ABCDEF7"
#define BLE_CHR_SENSORCFG  "12345678-1234-5678-1234-56789ABCDEF8" // Read/Write
#define BLE_SVC_OTA        "12345678-1234-5678-1234-56789ABCDEF9"
#define BLE_CHR_OTA_CTRL   "12345678-1234-5678-1234-56789ABCDEFA" // Write/Notify
#define BLE_CHR_OTA_DATA   "12345678-1234-5678-1234-56789ABCDEFB" // Write Without Response

// Per-device 6-digit passkey for LE Secure Connections + bonding. Config/OTA
// characteristics require an encrypted, authenticated link. Override per unit.
#define BLE_PASSKEY      123456

// Role reported via the device-info characteristic: 0 = front, 1 = rear.
#define DEVICE_ROLE      0

// ── Battery / supply voltage sense ────────────────────────────────────────────
// ADC pin on a resistor divider from the supply/battery rail. ESP32 ADC is
// 0–3.3 V over 12 bits; DIVIDER is (R1+R2)/R2 of the external divider.
#define BATTERY_SENSE_PIN  34
#define BATTERY_DIVIDER    2.0f
#define BATTERY_NOTIFY_MS  1000

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

// ── Runtime configuration (settable over BLE) ─────────────────────────────────
struct LedRuntimeConfig {
    uint16_t led_count;    // active LED count (≤ FRONT_LED_COUNT)
    uint8_t  brightness;   // 0–255 global brightness
    uint8_t  effect;       // effect id (firmware catalogue)
    uint8_t  params[4];    // effect parameter bytes (e.g. RGB)
};

struct SensorRuntimeConfig {
    uint8_t  active_sensor;     // 0=left 1=center 2=right 3=fused
    int16_t  calib_offset_cm;   // signed calibration offset
    uint16_t max_range_cm;      // reported max range
};

// ── FreeRTOS handles (defined in main.cpp) ────────────────────────────────────
extern QueueHandle_t   navQueue;    // NavState,      depth 4
extern QueueHandle_t   proxQueue;   // SensorData,    depth 4
extern QueueHandle_t   effectQueue; // EffectCommand, depth 2
extern SemaphoreHandle_t sppMutex;

// Shared runtime config (guarded by configMutex; defined in main.cpp)
extern LedRuntimeConfig    g_ledConfig;
extern SensorRuntimeConfig g_sensorConfig;
extern SemaphoreHandle_t   configMutex;
