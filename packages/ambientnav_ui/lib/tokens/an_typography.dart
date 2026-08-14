import 'package:flutter/painting.dart';

/// Dart mirror of `design-system/tokens/typography.css`.
///
/// The three brand families are only published as remote webfonts, and the only
/// TTFs in `design-system/fonts/` are Montserrat — which is **not** one of them
/// and must not be substituted. Until the OFL files are vendored into
/// `app/assets/fonts/`, [kBrandFontsAvailable] stays false and the family names
/// resolve to null, i.e. the platform default.
///
/// That still carries most of the identity: the -0.035em display tracking, the
/// 0.26em eyebrow tracking and the 0.98 display line-height do more work here
/// than the glyph shapes do.
///
/// `google_fonts` is deliberately not used — it downloads at runtime, and this
/// app exists to navigate offline in a car.
abstract final class AnTypography {
  /// Flip once the OFL fonts are bundled and declared in the app's pubspec.
  static const bool kBrandFontsAvailable = false;

  static const String? display = kBrandFontsAvailable ? 'Space Grotesk' : null;
  static const String? body = kBrandFontsAvailable ? 'IBM Plex Sans' : null;
  static const String? mono = kBrandFontsAvailable ? 'IBM Plex Mono' : null;

  // ── Weights ────────────────────────────────────────────────────────────────
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // ── Letter spacing ─────────────────────────────────────────────────────────
  // CSS `em` values are relative to font size, so they are applied as
  // `size * factor` at each call site rather than stored as logical pixels.
  static const double lsDisplayEm = -0.035;
  static const double lsHeadingEm = -0.02;
  static const double lsBodyEm = 0.0;
  static const double lsEyebrowEm = 0.26;

  // ── Line heights (CSS unitless -> Flutter `height`) ────────────────────────
  static const double lhDisplay = 0.98;
  static const double lhHeading = 1.12;
  static const double lhBody = 1.6;

  /// The label style shared by the brand buttons.
  static TextStyle buttonLabel(double fontSize) => TextStyle(
    fontFamily: display,
    fontSize: fontSize,
    fontWeight: semibold,
    letterSpacing: fontSize * -0.01,
    height: 1.0,
  );

  /// The all-caps mono label used by [AnBadge]-style chips.
  static TextStyle badgeLabel({double fontSize = 11.5}) => TextStyle(
    fontFamily: mono,
    fontSize: fontSize,
    fontWeight: medium,
    letterSpacing: fontSize * 0.1,
    height: 1.0,
  );
}

/// The raw web type scale, in px.
///
/// Kept verbatim for the Widgetbook type specimen — it is **not** the app's
/// `TextTheme`. A 90 px headline has no place in an in-car HMI, so
/// `AnAppTheme` calibrates its own phone-appropriate scale.
abstract final class AnTypeScale {
  static const double display = 90;
  static const double h1 = 46;
  static const double h2 = 30;
  static const double h3 = 22;
  static const double lg = 18;
  static const double body = 16;
  static const double sm = 14;
  static const double xs = 12;
  static const double eyebrow = 12;

  /// Ordered (name, size) pairs for the specimen.
  static const List<(String, double)> scale = [
    ('display', display),
    ('h1', h1),
    ('h2', h2),
    ('h3', h3),
    ('lg', lg),
    ('body', body),
    ('sm', sm),
    ('xs', xs),
  ];
}
