/// Dart mirror of the 4 px grid and radius scale in
/// `design-system/tokens/spacing.css`.
abstract final class AnSpace {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 24;
  static const double s6 = 32;
  static const double s7 = 48;
  static const double s8 = 64;
  static const double s9 = 92;
  static const double s10 = 120;

  /// Ordered scale, for the Widgetbook spacing specimen.
  static const List<double> scale = [s1, s2, s3, s4, s5, s6, s7, s8, s9, s10];
}

/// Corner radii. Soft throughout — never pill, except the light strip and
/// toggles, which use [strip].
abstract final class AnRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double strip = 999;

  /// Ordered scale, for the Widgetbook radius specimen.
  static const List<double> scale = [xs, sm, md, lg, xl];
}
