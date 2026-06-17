import 'package:ambientnav/core/theme/app_theme.dart';
import 'package:ambientnav/core/theme/theme_controller.dart';
import 'package:ambientnav/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

void main() {
  testWidgets('selecting dark mode switches the active theme brightness',
      (tester) async {
    // Use a Consumer so we can read the live ThemeMode from the app.
    await pumpApp(
      tester,
      Consumer(
        builder: (context, ref, _) {
          final mode = ref.watch(themeControllerProvider);
          return MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: mode,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SettingsScreen(),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    // Tap the "dark" segment of the theme selector.
    await tester.tap(find.byIcon(Icons.dark_mode));
    await tester.pumpAndSettle();

    final BuildContext ctx = tester.element(find.byType(SettingsScreen));
    expect(Theme.of(ctx).brightness, Brightness.dark);
  });
}
