import 'package:flutter/material.dart';

import '../tokens/an_tokens.dart';
import 'an_brand_theme.dart';

/// [ThemeData] built from the AmbientNav brand tokens.
///
/// Nothing imports this until the palette migration lands — it exists first so
/// the change can be reviewed side by side in Widgetbook against the currently
/// shipped amber theme.
abstract final class AnAppTheme {
  static ThemeData get dark => _build(Brightness.dark, AnBrandTheme.dark);
  static ThemeData get light => _build(Brightness.light, AnBrandTheme.light);

  static ThemeData _build(Brightness brightness, AnBrandTheme brand) {
    final isDark = brightness == Brightness.dark;

    // Seeded from violet rather than cyan. #19E3FF as ColorScheme.primary fails
    // contrast against both black and white foregrounds, which Material would
    // then pick automatically for filled buttons and chips. Cyan stays what the
    // design system actually calls it — an accent and an indicator, applied
    // deliberately via AnColors, not swept in as a general-purpose primary.
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AnColors.violet,
          brightness: brightness,
        ).copyWith(
          secondary: AnColors.cyan,
          error: AnColors.magenta,
          surface: isDark ? brand.surface2 : brand.surface2,
          outline: isDark ? AnColors.text4 : AnColors.ash,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: brand.cockpit,
      canvasColor: brand.surface,
      dividerColor: brand.line,
      textTheme: _textTheme(brand),
      extensions: [brand],
      cardTheme: CardThemeData(
        color: brand.surface2,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AnRadius.lg),
          side: BorderSide(color: brand.line),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: brand.cockpit,
        foregroundColor: brand.text,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dividerTheme: DividerThemeData(color: brand.line, space: 1, thickness: 1),
    );
  }

  /// Phone-calibrated scale.
  ///
  /// Deliberately *not* the web scale in [AnTypeScale] — a 90 px display or a
  /// 46 px h1 belongs on a landing page, not in a car. The web values stay
  /// available for the Widgetbook type specimen.
  static TextTheme _textTheme(AnBrandTheme brand) {
    TextStyle display(double size) => TextStyle(
      fontFamily: AnTypography.display,
      fontSize: size,
      fontWeight: AnTypography.semibold,
      letterSpacing: size * AnTypography.lsDisplayEm,
      height: AnTypography.lhDisplay,
      color: brand.text,
    );

    TextStyle heading(double size) => TextStyle(
      fontFamily: AnTypography.display,
      fontSize: size,
      fontWeight: AnTypography.semibold,
      letterSpacing: size * AnTypography.lsHeadingEm,
      height: AnTypography.lhHeading,
      color: brand.text,
    );

    TextStyle bodyStyle(double size, Color color) => TextStyle(
      fontFamily: AnTypography.body,
      fontSize: size,
      fontWeight: AnTypography.regular,
      height: AnTypography.lhBody,
      color: color,
    );

    return TextTheme(
      displaySmall: display(AnTypeScale.h2),
      headlineMedium: heading(AnTypeScale.h2),
      headlineSmall: heading(AnTypeScale.h3),
      titleLarge: heading(AnTypeScale.h3),
      titleMedium: bodyStyle(AnTypeScale.lg, brand.text),
      bodyLarge: bodyStyle(AnTypeScale.body, brand.text2),
      bodyMedium: bodyStyle(AnTypeScale.sm, brand.text2),
      bodySmall: bodyStyle(AnTypeScale.xs, brand.text3),
      labelSmall: TextStyle(
        fontFamily: AnTypography.mono,
        fontSize: AnTypeScale.eyebrow,
        fontWeight: AnTypography.medium,
        letterSpacing: AnTypeScale.eyebrow * AnTypography.lsEyebrowEm,
        color: brand.text3,
      ),
    );
  }
}
