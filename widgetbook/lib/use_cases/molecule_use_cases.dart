import 'package:ambientnav/features/controllers/domain/entities/controller_info.dart';
import 'package:ambientnav/features/controllers/domain/entities/controller_role.dart';
import 'package:ambientnav/features/controllers/domain/entities/ota_update.dart';
import 'package:ambientnav/ui/molecules/controller_tile.dart';
import 'package:ambientnav/ui/molecules/ota_progress_view.dart';
import 'package:ambientnav/ui/molecules/pairing_banner.dart';
import 'package:ambientnav/ui/organisms/controller_telemetry_list.dart';
import 'package:ambientnav_ui/ambientnav_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// Use cases for the composed app components in `app/lib/ui/`.
///
/// All four were private classes inside screen files until they were extracted,
/// which made them unreachable from both Widgetbook and widget tests. They now
/// take plain values and callbacks, so no ProviderScope is needed here.
List<WidgetbookNode> extractedMolecules() => [
  _controllerTile,
  _pairingBanner,
  _otaProgressView,
];

/// Composed of several molecules and driven by a whole domain entity.
List<WidgetbookNode> extractedOrganisms() => [_controllerTelemetryList];

/// Fixtures mirroring what MockControllerRepository scripts, so the catalogue
/// and the widget tests show the same devices.
const _front = ControllerInfo(
  id: 'mock-front',
  name: 'AmbientNav-Front',
  rssi: -55,
  voltage: 4.05,
  firmwareVersion: '0.5.0',
);

const _rearConnected = ControllerInfo(
  id: 'mock-rear',
  name: 'AmbientNav-Rear',
  rssi: -72,
  voltage: 3.88,
  firmwareVersion: '0.5.0',
  role: ControllerRole.rear,
  isConnected: true,
);

const _rearPaired = ControllerInfo(
  id: 'mock-rear-paired',
  name: 'AmbientNav-Rear',
  rssi: -91,
  voltage: 3.24,
  role: ControllerRole.rear,
  isConnected: true,
  isPaired: true,
);

// ── ControllerTile ───────────────────────────────────────────────────────────

final _controllerTile = WidgetbookComponent(
  name: 'ControllerTile',
  useCases: [
    WidgetbookUseCase(
      // Switch the locale addon to `de` here: roleFront/roleRear/connect all
      // change, which is the cheapest way to spot a missing translation.
      name: 'Discovered / connected / paired',
      builder: (context) => const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ControllerTile(device: _front),
          Divider(height: 1),
          ControllerTile(device: _rearConnected),
          Divider(height: 1),
          ControllerTile(device: _rearPaired),
        ],
      ),
    ),
    WidgetbookUseCase(
      name: 'Playground',
      builder: (context) => ControllerTile(
        device: ControllerInfo(
          id: 'knob',
          name: context.knobs.string(
            label: 'name',
            initialValue: 'AmbientNav-Front',
          ),
          rssi: context.knobs.int.slider(
            label: 'rssi (dBm)',
            initialValue: -60,
            min: -100,
            max: -30,
          ),
          voltage: context.knobs.doubleOrNull.slider(
            label: 'voltage (V)',
            initialValue: 3.9,
            min: 2.8,
            max: 4.3,
            precision: 2,
          ),
          role: context.knobs.object.segmented(
            label: 'role',
            options: ControllerRole.values,
            labelBuilder: (r) => r.name,
          ),
          isConnected: context.knobs.boolean(label: 'connected'),
          isPaired: context.knobs.boolean(label: 'paired'),
        ),
        onConnect: () {},
        onOpen: () {},
      ),
    ),
  ],
);

// ── PairingBanner ────────────────────────────────────────────────────────────

final _pairingBanner = WidgetbookComponent(
  name: 'PairingBanner',
  useCases: [
    WidgetbookUseCase(
      name: 'Not paired',
      builder: (context) => Align(
        alignment: Alignment.topCenter,
        child: PairingBanner(onPair: () {}),
      ),
    ),
  ],
);

// ── OtaProgressView ──────────────────────────────────────────────────────────

final _otaProgressView = WidgetbookComponent(
  name: 'OtaProgressView',
  useCases: [
    WidgetbookUseCase(
      // Every OtaState, including failure — previously only reachable by
      // unplugging a controller mid-transfer.
      name: 'Every state',
      builder: (context) {
        final brand = AnBrandTheme.of(context);
        const total = 262144;
        const cases = <(String, OtaProgress)>[
          ('idle (renders nothing)', OtaProgress.idle()),
          (
            'transferring',
            OtaProgress(
              state: OtaState.transferring,
              bytesSent: 96000,
              totalBytes: total,
            ),
          ),
          (
            'verifying',
            OtaProgress(
              state: OtaState.verifying,
              bytesSent: total,
              totalBytes: total,
            ),
          ),
          (
            'applying',
            OtaProgress(
              state: OtaState.applying,
              bytesSent: total,
              totalBytes: total,
            ),
          ),
          (
            'done',
            OtaProgress(
              state: OtaState.done,
              bytesSent: total,
              totalBytes: total,
            ),
          ),
          (
            'failed',
            OtaProgress(
              state: OtaState.failed,
              bytesSent: 96000,
              totalBytes: total,
              error: 'not paired',
            ),
          ),
        ];
        return ListView(
          padding: const EdgeInsets.all(AnSpace.s4),
          children: [
            for (final (label, progress) in cases) ...[
              Text(label, style: TextStyle(color: brand.text4, fontSize: 11)),
              const SizedBox(height: AnSpace.s2),
              OtaProgressView(progress: progress),
              const SizedBox(height: AnSpace.s5),
            ],
          ],
        );
      },
    ),
    WidgetbookUseCase(
      name: 'Playground',
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AnSpace.s4),
        child: OtaProgressView(
          progress: OtaProgress(
            state: context.knobs.object.dropdown(
              label: 'state',
              options: OtaState.values,
              labelBuilder: (s) => s.name,
            ),
            bytesSent: context.knobs.int.slider(
              label: 'bytes sent',
              initialValue: 96000,
              max: 262144,
            ),
            totalBytes: 262144,
            error: context.knobs.stringOrNull(
              label: 'error',
              initialValue: null,
            ),
          ),
        ),
      ),
    ),
  ],
);

// ── ControllerTelemetryList ──────────────────────────────────────────────────

final _controllerTelemetryList = WidgetbookComponent(
  name: 'ControllerTelemetryList',
  useCases: [
    WidgetbookUseCase(
      name: 'Paired front controller',
      builder: (context) => const ControllerTelemetryList(device: _front),
    ),
    WidgetbookUseCase(
      name: 'Weak signal, low battery, paired',
      builder: (context) => const ControllerTelemetryList(device: _rearPaired),
    ),
    WidgetbookUseCase(
      name: 'No telemetry yet',
      builder: (context) => const ControllerTelemetryList(
        device: ControllerInfo(
          id: 'fresh',
          name: 'AmbientNav-Front',
          rssi: -70,
        ),
      ),
    ),
  ],
);
