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

static void renderNavSweep(EffectType dir, uint32_t elapsed) {
    fill_solid(leds, FRONT_LED_COUNT, CRGB::Black);
    float phase  = fmodf((float)elapsed, 600.0f) / 600.0f;  // 0.0–1.0 per cycle
    int   center = FRONT_LED_COUNT / 2;
    int   head;
    if (dir == EFF_NAV_LEFT) {
        head = center - (int)(phase * center);
    } else {
        head = center + (int)(phase * center);
    }
    head = constrain(head, 0, FRONT_LED_COUNT - 1);

    // 9-pixel dot with 5-pixel trailing fade
    static const CRGB amber = CRGB(255, 160, 0);
    for (int i = -4; i <= 4; i++) {
        int idx = head + i;
        if (idx < 0 || idx >= FRONT_LED_COUNT) continue;
        uint8_t fade = 255 - (uint8_t)(abs(i) * 30);
        leds[idx] = CRGB((uint8_t)(amber.r * fade / 255),
                         (uint8_t)(amber.g * fade / 255),
                         (uint8_t)(amber.b * fade / 255));
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

        uint32_t elapsed = millis() - effectStart;

        switch (cmd.type) {
            case EFF_AMBIENT:       renderAmbient(elapsed);              break;
            case EFF_NAV_LEFT:      renderNavSweep(EFF_NAV_LEFT,  elapsed); break;
            case EFF_NAV_RIGHT:     renderNavSweep(EFF_NAV_RIGHT, elapsed); break;
            case EFF_NAV_STRAIGHT:  renderNavStraight(elapsed);          break;
            case EFF_BLINKER_LEFT:  renderBlinker(EFF_BLINKER_LEFT,  elapsed); break;
            case EFF_BLINKER_RIGHT: renderBlinker(EFF_BLINKER_RIGHT, elapsed); break;
            case EFF_HAZARD:        renderHazard(elapsed);               break;
        }

        FastLED.show();
        vTaskDelay(pdMS_TO_TICKS(10));
    }
}
