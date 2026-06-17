import 'package:ambientnav/features/controllers/data/ble/codecs/nav_codec.dart';
import 'package:ambientnav/features/controllers/domain/entities/nav_command.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NavCodec', () {
    test('encodes the documented 3-byte packets', () {
      // left, 120 m, left blinker
      expect(
        NavCodec.encode(const NavCommand(
          direction: NavDirection.left,
          distanceM: 120,
          blinker: Blinker.left,
        )),
        [0x01, 0x78, 0x01],
      );
      // right, 45 m, right blinker
      expect(
        NavCodec.encode(const NavCommand(
          direction: NavDirection.right,
          distanceM: 45,
          blinker: Blinker.right,
        )),
        [0x02, 0x2D, 0x02],
      );
      // straight, 255 m, off
      expect(
        NavCodec.encode(const NavCommand(
          direction: NavDirection.straight,
          distanceM: 255,
        )),
        [0x03, 0xFF, 0x00],
      );
    });

    test('caps distance at 255', () {
      final bytes = NavCodec.encode(
        const NavCommand(direction: NavDirection.none, distanceM: 9999),
      );
      expect(bytes[1], 255);
    });

    test('round-trips through decode', () {
      const cmd = NavCommand(
        direction: NavDirection.right,
        distanceM: 88,
        blinker: Blinker.hazard,
      );
      expect(NavCodec.decode(NavCodec.encode(cmd)), cmd);
    });

    test('rejects malformed length', () {
      expect(() => NavCodec.decode([0x01, 0x02]), throwsFormatException);
    });
  });
}
