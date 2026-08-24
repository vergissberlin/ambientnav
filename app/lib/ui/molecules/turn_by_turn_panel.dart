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
    // AnPanelAccent.staticAccent deliberately — this panel rebuilds on every
    // navigation distance tick, and pulse/scanline would stack extra motion
    // on top of MapLibre's own rendering on a panel that must stay glanceable
    // while driving.
    return Padding(
      padding: const EdgeInsets.all(12),
      child: AnPanel(
        glow: AnCardGlow.cyan,
        accent: AnPanelAccent.staticAccent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(_icon(m.type), size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                m.instruction,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _distanceLabel(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
