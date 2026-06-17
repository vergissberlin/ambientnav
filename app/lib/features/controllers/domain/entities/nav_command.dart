/// Turn direction sent to the front controller.
enum NavDirection {
  none(0x00),
  left(0x01),
  right(0x02),
  straight(0x03);

  const NavDirection(this.wireValue);
  final int wireValue;

  static NavDirection fromWire(int value) {
    return NavDirection.values.firstWhere(
      (d) => d.wireValue == value,
      orElse: () => NavDirection.none,
    );
  }
}

/// Turn-signal / hazard state sent to the front controller.
enum Blinker {
  off(0x00),
  left(0x01),
  right(0x02),
  hazard(0x03);

  const Blinker(this.wireValue);
  final int wireValue;

  static Blinker fromWire(int value) {
    return Blinker.values.firstWhere(
      (b) => b.wireValue == value,
      orElse: () => Blinker.off,
    );
  }
}

/// The compact navigation command matching the existing 3-byte BLE packet
/// `[direction, distance_m, blinker]` written to characteristic `…DEF1`.
class NavCommand {
  const NavCommand({
    required this.direction,
    required this.distanceM,
    this.blinker = Blinker.off,
  });

  final NavDirection direction;

  /// Metres to the maneuver, capped at 255 on the wire.
  final int distanceM;
  final Blinker blinker;

  @override
  bool operator ==(Object other) =>
      other is NavCommand &&
      other.direction == direction &&
      other.distanceM == distanceM &&
      other.blinker == blinker;

  @override
  int get hashCode => Object.hash(direction, distanceM, blinker);
}
