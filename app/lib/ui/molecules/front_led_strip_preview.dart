import 'dart:math' as math;

import 'package:ambientnav_ui/ambientnav_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Which LED effect the simulated front strip is currently showing — mirrors
/// a subset of `firmware/front/src/led_effects.cpp`'s `EffectType` (turning
/// and hazard only; a standalone turn-signal/blinker state isn't modeled
/// since the app has no manual turn-signal control to drive it from).
enum FrontStripEffect { ambient, navLeft, navRight, navStraight, hazard }

/// A live, on-screen simulation of the physical front LED strip, matching
/// `firmware/front/src/led_effects.cpp`'s actual colors and timing (not the
/// docs site's more stylized Astro visualizer, which takes artistic license
/// with color):
/// - [FrontStripEffect.navLeft]/[navRight] — a purple-core, pink-edge bar
///   that slides from the strip's centre to the corresponding edge over
///   819ms (ease-in-out), then fades over the remaining 231ms of a 1050ms
///   loop.
/// - [FrontStripEffect.navStraight] — the whole strip pulses white, one
///   half-sine hump every 800ms.
/// - [FrontStripEffect.hazard] — the whole strip blinks amber, 200ms on /
///   200ms off.
/// - [FrontStripEffect.ambient] — a slow white breathing glow, 3000ms cycle.
///
/// Deliberately a separate widget from `AnLightStrip`: that atom is
/// documented as a brand specimen kept off live effect state, so extending
/// it here would pull `ambientnav_ui` into the firmware<->docs parity
/// invariant (see CLAUDE.md) and add modes the web/docs spec doesn't have.
/// This widget lives in the app instead, where it's allowed to know about
/// real `EffectType` behaviour without making that claim on the design
/// system.
class FrontLedStripPreview extends StatefulWidget {
  const FrontLedStripPreview({
    super.key,
    required this.effect,
    this.ledCount = 48,
  });

  final FrontStripEffect effect;
  final int ledCount;

  @override
  State<FrontLedStripPreview> createState() => _FrontLedStripPreviewState();
}

class _FrontLedStripPreviewState extends State<FrontLedStripPreview>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _effectStart = Duration.zero;
  Duration _elapsedInEffect = Duration.zero;
  FrontStripEffect? _lastEffect;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (widget.effect != _lastEffect) {
      _lastEffect = widget.effect;
      _effectStart = elapsed;
    }
    setState(() => _elapsedInEffect = elapsed - _effectStart);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = AnBrandTheme.of(context);
    final colors = _colorsFor(
      widget.effect,
      _elapsedInEffect.inMilliseconds,
      widget.ledCount,
    );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: brand.surface2,
        borderRadius: BorderRadius.circular(AnRadius.strip),
        border: Border.all(color: brand.line),
      ),
      child: SizedBox(
        height: 14,
        child: Row(
          children: [
            for (final color in colors)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 0.75),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static List<Color> _colorsFor(FrontStripEffect effect, int ms, int n) {
    switch (effect) {
      case FrontStripEffect.ambient:
        return _ambient(ms, n);
      case FrontStripEffect.navLeft:
        return _navWave(ms, n, toRight: false);
      case FrontStripEffect.navRight:
        return _navWave(ms, n, toRight: true);
      case FrontStripEffect.navStraight:
        return _navStraight(ms, n);
      case FrontStripEffect.hazard:
        return _hazard(ms, n);
    }
  }

  /// `renderAmbient()` — full sine breathe, 3000ms cycle. Firmware caps this
  /// at 20% of full LED brightness on real hardware; kept similarly dim here
  /// so the idle state reads as a barely-there glow rather than a bug.
  static List<Color> _ambient(int ms, int n) {
    final phase = (ms % 3000) / 3000;
    final brightness = 0.5 + 0.5 * math.sin(2 * math.pi * phase);
    final opacity = 0.08 + 0.22 * brightness;
    final color = Colors.white.withValues(alpha: opacity);
    return List.filled(n, color);
  }

  /// `renderNavWave()` — a soft purple-core/pink-edge bar (half-width 9 of
  /// 60 firmware LEDs, scaled proportionally to [n]) that slides from centre
  /// to the target edge over the first 78% of a 1050ms cycle (smoothstep
  /// ease-in-out), then fades out over the remaining 22%.
  static List<Color> _navWave(int ms, int n, {required bool toRight}) {
    const cycleMs = 1050;
    const slideEnd = 0.78;
    final t = (ms % cycleMs) / cycleMs;
    final centerLed = n / 2;
    final edgeLed = toRight ? n - 1.0 : 0.0;
    final barHalf = n * (9 / 60);

    double centerPos;
    double masterFade;
    if (t < slideEnd) {
      final slideT = t / slideEnd;
      final eased = slideT * slideT * (3 - 2 * slideT); // smoothstep
      centerPos = centerLed + (edgeLed - centerLed) * eased;
      masterFade = 1.0;
    } else {
      centerPos = edgeLed;
      final fadeT = (t - slideEnd) / (1 - slideEnd);
      masterFade = (1 - fadeT) * (1 - fadeT);
    }

    return List.generate(n, (i) {
      final dist = (i - centerPos).abs();
      if (dist > barHalf) return Colors.transparent;
      final envelope = 0.5 * (1 + math.cos(math.pi * dist / barHalf));
      final cosT = (dist / barHalf).clamp(0.0, 1.0);
      final r = (120 + 135 * cosT).round();
      final g = (80 * cosT).round();
      final b = (220 - 35 * cosT).round();
      final a = (envelope * masterFade).clamp(0.0, 1.0);
      return Color.fromRGBO(r, g, b, a);
    });
  }

  /// `renderNavStraight()` — whole strip, one half-sine pulse every 800ms.
  static List<Color> _navStraight(int ms, int n) {
    final phase = (ms % 800) / 800;
    final value = math.sin(math.pi * phase).clamp(0.0, 1.0);
    final color = Colors.white.withValues(alpha: value);
    return List.filled(n, color);
  }

  /// `renderHazard()` — whole strip, hard amber blink, 200ms on / 200ms off.
  static List<Color> _hazard(int ms, int n) {
    final on = (ms % 400) < 200;
    final color = on ? const Color(0xFFFFA000) : Colors.transparent;
    return List.filled(n, color);
  }
}
