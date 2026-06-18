import 'package:flutter/material.dart';
import 'package:ambientnav/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/controller_info.dart';
import '../domain/entities/controller_role.dart';
import 'controller_detail_screen.dart';
import 'controllers_controller.dart';
import 'widgets/battery_gauge.dart';
import 'widgets/rssi_indicator.dart';

/// Lists discovered controllers with live RSSI + battery, and lets the user
/// connect to one.
class ControllersListScreen extends ConsumerWidget {
  const ControllersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(controllersControllerProvider);
    final controller = ref.read(controllersControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.controllersTab)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            state.isScanning ? controller.stopScan : controller.startScan,
        icon: Icon(state.isScanning ? Icons.stop : Icons.bluetooth_searching),
        label: Text(state.isScanning ? l10n.scanning : l10n.scanForControllers),
      ),
      body: state.devices.isEmpty
          ? Center(child: Text(l10n.noControllers))
          : ListView.builder(
              itemCount: state.devices.length,
              itemBuilder: (context, i) {
                final d = state.devices[i];
                return _ControllerTile(device: d);
              },
            ),
    );
  }
}

class _ControllerTile extends ConsumerWidget {
  const _ControllerTile({required this.device});

  final ControllerInfo device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(controllersControllerProvider.notifier);
    final roleLabel =
        device.role == ControllerRole.front ? l10n.roleFront : l10n.roleRear;

    return ListTile(
      leading: Icon(
        device.isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
        color:
            device.isConnected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text('${device.name} · $roleLabel'),
      subtitle: Row(
        children: [
          RssiIndicator(quality: device.signalQuality, rssi: device.rssi),
          const SizedBox(width: 12),
          BatteryGauge(voltage: device.voltage),
          if (device.isPaired) ...[
            const SizedBox(width: 8),
            const Icon(Icons.lock, size: 14),
          ],
        ],
      ),
      trailing: device.isConnected
          ? IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ControllerDetailScreen(deviceId: device.id),
                ),
              ),
            )
          : TextButton(
              onPressed: () => controller.connect(device.id),
              child: Text(l10n.connect),
            ),
    );
  }
}
