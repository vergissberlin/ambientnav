import 'package:ambientnav_ui/ambientnav_ui.dart';
import 'package:flutter/material.dart';

import '../../features/navigation/domain/entities/maneuver.dart';

/// Banner showing the next maneuver icon, instruction and distance. Shared
/// visual used on the phone and (conceptually) the car heads.
class TurnByTurnPanel extends StatelessWidget {
  const TurnByTurnPanel({
    super.key,
    required this.maneuver,
    required this.distanceMeters,
  });

  final Maneuver? maneuver;
  final double distanceMeters;

  IconData _icon(ManeuverType type) => switch (type) {
    ManeuverType.turnLeft || ManeuverType.slightLeft => Icons.turn_left,
    ManeuverType.turnRight || ManeuverType.slightRight => Icons.turn_right,
    ManeuverType.uturn => Icons.u_turn_left,
    ManeuverType.roundabout => Icons.roundabout_right,
    ManeuverType.arrive => Icons.flag,
    ManeuverType.depart || ManeuverType.straight => Icons.straight,
    ManeuverType.newName => Icons.signpost,
  };

  String _distanceLabel() {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceMeters.round()} m';
  }

  @override
  Widget build(BuildContext context) {
    final m = maneuver;
    if (m == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final compact = MediaQuery.orientationOf(context) == Orientation.landscape;
    final outerPadding = EdgeInsets.fromLTRB(
      12,
      compact ? 4 : 12,
      12,
      compact ? 4 : 12,
    );
    final innerPadding = EdgeInsets.symmetric(
      horizontal: compact ? 10 : 16,
      vertical: compact ? 6 : 12,
    );
    final iconSize = compact ? 24.0 : 36.0;
    final instructionStyle = compact
        ? theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.0,
          )
        : theme.textTheme.titleMedium;
    final distanceStyle = compact
        ? theme.textTheme.labelLarge?.copyWith(height: 1.0)
        : theme.textTheme.titleMedium;
    // AnPanelAccent.staticAccent deliberately — this panel rebuilds on every
    // navigation distance tick, and pulse/scanline would stack extra motion
    // on top of MapLibre's own rendering on a panel that must stay glanceable
    // while driving.
    return Padding(
      padding: outerPadding,
      child: AnPanel(
        glow: AnCardGlow.cyan,
        accent: AnPanelAccent.staticAccent,
        padding: innerPadding,
        child: Row(
          children: [
            Icon(_icon(m.type), size: iconSize),
            SizedBox(width: compact ? 8 : 16),
            Expanded(
              child: Text(
                m.instruction,
                style: instructionStyle,
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: compact ? 8 : 12),
            Text(_distanceLabel(), style: distanceStyle),
          ],
        ),
      ),
    );
  }
}
