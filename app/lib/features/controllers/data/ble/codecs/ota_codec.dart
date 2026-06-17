import 'dart:typed_data';

import '../../../../../core/utils/byte_codec.dart';

/// OTA control operations written to the OTA control characteristic (`…DEFA`).
enum OtaOp {
  begin(0x00),
  abort(0x01),
  commit(0x02);

  const OtaOp(this.wireValue);
  final int wireValue;
}

/// Framing for the OTA characteristics:
/// - control (`…DEFA`): `[op(u8), totalLen(u32 LE)]`
/// - data (`…DEFB`):    `[seq(u16 LE), chunk…]`
///
/// A CRC-32 of the full image is appended to the begin frame so the firmware
/// can verify integrity before committing (and rebooting).
class OtaCodec {
  const OtaCodec._();

  /// Maximum chunk payload; conservative default for a 23-byte ATT MTU
  /// (`MTU - 3` ATT header). Callers may raise this after MTU negotiation.
  static const int defaultChunkSize = 20;

  static Uint8List encodeBegin(int totalLen, int crc32) {
    final out = <int>[OtaOp.begin.wireValue];
    ByteCodec.writeU32(out, totalLen);
    ByteCodec.writeU32(out, crc32);
    return Uint8List.fromList(out);
  }

  static Uint8List encodeControl(OtaOp op) =>
      Uint8List.fromList([op.wireValue]);

  static Uint8List encodeDataChunk(int seq, List<int> chunk) {
    final out = <int>[];
    ByteCodec.writeU16(out, seq);
    out.addAll(chunk);
    return Uint8List.fromList(out);
  }

  /// Splits [firmware] into sequenced chunks of at most [chunkSize] bytes.
  static List<Uint8List> chunk(List<int> firmware,
      {int chunkSize = defaultChunkSize}) {
    final chunks = <Uint8List>[];
    var seq = 0;
    for (var i = 0; i < firmware.length; i += chunkSize) {
      final end =
          (i + chunkSize < firmware.length) ? i + chunkSize : firmware.length;
      chunks.add(encodeDataChunk(seq, firmware.sublist(i, end)));
      seq++;
    }
    return chunks;
  }
}
