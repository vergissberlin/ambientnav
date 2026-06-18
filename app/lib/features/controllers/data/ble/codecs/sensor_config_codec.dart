import 'dart:typed_data';

import '../../../../../core/utils/byte_codec.dart';
import '../../../domain/entities/sensor_config.dart';

/// Wire format for the sensor-config characteristic (`…DEF8`), 5 bytes:
/// `[activeSensor(u8), calibOffsetCm(i16 LE), maxRangeCm(u16 LE)]`.
class SensorConfigCodec {
  const SensorConfigCodec._();

  static const int byteLength = 5;

  static Uint8List encode(SensorConfig cfg) {
    if (!cfg.isValid) {
      throw ArgumentError('SensorConfig out of range: $cfg');
    }
    final out = <int>[cfg.activeSensor.wireValue & 0xFF];
    ByteCodec.writeI16(out, cfg.calibrationOffsetCm);
    ByteCodec.writeU16(out, cfg.maxRangeCm);
    return Uint8List.fromList(out);
  }

  static SensorConfig decode(List<int> bytes) {
    if (bytes.length < byteLength) {
      throw const FormatException('Sensor config must be at least 5 bytes');
    }
    return SensorConfig(
      activeSensor: SensorType.fromWire(bytes[0]),
      calibrationOffsetCm: ByteCodec.i16(bytes, 1),
      maxRangeCm: ByteCodec.u16(bytes, 3),
    );
  }
}
