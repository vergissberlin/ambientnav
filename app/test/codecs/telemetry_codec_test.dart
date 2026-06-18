import 'package:ambientnav/features/controllers/data/ble/codecs/telemetry_codec.dart';
import 'package:ambientnav/features/controllers/domain/entities/controller_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TelemetryCodec', () {
    test('decodes millivolts (LE) to volts', () {
      // 4050 mV = 0x0FD2 -> [0xD2, 0x0F]
      expect(TelemetryCodec.decodeVoltage([0xD2, 0x0F]), closeTo(4.05, 1e-9));
    });

    test('round-trips voltage', () {
      final encoded = TelemetryCodec.encodeVoltage(3.872);
      expect(TelemetryCodec.decodeVoltage(encoded), closeTo(3.872, 1e-3));
    });

    test('rejects short payload', () {
      expect(() => TelemetryCodec.decodeVoltage([0x01]), throwsFormatException);
    });
  });

  group('DeviceInfoCodec', () {
    test('decodes role + firmware version', () {
      final bytes = DeviceInfoCodec.encode(
        const DeviceInfo(role: ControllerRole.rear, firmwareVersion: '0.4.0'),
      );
      final info = DeviceInfoCodec.decode(bytes);
      expect(info.role, ControllerRole.rear);
      expect(info.firmwareVersion, '0.4.0');
    });
  });
}
