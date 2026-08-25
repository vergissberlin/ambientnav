import 'package:ambientnav/core/l10n/app_localizations.dart';
import 'package:ambientnav_ui/ambientnav_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/molecules/controller_tile.dart';
import 'controller_detail_screen.dart';
import 'controllers_controller.dart';

/// Lists discovered controllers with live RSSI + battery, and lets the user
/// connect to one.
class ControllersListScreen extends ConsumerWidget {
  const ControllersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(controllersControllerProvider);
    final controller = ref.read(controllersControllerProvider.notifier);

    final appBar = AnAppBar(title: Text(l10n.controllersTab));
    final topInset =
        MediaQuery.paddingOf(context).top + appBar.preferredSize.height;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: appBar,
      // The outer HomeShell's `extendBody: true` grows this nested Scaffold's
      // available height down behind the glass bottom nav bar, so its default
      // FAB position would otherwise land underneath it — push it back up by
      // the inset extendBody adds to MediaQuery.padding.bottom.
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: FloatingActionButton.extended(
          onPressed: state.isScanning
              ? controller.stopScan
              : controller.startScan,
          icon: Icon(state.isScanning ? Icons.stop : Icons.bluetooth_searching),
          label: Text(
            state.isScanning ? l10n.scanning : l10n.scanForControllers,
          ),
        ),
      ),
      body: state.devices.isEmpty
          ? Padding(
              padding: EdgeInsets.only(top: topInset),
              child: Center(child: Text(l10n.noControllers)),
            )
          : ListView.builder(
              padding: EdgeInsets.only(top: topInset),
              itemCount: state.devices.length,
              itemBuilder: (context, i) {
                final d = state.devices[i];
                return ControllerTile(
                  device: d,
                  onConnect: () => controller.connect(d.id),
                  onOpen: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ControllerDetailScreen(deviceId: d.id),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
