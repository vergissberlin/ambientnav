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
    const float CYCLE_MS  = 1050.0f;
    const float SLIDE_END = 0.78f;   // 0–78 % slide, rest = fade-out
    const float BAR_HALF  = 9.0f;    // soft half-width in LEDs (cosine window)

    float phase  = fmodf((float)elapsed, CYCLE_MS) / CYCLE_MS;
    float fCenter = (float)(FRONT_LED_COUNT / 2);
    float edge    = (dir == EFF_NAV_LEFT) ? 0.0f : (float)(FRONT_LED_COUNT - 1);

    float barPos, masterFade;
    if (phase < SLIDE_END) {
        float t       = phase / SLIDE_END;
        float smoothT = t * t * (3.0f - 2.0f * t);  // smoothstep ease-in-out
        barPos     = fCenter + smoothT * (edge - fCenter);
        masterFade = 1.0f;
    } else {
        float t    = (phase - SLIDE_END) / (1.0f - SLIDE_END);
        barPos     = edge;
        masterFade = (1.0f - t) * (1.0f - t);  // quadratic fade-out
    }

    fill_solid(leds, FRONT_LED_COUNT, CRGB::Black);

    for (int i = 0; i < FRONT_LED_COUNT; i++) {
        float dist = fabsf((float)i - barPos);
        if (dist >= BAR_HALF) continue;

        // Cosine window: 1.0 at bar centre, 0.0 at bar edge
        float cosT     = dist / BAR_HALF;           // 0 = centre, 1 = edge
        float envelope = 0.5f * (1.0f + cosf(M_PI * cosT));

        // Color: purple (120,0,220) at bar centre → pink (255,80,185) at bar edge
        float r = 120.0f + 135.0f * cosT;
        float g =           80.0f * cosT;
        float b = 220.0f -  35.0f * cosT;

        float bright = envelope * masterFade;
        leds[i] = CRGB(
            (uint8_t)(r * bright),
            (uint8_t)(g * bright),
            (uint8_t)(b * bright)
        );
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
