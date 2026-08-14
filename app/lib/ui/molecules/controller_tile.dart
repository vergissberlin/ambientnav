import 'package:ambientnav/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../features/controllers/domain/entities/controller_info.dart';
import '../../features/controllers/domain/entities/controller_role.dart';
import '../atoms/battery_gauge.dart';
import '../atoms/rssi_indicator.dart';

/// One discovered controller: signal, battery, pairing state and the primary
/// action — connect while disconnected, open the detail screen once connected.
///
/// Deliberately free of Riverpod and Navigator; the caller supplies both
/// callbacks. That is what makes the tile renderable in Widgetbook and testable
/// without provider overrides.
class ControllerTile extends StatelessWidget {
  const ControllerTile({
    super.key,
    required this.device,
    this.onConnect,
    this.onOpen,
  });

  final ControllerInfo device;

  /// Invoked by the "Connect" action shown while disconnected.
  final VoidCallback? onConnect;

  /// Invoked by the trailing chevron shown while connected.
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final roleLabel = device.role == ControllerRole.front
        ? l10n.roleFront
        : l10n.roleRear;

    return ListTile(
      leading: Icon(
        device.isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
        color: device.isConnected
            ? Theme.of(context).colorScheme.primary
            : null,
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
          ? IconButton(icon: const Icon(Icons.chevron_right), onPressed: onOpen)
          : TextButton(onPressed: onConnect, child: Text(l10n.connect)),
    );
  }
}
