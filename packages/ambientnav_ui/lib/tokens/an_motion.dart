import 'package:flutter/animation.dart';

/// Motion tokens from `design-system/tokens/spacing.css`.
///
/// The brand's motion is "calm, light-like": one easing curve everywhere, three
/// durations. Light does not bounce, so there is deliberately no spring or
/// overshoot curve here.
abstract final class AnMotion {
  /// `--ease-glow: cubic-bezier(.4, 0, .2, 1)`.
  static const Curve easeGlow = Cubic(0.4, 0.0, 0.2, 1.0);

  /// `--dur-fast: 140ms` — press feedback, hover.
  static const Duration fast = Duration(milliseconds: 140);

  /// `--dur-base: 240ms` — colour and elevation transitions.
  static const Duration base = Duration(milliseconds: 240);

  /// `--dur-slow: 420ms` — entrances, larger surface changes.
  static const Duration slow = Duration(milliseconds: 420);
}
