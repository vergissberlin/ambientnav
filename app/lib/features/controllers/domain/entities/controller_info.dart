import 'controller_role.dart';

/// A discovered / connected microcontroller and its latest known metadata.
///
/// [rssi] is read natively by the BLE central (the phone); [voltage] and
/// [firmwareVersion] arrive over the telemetry / device-info characteristics.
class ControllerInfo {
  const ControllerInfo({
    required this.id,
    required this.name,
    required this.rssi,
    this.voltage,
    this.firmwareVersion,
    this.role = ControllerRole.front,
    this.isConnected = false,
    this.isPaired = false,
  });

  /// Stable platform device identifier (iOS UUID / Android MAC).
  final String id;
  final String name;

  /// Received signal strength in dBm (typically -30 strong … -100 weak).
  final int rssi;

  /// Battery voltage in volts, or null if not yet reported.
  final double? voltage;
  final String? firmwareVersion;
  final ControllerRole role;
  final bool isConnected;

  /// Whether an encrypted/authenticated (bonded) link has been established.
  /// Config writes and OTA are only permitted once paired.
  final bool isPaired;

  /// Signal quality 0.0 (weak) … 1.0 (strong), derived from [rssi].
  double get signalQuality {
    const min = -100.0;
    const max = -50.0;
    final clamped = rssi.toDouble().clamp(min, max);
    return (clamped - min) / (max - min);
  }

  ControllerInfo copyWith({
    String? name,
    int? rssi,
    double? voltage,
    String? firmwareVersion,
    ControllerRole? role,
    bool? isConnected,
    bool? isPaired,
  }) {
    return ControllerInfo(
      id: id,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      voltage: voltage ?? this.voltage,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      role: role ?? this.role,
      isConnected: isConnected ?? this.isConnected,
      isPaired: isPaired ?? this.isPaired,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ControllerInfo &&
      other.id == id &&
      other.name == name &&
      other.rssi == rssi &&
      other.voltage == voltage &&
      other.firmwareVersion == firmwareVersion &&
      other.role == role &&
      other.isConnected == isConnected &&
      other.isPaired == isPaired;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        rssi,
        voltage,
        firmwareVersion,
        role,
        isConnected,
        isPaired,
      );
}
