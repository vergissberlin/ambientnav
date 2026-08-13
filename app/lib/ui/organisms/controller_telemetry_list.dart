import 'package:ambientnav/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../features/controllers/domain/entities/controller_info.dart';
import '../atoms/battery_gauge.dart';
import '../atoms/rssi_indicator.dart';

/// Live readings for one controller: signal, battery, firmware version and
/// pairing state.
///
/// Named `…List` rather than `…Tab` because it is a [ListView] of four tiles
/// and knows nothing about the tab bar it happens to sit in.
class ControllerTelemetryList extends StatelessWidget {
  const ControllerTelemetryList({super.key, required this.device});

  final ControllerInfo device;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          title: Text(l10n.signalStrength),
          trailing: RssiIndicator(
            quality: device.signalQuality,
            rssi: device.rssi,
          ),
        ),
        ListTile(
          title: Text(l10n.battery),
          trailing: BatteryGauge(voltage: device.voltage),
        ),
        ListTile(
          title: Text(l10n.firmwareVersion(device.firmwareVersion ?? '—')),
        ),
        ListTile(
          title: Text(device.isPaired ? l10n.paired : l10n.notPaired),
          leading: Icon(device.isPaired ? Icons.lock : Icons.lock_open),
        ),
      ],
    );
  }
}
