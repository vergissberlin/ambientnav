import 'package:ambientnav/core/utils/byte_codec.dart';
import 'package:ambientnav/features/controllers/data/ble/codecs/ota_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OtaCodec', () {
    test('begin frame carries total length and CRC (LE)', () {
      final frame = OtaCodec.encodeBegin(0x01020304, 0xAABBCCDD);
      expect(frame[0], OtaOp.begin.wireValue);
      expect(frame.sublist(1, 5), [0x04, 0x03, 0x02, 0x01]);
      expect(frame.sublist(5, 9), [0xDD, 0xCC, 0xBB, 0xAA]);
    });

    test('chunks firmware into sequenced frames', () {
      final firmware = List<int>.generate(50, (i) => i);
      final chunks = OtaCodec.chunk(firmware, chunkSize: 20);
      expect(chunks.length, 3); // 20 + 20 + 10
      // Each frame prefixed with a 2-byte sequence number.
      expect(ByteCodec.u16(chunks[0], 0), 0);
      expect(ByteCodec.u16(chunks[1], 0), 1);
      expect(ByteCodec.u16(chunks[2], 0), 2);
      // Reassemble payloads and compare to source.
      final reassembled = <int>[];
      for (final c in chunks) {
        reassembled.addAll(c.sublist(2));
      }
      expect(reassembled, firmware);
    });

    test('CRC-32 matches a known IEEE vector', () {
      // CRC-32 of "123456789" is 0xCBF43926.
      final crc = ByteCodec.crc32('123456789'.codeUnits);
      expect(crc, 0xCBF43926);
    });
  });
}
