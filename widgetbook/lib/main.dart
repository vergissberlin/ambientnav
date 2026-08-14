import 'package:ambientnav/core/l10n/app_localizations.dart';
import 'package:ambientnav_ui/ambientnav_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

import 'directories.dart';

void main() => runApp(const AmbientNavWidgetbook());

/// Component catalogue for the AmbientNav UI.
///
/// The brand themes are now the app's themes — `AppTheme` is a façade over
/// `AnAppTheme`, so listing both would show the same two entries twice.
class AmbientNavWidgetbook extends StatelessWidget {
  const AmbientNavWidgetbook({super.key});

  @override
  Widget build(BuildContext context) {
    // Dark first — the design system's "dark cockpit base" is the primary form.
    final dark = WidgetbookTheme(name: 'Dark', data: AnAppTheme.dark);

    return Widgetbook.material(
      directories: kDirectories,
      addons: [
        MaterialThemeAddon(
          themes: [
            dark,
            WidgetbookTheme(name: 'Light', data: AnAppTheme.light),
          ],
          initialTheme: dark,
        ),
        // Required, not optional: app/l10n.yaml sets nullable-getter: false, so
        // AppLocalizations.of(context) throws outright without these delegates.
        LocalizationAddon(
          locales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          initialLocale: const Locale('en'),
        ),
        ViewportAddon([
          Viewports.none,
          IosViewports.iPhoneSE,
          IosViewports.iPhone13,
          AndroidViewports.samsungGalaxyS20,
        ]),
        // Up to 2.0, where ControllerTile's three-widget subtitle Row is
        // expected to overflow — a bug class no current test covers.
        TextScaleAddon(min: 1.0, max: 2.0, divisions: 4),
        AlignmentAddon(),
        GridAddon(),
        InspectorAddon(),
      ],
    );
  }
}
