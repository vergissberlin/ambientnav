#include "led_effects.h"
#include "config.h"
#include <FastLED.h>
#include <math.h>

static CRGB leds[REAR_LED_COUNT];

static CRGB colorForDistance(uint16_t cm) {
    if (cm >= 150) return CRGB(0,   255, 0);    // green
    if (cm >= 100) return CRGB(170, 255, 0);    // yellow-green
    if (cm >= 50)  return CRGB(255, 165, 0);    // amber
    if (cm >= 20)  return CRGB(255, 68,  0);    // orange
    return CRGB(255, 0, 0);                     // red
}

// fill = clamp((distance - 20) / 130, 0.1, 1.0)
static void renderZone(int zoneIndex, uint16_t dist_cm, uint32_t elapsed) {
    float fill;
    if (dist_cm >= 999) {
        fill = 1.0f;
    } else {
        fill = (dist_cm - 20.0f) / 130.0f;
        fill = (fill < 0.1f) ? 0.1f : (fill > 1.0f ? 1.0f : fill);
    }

    int  numLit = (int)(fill * ZONE_LED_COUNT);
    CRGB color  = colorForDistance(dist_cm);

    // Fast blink when closer than 20 cm
    if (dist_cm < 20 && (elapsed % 200) >= 100) {
        color = CRGB::Black;
    }

    int start = zoneIndex * ZONE_LED_COUNT;
    for (int i = 0; i < ZONE_LED_COUNT; i++) {
        leds[start + i] = (i < numLit) ? color : CRGB::Black;
    }
}

static void renderAmbientRear(uint32_t elapsed) {
    float   brightness = 128.0f + 127.0f * sinf(2.0f * M_PI * elapsed / 3000.0f);
    uint8_t val = (uint8_t)(brightness * 0.15f);
    fill_solid(leds, REAR_LED_COUNT, CRGB(val, val, val));
}

// ── Public interface ──────────────────────────────────────────────────────────

void ledRearInit() {
    FastLED.addLeds<WS2812B, REAR_LED_PIN, GRB>(leds, REAR_LED_COUNT)
           .setCorrection(TypicalLEDStrip);
    FastLED.setBrightness(REAR_BRIGHTNESS);
    fill_solid(leds, REAR_LED_COUNT, CRGB::Black);
    FastLED.show();
}

void taskLEDRear(void* param) {
    bool     reverseActive = false;
    uint32_t effectStart   = millis();

    for (;;) {
        bool newActive;
        while (xQueueReceive(cmdQueue, &newActive, 0) == pdTRUE) {
            if (newActive != reverseActive) {
                effectStart   = millis();
                reverseActive = newActive;
            }
        }

        uint32_t elapsed = millis() - effectStart;

        if (reverseActive) {
            SensorData d = { 999, 999, 999 };
            xQueuePeek(sensorQueue, &d, 0);  // peek: don't consume, ultrasonic task refills
            renderZone(0, d.left_cm,   elapsed);
            renderZone(1, d.center_cm, elapsed);
            renderZone(2, d.right_cm,  elapsed);
        } else {
            renderAmbientRear(elapsed);
        }

        FastLED.show();
        vTaskDelay(pdMS_TO_TICKS(10));
    }
}
