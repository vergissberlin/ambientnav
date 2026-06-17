import '../../../controllers/domain/entities/nav_command.dart';
import '../entities/maneuver.dart';

/// Converts the next [Maneuver] and the distance to it into the compact 3-byte
/// [NavCommand] the front controller understands.
///
/// Distance is quantized to 1-metre resolution and capped at 255 (the wire
/// limit), matching the firmware's NavAgent contract.
class ManeuverToBleCommand {
  const ManeuverToBleCommand();

  NavCommand call(Maneuver maneuver, double distanceToManeuverMeters,
      {Blinker blinker = Blinker.off}) {
    final distance = distanceToManeuverMeters.round().clamp(0, 255);
    return NavCommand(
      direction: _direction(maneuver.type),
      distanceM: distance,
      blinker: blinker,
    );
  }

  NavDirection _direction(ManeuverType type) {
    switch (type) {
      case ManeuverType.turnLeft:
      case ManeuverType.slightLeft:
        return NavDirection.left;
      case ManeuverType.turnRight:
      case ManeuverType.slightRight:
        return NavDirection.right;
      case ManeuverType.straight:
      case ManeuverType.depart:
        return NavDirection.straight;
      case ManeuverType.uturn:
      case ManeuverType.roundabout:
      case ManeuverType.arrive:
        return NavDirection.none;
    }
  }
}
