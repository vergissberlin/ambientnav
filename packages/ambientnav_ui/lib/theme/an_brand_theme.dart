import 'package:flutter/material.dart';

import '../tokens/an_tokens.dart';

/// Semantic brand surfaces and text levels that differ between light and dark.
///
/// The raw scales (spacing, radii, accents, durations) stay as `const` statics
/// in `tokens/` — they never lerp and never vary by brightness, so putting them
/// here would be ~20 fields of [copyWith]/[lerp] boilerplate for nothing.
///
/// Read with [AnBrandTheme.of], which falls back to [dark] when the extension
/// is absent. That fallback matters: brand atoms then still render under a bare
/// `MaterialApp` — as in `app/test/widget/pump_app.dart` — instead of throwing.
@immutable
class AnBrandTheme extends ThemeExtension<AnBrandTheme> {
  const AnBrandTheme({
    required this.cockpit,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.line,
    required this.lineStrong,
    required this.text,
    required this.text2,
    required this.text3,
    required this.text4,
  });

  /// The dark cockpit palette — the brand's primary form.
  static const AnBrandTheme dark = AnBrandTheme(
    cockpit: AnColors.cockpit,
    surface: AnColors.surface,
    surface2: AnColors.surface2,
    surface3: AnColors.surface3,
    line: AnColors.line,
    lineStrong: AnColors.lineStrong,
    text: AnColors.text,
    text2: AnColors.text2,
    text3: AnColors.text3,
    text4: AnColors.text4,
  );

  /// Light knockout. The design system is dark-first and defines no light
  /// surface ladder, so these are derived from the neutrals rather than
  /// mirrored from CSS — the token drift test does not cover them.
  static const AnBrandTheme light = AnBrandTheme(
    cockpit: AnColors.daylight,
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFFFFFFF),
    surface3: Color(0xFFEDF0F7),
    line: Color(0x14000000),
    lineStrong: Color(0x24000000),
    text: AnColors.ink,
    text2: Color(0xFF3A4152),
    text3: AnColors.ash,
    text4: Color(0xFF8A93A6),
  );

  final Color cockpit;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color line;
  final Color lineStrong;
  final Color text;
  final Color text2;
  final Color text3;
  final Color text4;

  /// The brand palette for [context], defaulting to [dark] when no
  /// [AnBrandTheme] is registered on the ambient [Theme].
  static AnBrandTheme of(BuildContext context) =>
      Theme.of(context).extension<AnBrandTheme>() ?? dark;

  @override
  AnBrandTheme copyWith({
    Color? cockpit,
    Color? surface,
    Color? surface2,
    Color? surface3,
    Color? line,
    Color? lineStrong,
    Color? text,
    Color? text2,
    Color? text3,
    Color? text4,
  }) {
    return AnBrandTheme(
      cockpit: cockpit ?? this.cockpit,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      surface3: surface3 ?? this.surface3,
      line: line ?? this.line,
      lineStrong: lineStrong ?? this.lineStrong,
      text: text ?? this.text,
      text2: text2 ?? this.text2,
      text3: text3 ?? this.text3,
      text4: text4 ?? this.text4,
    );
  }

  @override
  AnBrandTheme lerp(ThemeExtension<AnBrandTheme>? other, double t) {
    if (other is! AnBrandTheme) return this;
    return AnBrandTheme(
      cockpit: Color.lerp(cockpit, other.cockpit, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      surface3: Color.lerp(surface3, other.surface3, t)!,
      line: Color.lerp(line, other.line, t)!,
      lineStrong: Color.lerp(lineStrong, other.lineStrong, t)!,
      text: Color.lerp(text, other.text, t)!,
      text2: Color.lerp(text2, other.text2, t)!,
      text3: Color.lerp(text3, other.text3, t)!,
      text4: Color.lerp(text4, other.text4, t)!,
    );
  }
}
