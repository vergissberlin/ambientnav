import 'package:ambientnav/features/controllers/data/ble/codecs/led_config_codec.dart';
import 'package:ambientnav/features/controllers/domain/entities/led_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LedConfigCodec', () {
    test('encodes ledCount little-endian', () {
      // 300 LEDs = 0x012C -> [0x2C, 0x01]
      final bytes = LedConfigCodec.encode(
        const LedConfig(ledCount: 300, brightness: 200, effect: 2),
      );
      expect(bytes.sublist(0, 2), [0x2C, 0x01]);
      expect(bytes[2], 200);
      expect(bytes[3], 2);
      expect(bytes.length, LedConfigCodec.byteLength);
    });

    test('round-trips a full config', () {
      const cfg = LedConfig(
        ledCount: 144,
        brightness: 64,
        effect: 3,
        effectParams: [10, 20, 30, 40],
      );
      expect(LedConfigCodec.decode(LedConfigCodec.encode(cfg)), cfg);
    });

    test('handles the max LED count', () {
      const cfg = LedConfig(ledCount: LedConfig.maxLeds, brightness: 255);
      final decoded = LedConfigCodec.decode(LedConfigCodec.encode(cfg));
      expect(decoded.ledCount, LedConfig.maxLeds);
    });

    test('rejects invalid config on encode', () {
      expect(
        () =>
            LedConfigCodec.encode(const LedConfig(ledCount: 0, brightness: 0)),
        throwsArgumentError,
      );
    });

    test('rejects truncated payload on decode', () {
      expect(() => LedConfigCodec.decode([1, 2, 3]), throwsFormatException);
    });
  });
}
