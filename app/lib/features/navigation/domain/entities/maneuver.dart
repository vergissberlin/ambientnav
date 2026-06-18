/// Abstract maneuver type independent of the routing backend.
enum ManeuverType {
  depart,
  turnLeft,
  turnRight,
  slightLeft,
  slightRight,
  straight,
  uturn,
  roundabout,
  arrive;
}

/// A single instruction along a route.
class Maneuver {
  const Maneuver({
    required this.type,
    required this.instruction,
    required this.distanceMeters,
    required this.latitude,
    required this.longitude,
  });

  final ManeuverType type;
  final String instruction;

  /// Distance from the previous maneuver (or route start) in metres.
  final double distanceMeters;
  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      other is Maneuver &&
      other.type == type &&
      other.instruction == instruction &&
      other.distanceMeters == distanceMeters &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode =>
      Object.hash(type, instruction, distanceMeters, latitude, longitude);
}
