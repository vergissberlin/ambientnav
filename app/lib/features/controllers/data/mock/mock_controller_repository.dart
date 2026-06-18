import 'dart:async';
import 'dart:math';

import '../../../../core/security/pairing_exception.dart';
import '../../domain/entities/controller_info.dart';
import '../../domain/entities/controller_role.dart';
import '../../domain/entities/led_config.dart';
import '../../domain/entities/nav_command.dart';
import '../../domain/entities/ota_update.dart';
import '../../domain/entities/sensor_config.dart';
import '../../domain/entities/telemetry.dart';
import '../../domain/repositories/controller_repository.dart';
import '../ble/codecs/ota_codec.dart';

/// In-memory [ControllerRepository] used in development (`--dart-define=
/// USE_MOCK=true`) and in every unit/widget test, so the full app runs without
/// BLE hardware.
///
/// It simulates two devices (front + rear), drifting battery voltage, stores
/// config writes and echoes them back on read, enforces the pairing gate, and
/// streams a scripted OTA progress sequence.
class MockControllerRepository implements ControllerRepository {
  MockControllerRepository({Random? random, this.passkey = '123456'})
      : _random = random ?? Random(42);

  final Random _random;

  /// The passkey the mock will accept during [pair].
  final String passkey;

  static const String frontId = 'mock-front';
  static const String rearId = 'mock-rear';

  final Map<String, ControllerInfo> _devices = {
    frontId: const ControllerInfo(
      id: frontId,
      name: 'AmbientNav-Front',
      rssi: -55,
      voltage: 4.05,
      firmwareVersion: '0.4.0',
      role: ControllerRole.front,
    ),
    rearId: const ControllerInfo(
      id: rearId,
      name: 'AmbientNav-Rear',
      rssi: -72,
      voltage: 3.88,
      firmwareVersion: '0.4.0',
      role: ControllerRole.rear,
    ),
  };

  final Map<String, LedConfig> _ledConfigs = {
    frontId: const LedConfig(ledCount: 60, brightness: 128, effect: 0),
    rearId: const LedConfig(ledCount: 60, brightness: 128, effect: 1),
  };

  final Map<String, SensorConfig> _sensorConfigs = {
    rearId: const SensorConfig(
      activeSensor: SensorType.fused,
      calibrationOffsetCm: 0,
      maxRangeCm: 400,
    ),
  };

  @override
  Stream<List<ControllerInfo>> scan() async* {
    // Emit devices appearing over time, with jittering RSSI.
    yield [_devices[frontId]!];
    await Future<void>.delayed(const Duration(milliseconds: 300));
    yield _devices.values.toList();
  }

  @override
  Future<void> stopScan() async {}

  @override
  Future<void> connect(String id) async {
    _require(id);
    _devices[id] = _devices[id]!.copyWith(isConnected: true);
  }

  @override
  Future<void> disconnect(String id) async {
    _require(id);
    _devices[id] = _devices[id]!.copyWith(isConnected: false, isPaired: false);
  }

  @override
  Future<void> pair(String id, String enteredPasskey) async {
    _require(id);
    if (enteredPasskey != passkey) {
      throw const WrongPasskeyException();
    }
    _devices[id] = _devices[id]!.copyWith(isConnected: true, isPaired: true);
  }

  @override
  Stream<Telemetry> telemetry(String id) async* {
    _require(id);
    var voltage = _devices[id]!.voltage ?? 4.0;
    while (true) {
      // Battery slowly drains with small noise.
      voltage = (voltage - 0.002 + (_random.nextDouble() - 0.5) * 0.01)
          .clamp(3.0, 4.2);
      final rssi = -55 - _random.nextInt(25);
      _devices[id] = _devices[id]!.copyWith(voltage: voltage, rssi: rssi);
      yield Telemetry(
        voltageVolts: double.parse(voltage.toStringAsFixed(2)),
        rssi: rssi,
        timestamp: DateTime.now(),
      );
      await Future<void>.delayed(const Duration(seconds: 1));
    }
  }

  @override
  Future<LedConfig> readLedConfig(String id) async {
    _require(id);
    return _ledConfigs[id] ?? const LedConfig(ledCount: 60, brightness: 128);
  }

  @override
  Future<void> writeLedConfig(String id, LedConfig config) async {
    _requirePaired(id);
    if (!config.isValid) {
      throw ArgumentError('Invalid LED config');
    }
    _ledConfigs[id] = config;
  }

  @override
  Future<SensorConfig> readSensorConfig(String id) async {
    _require(id);
    return _sensorConfigs[id] ??
        const SensorConfig(
          activeSensor: SensorType.fused,
          calibrationOffsetCm: 0,
          maxRangeCm: 400,
        );
  }

  @override
  Future<void> writeSensorConfig(String id, SensorConfig config) async {
    _requirePaired(id);
    if (!config.isValid) {
      throw ArgumentError('Invalid sensor config');
    }
    _sensorConfigs[id] = config;
  }

  @override
  Future<void> sendNavCommand(String id, NavCommand command) async {
    _require(id);
    // Navigation commands are accepted on any connected link (matches the
    // existing open nav characteristic).
  }

  @override
  Stream<OtaProgress> startOta(String id, List<int> firmware) async* {
    _requirePaired(id);
    final total = firmware.length;
    final chunks = OtaCodec.chunk(firmware);
    var sent = 0;
    yield OtaProgress(
        state: OtaState.transferring, bytesSent: 0, totalBytes: total);
    for (final c in chunks) {
      await Future<void>.delayed(const Duration(milliseconds: 2));
      sent += c.length - 2; // minus 2-byte seq header
      yield OtaProgress(
        state: OtaState.transferring,
        bytesSent: sent.clamp(0, total),
        totalBytes: total,
      );
    }
    yield OtaProgress(
        state: OtaState.verifying, bytesSent: total, totalBytes: total);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    yield OtaProgress(
        state: OtaState.applying, bytesSent: total, totalBytes: total);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    yield OtaProgress(
        state: OtaState.done, bytesSent: total, totalBytes: total);
  }

  // --- helpers ---

  void _require(String id) {
    if (!_devices.containsKey(id)) {
      throw StateError('Unknown device $id');
    }
  }

  void _requirePaired(String id) {
    _require(id);
    if (!_devices[id]!.isPaired) {
      throw NotPairedException(id);
    }
  }
}
