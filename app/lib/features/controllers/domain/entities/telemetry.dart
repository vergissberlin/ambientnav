/// Live telemetry pushed by a controller (voltage) combined with the
/// natively-read [rssi] of the link.
class Telemetry {
  const Telemetry({
    required this.voltageVolts,
    required this.rssi,
    required this.timestamp,
  });

  /// Supply / battery voltage in volts.
  final double voltageVolts;

  /// Link RSSI in dBm.
  final int rssi;
  final DateTime timestamp;

  @override
  bool operator ==(Object other) =>
      other is Telemetry &&
      other.voltageVolts == voltageVolts &&
      other.rssi == rssi &&
      other.timestamp == timestamp;

  @override
  int get hashCode => Object.hash(voltageVolts, rssi, timestamp);
}
