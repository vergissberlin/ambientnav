import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ambientnav/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dev/dev_settings.dart';
import '../../../core/theme/theme_controller.dart';

/// App settings: theme mode (dark/light/system) and voice guidance toggle.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(themeControllerProvider);
    final controller = ref.read(themeControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTab)),
      body: ListView(
        children: [
          ListTile(
            title: Text(l10n.theme),
            subtitle: Text(switch (mode) {
              ThemeMode.system => l10n.themeSystem,
              ThemeMode.light => l10n.themeLight,
              ThemeMode.dark => l10n.themeDark,
            }),
          ),
          SegmentedButton<ThemeMode>(
            key: const Key('themeSelector'),
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(l10n.themeSystem),
                icon: const Icon(Icons.brightness_auto),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(l10n.themeLight),
                icon: const Icon(Icons.light_mode),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(l10n.themeDark),
                icon: const Icon(Icons.dark_mode),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (s) => controller.setMode(s.first),
          ),
          if (kDebugMode) ...[
            const Divider(),
            ListTile(
              title: Text(l10n.developer),
              subtitle: Text(l10n.developerDesc),
            ),
            SwitchListTile(
              key: const Key('routeSimulationSwitch'),
              secondary: const Icon(Icons.route),
              title: Text(l10n.routeSimulation),
              subtitle: Text(l10n.routeSimulationDesc),
              value: ref.watch(simulationEnabledProvider),
              onChanged: (v) =>
                  ref.read(simulationEnabledProvider.notifier).setEnabled(v),
            ),
          ],
        ],
      ),
    );
  }
}
