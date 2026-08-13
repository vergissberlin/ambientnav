import 'package:ambientnav/features/controllers/presentation/widgets/battery_gauge.dart';
import 'package:ambientnav/features/controllers/presentation/widgets/rssi_indicator.dart';
import 'package:ambientnav/features/navigation/domain/entities/maneuver.dart';
import 'package:ambientnav/features/navigation/presentation/turn_by_turn_panel.dart';
import 'package:ambientnav_ui/ambientnav_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// Use cases for the app's own presentation widgets.
///
/// Limited to the ones that render from plain values with no Riverpod or
/// platform dependency. The provider-bound screens (LedConfigForm,
/// ControllersListScreen, …) need a ProviderScope wrapper with an overridden
/// localStoreProvider and a connected MockControllerRepository — that comes
/// with the component extraction work, not here.
List<WidgetbookNode> appFolder() => [
  WidgetbookFolder(
    name: 'App',
    children: [_batteryGauge, _rssiIndicator, _turnByTurnPanel],
  ),
];

Widget _stage(BuildContext context, Widget child) {
  return Center(
    child: Padding(padding: const EdgeInsets.all(AnSpace.s5), child: child),
  );
}

// ── BatteryGauge ─────────────────────────────────────────────────────────────

final _batteryGauge = WidgetbookComponent(
  name: 'BatteryGauge',
  useCases: [
    WidgetbookUseCase(
      // Values chosen to land on the icon tiers (0.66 / 0.33) and the colour
      // tiers (0.5 / 0.2) across the 3.0–4.2 V Li-ion range.
      name: 'States',
      builder: (context) => _stage(
        context,
        const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AnSpace.s3,
          children: [
            BatteryGauge(voltage: 4.2), // full
            BatteryGauge(voltage: 3.9), // ~75%
            BatteryGauge(voltage: 3.5), // ~42% — orange
            BatteryGauge(voltage: 3.1), // ~8%  — red
            BatteryGauge(voltage: null), // unknown — em dash
          ],
        ),
      ),
    ),
    WidgetbookUseCase(
      name: 'Playground',
      builder: (context) => _stage(
        context,
        BatteryGauge(
          voltage: context.knobs.doubleOrNull.slider(
            label: 'voltage (V)',
            initialValue: 3.9,
            min: 2.8,
            max: 4.3,
            divisions: 30,
            precision: 2,
          ),
        ),
      ),
    ),
  ],
);

// ── RssiIndicator ────────────────────────────────────────────────────────────

final _rssiIndicator = WidgetbookComponent(
  name: 'RssiIndicator',
  useCases: [
    WidgetbookUseCase(
      name: 'Signal quality',
      builder: (context) => _stage(
        context,
        const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AnSpace.s3,
          children: [
            RssiIndicator(quality: 1.0, rssi: -50),
            RssiIndicator(quality: 0.75, rssi: -62),
            RssiIndicator(quality: 0.4, rssi: -80), // orange below 0.5
            RssiIndicator(quality: 0.1, rssi: -95), // red below 0.25
            RssiIndicator(quality: 0.6), // no dBm label
          ],
        ),
      ),
    ),
    WidgetbookUseCase(
      name: 'Playground',
      builder: (context) => _stage(
        context,
        RssiIndicator(
          quality: context.knobs.double.slider(
            label: 'quality',
            initialValue: 0.7,
            max: 1,
            divisions: 20,
            precision: 2,
          ),
          rssi: context.knobs.intOrNull.slider(
            label: 'rssi (dBm)',
            initialValue: -60,
            min: -100,
            max: -30,
          ),
        ),
      ),
    ),
  ],
);

// ── TurnByTurnPanel ──────────────────────────────────────────────────────────

Maneuver _maneuver(ManeuverType type, String instruction) => Maneuver(
  type: type,
  instruction: instruction,
  distanceMeters: 120,
  latitude: 51.3397,
  longitude: 12.3731,
);

final _turnByTurnPanel = WidgetbookComponent(
  name: 'TurnByTurnPanel',
  useCases: [
    WidgetbookUseCase(
      name: 'Every maneuver type',
      builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.all(AnSpace.s4),
        child: Column(
          spacing: AnSpace.s2,
          children: [
            for (final type in ManeuverType.values)
              TurnByTurnPanel(
                maneuver: _maneuver(type, 'Instruction for ${type.name}'),
                distanceMeters: 120,
              ),
          ],
        ),
      ),
    ),
    WidgetbookUseCase(
      // Crosses the 1000 m boundary where the label switches from m to km, and
      // shows the null case, which collapses to SizedBox.shrink().
      name: 'Distance formatting',
      builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.all(AnSpace.s4),
        child: Column(
          spacing: AnSpace.s2,
          children: [
            TurnByTurnPanel(
              maneuver: _maneuver(
                ManeuverType.turnLeft,
                'Turn left onto Karl-Liebknecht-Straße',
              ),
              distanceMeters: 45,
            ),
            TurnByTurnPanel(
              maneuver: _maneuver(ManeuverType.turnRight, 'Turn right'),
              distanceMeters: 999,
            ),
            TurnByTurnPanel(
              maneuver: _maneuver(ManeuverType.straight, 'Continue straight'),
              distanceMeters: 1000,
            ),
            TurnByTurnPanel(
              maneuver: _maneuver(
                ManeuverType.roundabout,
                'At the roundabout, take the third exit onto a road with a very '
                'long name that has to be truncated after two lines',
              ),
              distanceMeters: 12500,
            ),
            const TurnByTurnPanel(maneuver: null, distanceMeters: 0),
          ],
        ),
      ),
    ),
    WidgetbookUseCase(
      name: 'Playground',
      builder: (context) => _stage(
        context,
        TurnByTurnPanel(
          maneuver: _maneuver(
            context.knobs.object.dropdown(
              label: 'type',
              options: ManeuverType.values,
              labelBuilder: (t) => t.name,
            ),
            context.knobs.string(
              label: 'instruction',
              initialValue: 'Turn left onto Karl-Liebknecht-Straße',
            ),
          ),
          distanceMeters: context.knobs.double.slider(
            label: 'distance (m)',
            initialValue: 120,
            max: 15000,
            divisions: 150,
            precision: 0,
          ),
        ),
      ),
    ),
  ],
);
