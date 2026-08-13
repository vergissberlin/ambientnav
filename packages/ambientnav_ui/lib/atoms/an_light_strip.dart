import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/an_brand_theme.dart';
import '../tokens/an_tokens.dart';

/// Behaviour of an [AnLightStrip].
enum AnLightStripMode {
  /// Calm idle gradient across the full strip.
  ambient,

  /// Cyan flow brightening toward [AnLightStrip.direction].
  guide,

  /// Magenta filling inward from both ends by [AnLightStrip.intensity].
  alert,
}

enum AnLightStripDirection { left, right }

/// Port of `design-system/components/light/LightStrip.jsx` — the signature
/// AmbientNav element, a horizontal addressable-LED strip rendering the brand's
/// light language.
///
/// **Scope: this is a brand specimen, not a live effect preview.** The firmware
/// in `firmware/front/src/led_effects.cpp` and the docs visualizer in
/// `docs/src/components/LedEffectsVisualizer.astro` are the two representations
/// bound by the parity invariant in CLAUDE.md. This widget deliberately models
/// only the three design-system modes and is not driven by real effect state,
/// so it does not become a third thing to keep in sync. Wiring it to
/// `EffectType` would mean extending that invariant — and adding the
/// `EFF_NAV_STRAIGHT` and blinker modes the web spec has no equivalent for.
class AnLightStrip extends StatelessWidget {
  const AnLightStrip({
    super.key,
    this.mode = AnLightStripMode.ambient,
    this.direction = AnLightStripDirection.right,
    this.intensity = 0.6,
    this.leds = 28,
    this.height = 16,
  }) : assert(leds > 1, 'a strip needs at least two LEDs');

  final AnLightStripMode mode;
  final AnLightStripDirection direction;

  /// How far the alert fill has closed in, 0..1. Ignored in other modes.
  final double intensity;

  final int leds;
  final double height;

  /// Structural port of the JSX `colorFor(i)` so the two stay comparable.
  Color _colorFor(int i) {
    final t = i / (leds - 1);
    switch (mode) {
      case AnLightStripMode.guide:
        final pos = direction == AnLightStripDirection.right ? t : 1 - t;
        return AnColors.cyan.withValues(alpha: 0.12 + pos * 0.88);

      case AnLightStripMode.alert:
        // 0 at the centre, 1 at the edges.
        final edge = math.min(t, 1 - t) * 2;
        final on = edge >= 1 - intensity;
        return AnColors.magenta.withValues(
          alpha: on ? 0.5 + intensity * 0.5 : 0.08,
        );

      case AnLightStripMode.ambient:
        const stops = [AnColors.cyan, AnColors.violet, AnColors.magenta];
        final seg = t * 2;
        final idx = math.min(1, seg.floor());
        final f = seg - idx;
        return Color.lerp(
          stops[idx],
          stops[idx + 1],
          f,
        )!.withValues(alpha: 0.55);
    }
  }

  List<BoxShadow> _glow() => switch (mode) {
    AnLightStripMode.alert => AnShadows.glowMagenta,
    AnLightStripMode.guide => AnShadows.glowCyan,
    AnLightStripMode.ambient => AnShadows.glowViolet,
  };

  @override
  Widget build(BuildContext context) {
    final brand = AnBrandTheme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: brand.line),
        borderRadius: BorderRadius.circular(AnRadius.strip),
        boxShadow: _glow(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          spacing: 2,
          children: [
            for (var i = 0; i < leds; i++)
              Expanded(
                child: AnimatedContainer(
                  duration: AnMotion.base,
                  curve: AnMotion.easeGlow,
                  height: height,
                  decoration: BoxDecoration(
                    color: _colorFor(i),
                    borderRadius: BorderRadius.circular(AnRadius.strip),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
