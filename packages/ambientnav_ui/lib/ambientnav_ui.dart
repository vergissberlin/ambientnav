/// AmbientNav brand layer: design tokens, theming and the brand atoms.
///
/// Mirrors `design-system/` for Flutter. Deliberately app-agnostic and
/// localisation-free so it carries no dependency on the app package — app copy
/// and domain widgets live in `app/lib/ui` instead.
library;

export 'atoms/an_badge.dart';
export 'atoms/an_button.dart';
export 'atoms/an_card.dart';
export 'atoms/an_light_strip.dart';
export 'theme/an_app_theme.dart';
export 'theme/an_brand_theme.dart';
export 'tokens/an_tokens.dart';
