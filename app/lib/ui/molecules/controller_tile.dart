import 'package:ambientnav/core/l10n/app_localizations.dart';
import 'package:ambientnav_ui/ambientnav_ui.dart';
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

    return AnPanel(
      glow: device.isConnected ? AnCardGlow.cyan : AnCardGlow.none,
      accent: AnPanelAccent.staticAccent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            device.isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
            color: device.isConnected
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${device.name} · $roleLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    RssiIndicator(
                      quality: device.signalQuality,
                      rssi: device.rssi,
                    ),
                    BatteryGauge(voltage: device.voltage),
                    if (device.isPaired) const Icon(Icons.lock, size: 14),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: device.isConnected
                ? IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: onOpen,
                  )
                : TextButton(onPressed: onConnect, child: Text(l10n.connect)),
          ),
        ],
      ),
    );
  }
}
