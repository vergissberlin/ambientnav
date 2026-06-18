import 'dart:typed_data';

import '../../../domain/entities/nav_command.dart';

/// Encodes/decodes the existing 3-byte navigation packet:
/// `[direction, distance_m, blinker]` (characteristic `…DEF1`).
class NavCodec {
  const NavCodec._();

  static Uint8List encode(NavCommand cmd) {
    final distance = cmd.distanceM.clamp(0, 255);
    return Uint8List.fromList([
      cmd.direction.wireValue,
      distance,
      cmd.blinker.wireValue,
    ]);
  }

  static NavCommand decode(List<int> bytes) {
    if (bytes.length != 3) {
      throw const FormatException('Nav packet must be exactly 3 bytes');
    }
    return NavCommand(
      direction: NavDirection.fromWire(bytes[0]),
      distanceM: bytes[1],
      blinker: Blinker.fromWire(bytes[2]),
    );
  }
}
