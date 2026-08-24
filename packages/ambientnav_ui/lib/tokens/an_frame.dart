import 'an_spacing.dart';

/// Dart mirror of `design-system/tokens/frame.css`.
///
/// The Cybernetic Frame is a second layer on top of the calm cockpit
/// foundation: sharp corner brackets, occasional scanline texture, and brief
/// glitch-flicker accents. Colors live in [AnColors] (`frameColor`,
/// `frameColorAlert`, `frameColorBrand`, `glitchColorA`, `glitchColorB`,
/// `scanline`); the geometry and opacity constants live here.
///
/// See readme.md → "The Cybernetic Frame" for the full usage rules
/// (scope-out list, motion-accessibility note, color discipline).
abstract final class AnFrame {
  /// `--amb-frame-thickness: 2px`.
  static const double thickness = 2.0;

  /// `--amb-frame-leg: var(--space-4)` — leg length of a corner bracket,
  /// snapped to the 4px grid. References [AnSpace.s4] rather than
  /// duplicating the literal 16px value.
  static const double leg = AnSpace.s4;

  /// `--amb-frame-opacity-rest: .35`.
  static const double opacityRest = 0.35;

  /// `--amb-frame-opacity-active: .9`.
  static const double opacityActive = 0.9;

  /// `--radius-frame: 2px` — near-sharp, contrasts against the soft
  /// 12–16px card radius the brackets sit on.
  static const double radius = 2.0;

  /// `--amb-glitch-offset: 2px`.
  static const double glitchOffset = 2.0;
}
