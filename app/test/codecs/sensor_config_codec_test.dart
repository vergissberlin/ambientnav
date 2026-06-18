import 'package:ambientnav/features/controllers/data/ble/codecs/sensor_config_codec.dart';
import 'package:ambientnav/features/controllers/domain/entities/sensor_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SensorConfigCodec', () {
    test('encodes negative calibration offset (signed i16 LE)', () {
      final bytes = SensorConfigCodec.encode(
        const SensorConfig(
          activeSensor: SensorType.center,
          calibrationOffsetCm: -5,
          maxRangeCm: 400,
        ),
      );
      expect(bytes[0], SensorType.center.wireValue);
      // -5 as u16 = 0xFFFB -> [0xFB, 0xFF]
      expect(bytes.sublist(1, 3), [0xFB, 0xFF]);
      // 400 = 0x0190 -> [0x90, 0x01]
      expect(bytes.sublist(3, 5), [0x90, 0x01]);
    });

    test('round-trips with negative and positive offsets', () {
      for (final offset in [-32768, -100, 0, 250, 32767]) {
        final cfg = SensorConfig(
          activeSensor: SensorType.fused,
          calibrationOffsetCm: offset,
          maxRangeCm: 350,
        );
        expect(
          SensorConfigCodec.decode(SensorConfigCodec.encode(cfg)),
          cfg,
          reason: 'offset $offset',
        );
      }
    });

    test('rejects truncated payload', () {
      expect(() => SensorConfigCodec.decode([0, 1]), throwsFormatException);
    });
  });
}
