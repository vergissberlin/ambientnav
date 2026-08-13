import 'package:flutter/painting.dart';

/// Dart mirror of `design-system/tokens/colors.css`.
///
/// Cyan and magenta are **semantic, never decorative**: cyan means direction
/// and guidance, magenta means proximity and warning. Violet bridges the two
/// and carries the brand itself. Picking an accent for looks alone breaks the
/// light language the product is built on.
///
/// Kept in sync by `test/tokens_match_css_test.dart`, which parses the CSS and
/// fails if these drift.
abstract final class AnColors {
  // ── Signal accents ─────────────────────────────────────────────────────────
  /// Guide Cyan — direction & flow.
  static const Color cyan = Color(0xFF19E3FF);
  static const Color cyanSoft = Color(0xFF5CEFFF);
  static const Color cyanDeep = Color(0xFF05323A);

  /// Signal Violet — transition / brand.
  static const Color violet = Color(0xFF7C5CFF);
  static const Color violetSoft = Color(0xFFA38CFF);

  /// Alert Magenta — proximity & warning.
  static const Color magenta = Color(0xFFFF2D9C);
  static const Color magentaSoft = Color(0xFFFF6FC2);
  static const Color magentaDeep = Color(0xFF3A0A24);

  // ── Cockpit base & surfaces (dark first) ───────────────────────────────────
  static const Color cockpit = Color(0xFF06080E);
  static const Color surface = Color(0xFF0B0F18);
  static const Color surface2 = Color(0xFF0E121C);
  static const Color surface3 = Color(0xFF151A26);

  /// `rgba(255,255,255,.08)`.
  static const Color line = Color(0x14FFFFFF);

  /// `rgba(255,255,255,.14)`.
  static const Color lineStrong = Color(0x24FFFFFF);

  // ── Text on dark ───────────────────────────────────────────────────────────
  static const Color text = Color(0xFFEEF2FA);
  static const Color text2 = Color(0xFFC7CEDC);
  static const Color text3 = Color(0xFF9AA4B8);
  static const Color text4 = Color(0xFF6B7488);

  // ── Neutrals (light contexts / knockouts) ──────────────────────────────────
  static const Color daylight = Color(0xFFF4F6FB);
  static const Color ash = Color(0xFF9AA4B8);
  static const Color ink = Color(0xFF0B0F18);

  // ── Hex strings for MapLibre style layers ──────────────────────────────────
  // MapLibre's LineOptions/CircleOptions take colour *strings*, not Colors.
  // See app/lib/features/navigation/presentation/map_screen.dart.
  static const String cyanHex = '#19E3FF';
  static const String violetHex = '#7C5CFF';
  static const String magentaHex = '#FF2D9C';
  static const String whiteHex = '#FFFFFF';

  // ── Gradients ──────────────────────────────────────────────────────────────
  /// `--amb-gradient`: 120° cyan → violet → magenta.
  static const LinearGradient gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyan, violet, magenta],
    stops: [0.0, 0.5, 1.0],
  );

  /// `--amb-gradient-h`: the same ramp, horizontal.
  static const LinearGradient gradientH = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [cyan, violet, magenta],
    stops: [0.0, 0.5, 1.0],
  );
}
