#include "led_effects.h"
#include "config.h"
#include <FastLED.h>
#include <math.h>

static CRGB leds[FRONT_LED_COUNT];

// ── Effect renderers ──────────────────────────────────────────────────────────

static void renderAmbient(uint32_t elapsed) {
    float brightness = 128.0f + 127.0f * sinf(2.0f * M_PI * elapsed / 3000.0f);
    uint8_t val = (uint8_t)(brightness * 0.20f);  // 20 % max
    fill_solid(leds, FRONT_LED_COUNT, CRGB(val, val, val));
}

static void renderNavWave(EffectType dir, uint32_t elapsed) {
    const int   center     = FRONT_LED_COUNT / 2;
    const float CYCLE_MS   = 1100.0f;
    const float SWEEP_FRAC = 0.72f;  // 0–72 % sequential fill, rest = fade-out

    float phase   = fmodf((float)elapsed, CYCLE_MS) / CYCLE_MS;
    int   halfLen = center;

    fill_solid(leds, FRONT_LED_COUNT, CRGB::Black);

    // Paint one LED with position-based color and a master brightness factor.
    // posNorm 0 = closest to center, 1 = outermost LED.
    auto paint = [&](int idx, float posNorm, float masterFade) {
        // Amber (255,160,0) → deep orange (255,90,0) toward the edge
        float g      = 160.0f - 70.0f * posNorm;
        // Subtle organic ripple so adjacent LEDs are never identically bright
        float ripple = 0.88f + 0.12f * sinf(posNorm * M_PI * 4.0f + elapsed * 0.003f);
        float bright = masterFade * ripple;
        leds[idx] = CRGB(
            (uint8_t)(255.0f * bright),
            (uint8_t)(g      * bright),
            0
        );
    };

    if (phase < SWEEP_FRAC) {
        // Sequential fill: LEDs light up one by one from center to edge
        float sweepProgress = phase / SWEEP_FRAC;
        int   litCount      = max(1, (int)(sweepProgress * halfLen));

        for (int i = 0; i < litCount; i++) {
            float posNorm = (float)i / (halfLen - 1);
            // Trailing LEDs are slightly dimmer; wave-front LED is always full
            float fade = (i == litCount - 1) ? 1.0f : (0.60f + 0.40f * (float)i / litCount);
            int   idx  = (dir == EFF_NAV_LEFT) ? (center - 1 - i) : (center + i);
            idx = constrain(idx, 0, FRONT_LED_COUNT - 1);
            paint(idx, posNorm, fade);
        }
    } else {
        // Whole active half fades out smoothly (quadratic ease-out)
        float t          = (phase - SWEEP_FRAC) / (1.0f - SWEEP_FRAC);
        float masterFade = (1.0f - t) * (1.0f - t);

        for (int i = 0; i < halfLen; i++) {
            float posNorm = (float)i / (halfLen - 1);
            int   idx     = (dir == EFF_NAV_LEFT) ? (center - 1 - i) : (center + i);
            idx = constrain(idx, 0, FRONT_LED_COUNT - 1);
            paint(idx, posNorm, masterFade);
        }
    }
}

static void renderNavStraight(uint32_t elapsed) {
    float   phase = fmodf((float)elapsed, 800.0f) / 800.0f;
    uint8_t val   = (uint8_t)(255.0f * sinf(M_PI * phase));
    fill_solid(leds, FRONT_LED_COUNT, CRGB(val, val, val));
}

static void renderBlinker(EffectType side, uint32_t elapsed) {
    bool on = ((elapsed % 400) < 200);
    static const CRGB amber = CRGB(255, 160, 0);
    int  start = (side == EFF_BLINKER_LEFT)  ? 0               : FRONT_LED_COUNT / 2;
    int  end   = (side == EFF_BLINKER_LEFT)  ? FRONT_LED_COUNT / 2 : FRONT_LED_COUNT;
    for (int i = 0; i < FRONT_LED_COUNT; i++) {
        leds[i] = (i >= start && i < end && on) ? amber : CRGB::Black;
    }
}

static void renderHazard(uint32_t elapsed) {
    bool on = ((elapsed % 400) < 200);
    fill_solid(leds, FRONT_LED_COUNT, on ? CRGB(255, 160, 0) : CRGB::Black);
}

// ── Public interface ──────────────────────────────────────────────────────────

void ledFrontInit() {
    FastLED.addLeds<WS2812B, FRONT_LED_PIN, GRB>(leds, FRONT_LED_COUNT)
           .setCorrection(TypicalLEDStrip);
    FastLED.setBrightness(FRONT_BRIGHTNESS);
    fill_solid(leds, FRONT_LED_COUNT, CRGB::Black);
    FastLED.show();
}

void taskLEDFront(void* param) {
    EffectCommand cmd = { EFF_AMBIENT, CRGB::White, 255 };
    uint32_t      effectStart = millis();

    for (;;) {
        EffectCommand newCmd;
        if (xQueueReceive(effectQueue, &newCmd, 0) == pdTRUE) {
            if (newCmd.type != cmd.type) {
                effectStart = millis();
                cmd = newCmd;
            }
        }

        // Apply the runtime brightness set over BLE (LED-config characteristic).
        if (xSemaphoreTake(configMutex, 0) == pdTRUE) {
            FastLED.setBrightness(g_ledConfig.brightness);
            xSemaphoreGive(configMutex);
        }

        uint32_t elapsed = millis() - effectStart;

        switch (cmd.type) {
            case EFF_AMBIENT:       renderAmbient(elapsed);              break;
            case EFF_NAV_LEFT:      renderNavWave(EFF_NAV_LEFT,  elapsed); break;
            case EFF_NAV_RIGHT:     renderNavWave(EFF_NAV_RIGHT, elapsed); break;
            case EFF_NAV_STRAIGHT:  renderNavStraight(elapsed);          break;
            case EFF_BLINKER_LEFT:  renderBlinker(EFF_BLINKER_LEFT,  elapsed); break;
            case EFF_BLINKER_RIGHT: renderBlinker(EFF_BLINKER_RIGHT, elapsed); break;
            case EFF_HAZARD:        renderHazard(elapsed);               break;
        }

        FastLED.show();
        vTaskDelay(pdMS_TO_TICKS(10));
    }
}
