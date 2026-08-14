import 'package:ambientnav_ui/ambientnav_ui.dart';
import 'package:flutter/material.dart';

/// Light and dark [ThemeData] for AmbientNav.
///
/// A thin façade over [AnAppTheme] in `package:ambientnav_ui`, which builds the
/// themes from the tokens mirrored out of `design-system/tokens/`. Kept as a
/// façade so app code and tests keep one stable import for "the app's theme"
/// regardless of where it is assembled.
///
/// The amber seed this used to carry (`#FFB300`) was never the brand — the
/// design system defines a cyan/violet/magenta signal palette on dark cockpit
/// surfaces, and describes the app as its only screen-based surface. Cyan means
/// direction, magenta means proximity; neither is decorative.
class AppTheme {
  const AppTheme._();

  static ThemeData get light => AnAppTheme.light;

  static ThemeData get dark => AnAppTheme.dark;
}
