import 'package:ambientnav/core/utils/byte_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ByteCodec', () {
    test('u16 little-endian read/write', () {
      final out = <int>[];
      ByteCodec.writeU16(out, 0x1234);
      expect(out, [0x34, 0x12]);
      expect(ByteCodec.u16(out, 0), 0x1234);
    });

    test('u32 little-endian read/write', () {
      final out = <int>[];
      ByteCodec.writeU32(out, 0xDEADBEEF);
      expect(out, [0xEF, 0xBE, 0xAD, 0xDE]);
      expect(ByteCodec.u32(out, 0), 0xDEADBEEF);
    });

    test('i16 signed round-trip', () {
      for (final v in [-32768, -1, 0, 1, 32767]) {
        final out = <int>[];
        ByteCodec.writeI16(out, v);
        expect(ByteCodec.i16(out, 0), v, reason: 'value $v');
      }
    });
  });
}
