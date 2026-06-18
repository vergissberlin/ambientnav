import '../../../../../core/utils/byte_codec.dart';
import '../../../domain/entities/controller_role.dart';

/// Decodes the telemetry voltage characteristic (`…DEF3`): a `u16` of
/// millivolts, little-endian.
class TelemetryCodec {
  const TelemetryCodec._();

  /// Returns voltage in volts.
  static double decodeVoltage(List<int> bytes) {
    if (bytes.length < 2) {
      throw const FormatException('Voltage payload must be at least 2 bytes');
    }
    return ByteCodec.u16(bytes, 0) / 1000.0;
  }

  /// Encodes voltage (volts) back to the `u16` millivolt wire form.
  static List<int> encodeVoltage(double volts) {
    final mv = (volts * 1000).round().clamp(0, 65535);
    final out = <int>[];
    ByteCodec.writeU16(out, mv);
    return out;
  }
}

/// Parsed device-info characteristic (`…DEF4`): `[role(u8), fwVersion utf8…]`.
class DeviceInfo {
  const DeviceInfo({required this.role, required this.firmwareVersion});

  final ControllerRole role;
  final String firmwareVersion;
}

/// Decodes/encodes the device-info characteristic (`…DEF4`).
class DeviceInfoCodec {
  const DeviceInfoCodec._();

  static DeviceInfo decode(List<int> bytes) {
    if (bytes.isEmpty) {
      throw const FormatException('Device info payload is empty');
    }
    final role = ControllerRole.fromWire(bytes[0]);
    final version = String.fromCharCodes(bytes.sublist(1)).trim();
    return DeviceInfo(role: role, firmwareVersion: version);
  }

  static List<int> encode(DeviceInfo info) {
    return [info.role.wireValue, ...info.firmwareVersion.codeUnits];
  }
}
