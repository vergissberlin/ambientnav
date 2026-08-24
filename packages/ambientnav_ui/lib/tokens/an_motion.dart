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

  /// Glitch-flicker duration for the Cybernetic Frame's triggered RGB-split /
  /// opacity-jitter accent (hover, state-change, page-load reveal — never a
  /// looping animation). `frame.css` has no `--amb-glitch-dur` variable; this
  /// is a Dart-only motion value kept in the 150–250ms range readme.md
  /// specifies.
  static const Duration glitchFlicker = Duration(milliseconds: 180);

  /// 7s idle-loop duration for [AnPanelAccent.scanline] — ambient background
  /// motion, not a transition. `frame.css` only documents the *look* of a
  /// scanline texture, not a loop speed, so this is a Dart-only value picked
  /// in the 6–8s range that reads as slow HUD sweep rather than a spinner.
  static const Duration scan = Duration(milliseconds: 7000);
}
