import 'package:flutter/painting.dart';

import 'an_colors.dart';

/// Elevation tokens from `design-system/tokens/spacing.css` and the glow
/// shadows from `colors.css`.
///
/// The brand rule is **glow, not grey drop**: accent blooms carry elevation on
/// dark surfaces. [card] and [raised] are the only neutral shadows, and they
/// sit behind panels rather than under interactive elements.
abstract final class AnShadows {
  /// `--shadow-card`.
  ///
  /// The CSS value also carries an inset highlight
  /// (`0 1px 0 rgba(255,255,255,.04) inset`) that Flutter's [BoxShadow] cannot
  /// express — reproducing it needs a Stack with a gradient overlay, which is
  /// not worth it for a 4% white hairline. Deliberately dropped.
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x66000000), // rgba(0,0,0,.4)
      blurRadius: 30,
      offset: Offset(0, 8),
    ),
  ];

  /// `--shadow-raised: 0 12px 44px rgba(0,0,0,.5)`.
  static const List<BoxShadow> raised = [
    BoxShadow(color: Color(0x80000000), blurRadius: 44, offset: Offset(0, 12)),
  ];

  /// `--amb-glow-cyan: 0 0 24px rgba(25,227,255,.55)`.
  static const List<BoxShadow> glowCyan = [
    BoxShadow(color: Color(0x8C19E3FF), blurRadius: 24),
  ];

  /// `--amb-glow-violet: 0 0 24px rgba(124,92,255,.55)`.
  static const List<BoxShadow> glowViolet = [
    BoxShadow(color: Color(0x8C7C5CFF), blurRadius: 24),
  ];

  /// `--amb-glow-magenta: 0 0 24px rgba(255,45,156,.55)`.
  static const List<BoxShadow> glowMagenta = [
    BoxShadow(color: Color(0x8CFF2D9C), blurRadius: 24),
  ];

  /// The glow matching an accent colour, or none for anything else.
  static List<BoxShadow> glowFor(Color accent) {
    if (accent == AnColors.cyan) return glowCyan;
    if (accent == AnColors.violet) return glowViolet;
    if (accent == AnColors.magenta) return glowMagenta;
    return const [];
  }
}
