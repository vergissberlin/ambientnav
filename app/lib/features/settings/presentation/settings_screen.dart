import 'package:ambientnav_ui/ambientnav_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ambientnav/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dev/dev_settings.dart';
import '../../../core/permissions/permission_service.dart';
import '../../../core/settings/camera_background_settings.dart';
import '../../../core/theme/theme_controller.dart';

/// App settings: theme mode (dark/light/system) and the camera navigation
/// background toggle.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(themeControllerProvider);
    final controller = ref.read(themeControllerProvider.notifier);
    final cameraBackgroundEnabled = ref.watch(cameraBackgroundEnabledProvider);
    final cameraPermissionDenied = ref.watch(
      cameraBackgroundPermissionDeniedProvider,
    );

    final appBar = AnAppBar(title: Text(l10n.settingsTab));
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: appBar,
      body: ListView(
        padding: EdgeInsets.only(
          top: MediaQuery.paddingOf(context).top + appBar.preferredSize.height,
        ),
        children: [
          ListTile(
            title: Text(l10n.theme),
            subtitle: Text(switch (mode) {
              ThemeMode.system => l10n.themeSystem,
              ThemeMode.light => l10n.themeLight,
              ThemeMode.dark => l10n.themeDark,
            }),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AnSpace.s4),
            child: SegmentedButton<ThemeMode>(
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
          ),
          const Divider(),
          SwitchListTile(
            key: const Key('cameraNavBackgroundSwitch'),
            secondary: const Icon(Icons.camera_alt_outlined),
            title: Text(l10n.cameraNavBackground),
            subtitle: Text(
              cameraPermissionDenied
                  ? l10n.cameraNavBackgroundPermissionDenied
                  : l10n.cameraNavBackgroundDesc,
            ),
            value: cameraBackgroundEnabled,
            onChanged: (v) async {
              if (!v) {
                ref
                    .read(cameraBackgroundEnabledProvider.notifier)
                    .setEnabled(false);
                return;
              }
              final granted = await const PermissionService()
                  .ensureCameraPermission();
              final deniedNotifier = ref.read(
                cameraBackgroundPermissionDeniedProvider.notifier,
              );
              deniedNotifier.state = !granted;
              if (granted) {
                ref
                    .read(cameraBackgroundEnabledProvider.notifier)
                    .setEnabled(true);
              }
            },
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
