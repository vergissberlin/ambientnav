import 'package:ambientnav/core/l10n/app_localizations.dart';
import 'package:ambientnav_ui/ambientnav_ui.dart';
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

  /// Wraps a tab's content in the cybernetic frame. Each tab body already
  /// carries its own `EdgeInsets.all(16)` via an inner [ListView], so the
  /// panel padding is zeroed here rather than left at [AnPanel]'s default
  /// 28px — stacking both would nearly triple the current 16px inset instead
  /// of just doubling it. This keeps the visible spacing identical to before
  /// this change while still drawing the corner brackets flush to the tab's
  /// edges.
  Widget _tabPanel(Widget child) {
    return AnPanel(
      accent: AnPanelAccent.staticAccent,
      padding: EdgeInsets.zero,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final device = _device(ref);
    if (device == null) {
      final appBar = AnAppBar();
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: appBar,
        body: Padding(
          padding: EdgeInsets.only(
            top:
                MediaQuery.paddingOf(context).top + appBar.preferredSize.height,
          ),
          child: Center(child: Text(l10n.noControllers)),
        ),
      );
    }
    final isRear = device.role == ControllerRole.rear;
    final appBar = AnAppBar(
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
    );

    return DefaultTabController(
      length: isRear ? 4 : 3,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: appBar,
        body: Padding(
          padding: EdgeInsets.only(
            top:
                MediaQuery.paddingOf(context).top + appBar.preferredSize.height,
          ),
          child: Column(
            children: [
              if (!device.isPaired)
                PairingBanner(
                  onPair: () => PairingDialog.show(context, deviceId),
                ),
              Expanded(
                child: TabBarView(
                  children: [
                    _tabPanel(ControllerTelemetryList(device: device)),
                    _tabPanel(LedConfigForm(deviceId: deviceId)),
                    if (isRear)
                      _tabPanel(SensorCalibrationForm(deviceId: deviceId)),
                    _tabPanel(OtaScreen(deviceId: deviceId)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
