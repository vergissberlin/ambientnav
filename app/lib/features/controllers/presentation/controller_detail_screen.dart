import 'package:ambientnav/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/molecules/pairing_banner.dart';
import '../../../ui/organisms/controller_telemetry_list.dart';
import '../domain/entities/controller_info.dart';
import '../domain/entities/controller_role.dart';
import 'controllers_controller.dart';
import 'led_config_form.dart';
import 'ota_screen.dart';
import 'pairing_screen.dart';
import 'sensor_calibration_form.dart';

/// Per-controller detail: telemetry, LED config, sensor config and OTA.
/// Mutating tabs are gated behind a pairing banner until bonded.
class ControllerDetailScreen extends ConsumerWidget {
  const ControllerDetailScreen({super.key, required this.deviceId});

  final String deviceId;

  ControllerInfo? _device(WidgetRef ref) {
    final devices = ref.watch(controllersControllerProvider).devices;
    for (final d in devices) {
      if (d.id == deviceId) return d;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final device = _device(ref);
    if (device == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.noControllers)),
      );
    }
    final isRear = device.role == ControllerRole.rear;

    return DefaultTabController(
      length: isRear ? 4 : 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(device.name),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: l10n.signalStrength),
              Tab(text: l10n.ledConfig),
              if (isRear) Tab(text: l10n.sensorConfig),
              Tab(text: l10n.firmwareUpdate),
            ],
          ),
        ),
        body: Column(
          children: [
            if (!device.isPaired)
              PairingBanner(
                onPair: () => PairingDialog.show(context, deviceId),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  ControllerTelemetryList(device: device),
                  LedConfigForm(deviceId: deviceId),
                  if (isRear) SensorCalibrationForm(deviceId: deviceId),
                  OtaScreen(deviceId: deviceId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
