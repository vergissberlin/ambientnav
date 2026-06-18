/// Which ultrasonic sensor a rear controller should use for its readings.
enum SensorType {
  left,
  center,
  right,
  fused;

  int get wireValue => index;

  static SensorType fromWire(int value) {
    if (value < 0 || value >= SensorType.values.length) {
      return SensorType.fused;
    }
    return SensorType.values[value];
  }
}

/// Sensor selection + calibration for a rear controller.
///
/// Encoded onto the sensor-config characteristic (`…DEF8`).
class SensorConfig {
  const SensorConfig({
    required this.activeSensor,
    required this.calibrationOffsetCm,
    required this.maxRangeCm,
  });

  final SensorType activeSensor;

  /// Signed calibration offset in cm applied to raw distance readings
  /// (-32768 … 32767). Lets the user zero-out a mounting gap.
  final int calibrationOffsetCm;

  /// Maximum reported range in cm (0 … 65535); beyond it the firmware
  /// treats the reading as "no obstacle".
  final int maxRangeCm;

  bool get isValid =>
      calibrationOffsetCm >= -32768 &&
      calibrationOffsetCm <= 32767 &&
      maxRangeCm >= 0 &&
      maxRangeCm <= 65535;

  SensorConfig copyWith({
    SensorType? activeSensor,
    int? calibrationOffsetCm,
    int? maxRangeCm,
  }) {
    return SensorConfig(
      activeSensor: activeSensor ?? this.activeSensor,
      calibrationOffsetCm: calibrationOffsetCm ?? this.calibrationOffsetCm,
      maxRangeCm: maxRangeCm ?? this.maxRangeCm,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SensorConfig &&
      other.activeSensor == activeSensor &&
      other.calibrationOffsetCm == calibrationOffsetCm &&
      other.maxRangeCm == maxRangeCm;

  @override
  int get hashCode =>
      Object.hash(activeSensor, calibrationOffsetCm, maxRangeCm);
}
