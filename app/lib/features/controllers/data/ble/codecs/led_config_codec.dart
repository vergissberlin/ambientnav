import 'dart:typed_data';

import '../../../../../core/utils/byte_codec.dart';
import '../../../domain/entities/led_config.dart';

/// Wire format for the LED-config characteristic (`…DEF6`), 8 bytes:
/// `[ledCount(u16 LE), brightness(u8), effect(u8), p0, p1, p2, p3]`.
class LedConfigCodec {
  const LedConfigCodec._();

  static const int byteLength = 8;

  static Uint8List encode(LedConfig cfg) {
    if (!cfg.isValid) {
      throw ArgumentError('LedConfig out of range: $cfg');
    }
    final out = <int>[];
    ByteCodec.writeU16(out, cfg.ledCount);
    out.add(cfg.brightness & 0xFF);
    out.add(cfg.effect & 0xFF);
    out.addAll(cfg.effectParams.map((p) => p & 0xFF));
    return Uint8List.fromList(out);
  }

  static LedConfig decode(List<int> bytes) {
    if (bytes.length < byteLength) {
      throw const FormatException('LED config must be at least 8 bytes');
    }
    return LedConfig(
      ledCount: ByteCodec.u16(bytes, 0),
      brightness: bytes[2],
      effect: bytes[3],
      effectParams: [bytes[4], bytes[5], bytes[6], bytes[7]],
    );
  }
}
