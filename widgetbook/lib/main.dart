import 'package:ambientnav/core/l10n/app_localizations.dart';
import 'package:ambientnav/core/theme/app_theme.dart';
import 'package:ambientnav_ui/ambientnav_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

import 'directories.dart';

void main() => runApp(const AmbientNavWidgetbook());

/// Component catalogue for the AmbientNav UI.
///
/// Lists both the brand themes and the currently shipped amber themes, so the
/// palette migration can be reviewed side by side before it lands in
/// `app/lib/core/theme/app_theme.dart`.
class AmbientNavWidgetbook extends StatelessWidget {
  const AmbientNavWidgetbook({super.key});

  @override
  Widget build(BuildContext context) {
    final brandDark = WidgetbookTheme(
      name: 'Brand Dark',
      data: AnAppTheme.dark,
    );

    return Widgetbook.material(
      directories: kDirectories,
      addons: [
        MaterialThemeAddon(
          themes: [
            brandDark,
            WidgetbookTheme(name: 'Brand Light', data: AnAppTheme.light),
            WidgetbookTheme(name: 'App Dark (shipped)', data: AppTheme.dark),
            WidgetbookTheme(name: 'App Light (shipped)', data: AppTheme.light),
          ],
          initialTheme: brandDark,
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
