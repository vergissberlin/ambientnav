import 'dart:async';
import 'dart:typed_data';

import 'package:universal_ble/universal_ble.dart';

import '../../../../core/security/pairing_exception.dart';
import '../../../../core/utils/byte_codec.dart';
import '../../domain/entities/controller_info.dart';
import '../../domain/entities/led_config.dart';
import '../../domain/entities/nav_command.dart';
import '../../domain/entities/ota_update.dart';
import '../../domain/entities/sensor_config.dart';
import '../../domain/entities/telemetry.dart';
import '../../domain/repositories/controller_repository.dart';
import 'ble_mapping.dart';
import 'ble_uuids.dart';
import 'codecs/led_config_codec.dart';
import 'codecs/nav_codec.dart';
import 'codecs/ota_codec.dart';
import 'codecs/sensor_config_codec.dart';
import 'codecs/telemetry_codec.dart';

/// Real [ControllerRepository] backed by `universal_ble`. Reuses the shared
/// codecs and UUIDs; keeps GATT plumbing thin (mapping/sequencing logic lives in
/// the unit-tested [BleMapping] / [OtaCodec]).
///
/// Used in production when `--dart-define=USE_MOCK=false`. Hardware behaviour is
/// not exercised in CI (the mock repository is the test/CI default).
///
/// `universal_ble` exposes a flat API keyed by `(deviceId, service,
/// characteristic)` rather than an object graph, so there is no service cache to
/// maintain — [_serviceFor] maps each characteristic back to its service.
class BleControllerRepository implements ControllerRepository {
  BleControllerRepository() {
    // `onValueChange` is a single library-wide callback, so notifications for
    // every device and characteristic arrive here and are fanned out to the
    // per-subscription controllers created in [_notifications].
    UniversalBle.onValueChange = _routeNotification;
  }

  /// How long a scan runs before it stops itself. `universal_ble.startScan`
  /// takes no timeout, so it is enforced here.
  static const Duration scanTimeout = Duration(seconds: 15);

  /// Requested ATT MTU. The peripheral may negotiate down; the granted value is
  /// what [startOta] uses to size chunks.
  static const int _desiredMtu = 512;

  /// Fallback when a scan result carries no RSSI (`BleDevice.rssi` is nullable).
  /// -100 dBm maps to a signal quality of 0 in [ControllerInfo].
  static const int _unknownRssi = -100;

  final Map<String, ControllerInfo> _discovered = {};
  final Map<String, StreamController<Uint8List>> _notifications = {};

  Timer? _scanTimer;

  /// Resolve the service a characteristic lives on. Mirrors the grouping in
  /// [BleUuids]; throws rather than guessing so a new characteristic cannot be
  /// silently addressed against the wrong service.
  static String _serviceFor(String characteristic) {
    if (characteristic == BleUuids.navCharacteristic) {
      return BleUuids.navService;
    }
    if (characteristic == BleUuids.voltageCharacteristic ||
        characteristic == BleUuids.deviceInfoCharacteristic) {
      return BleUuids.telemetryService;
    }
    if (characteristic == BleUuids.ledConfigCharacteristic) {
      return BleUuids.ledConfigService;
    }
    if (characteristic == BleUuids.sensorConfigCharacteristic) {
      return BleUuids.sensorConfigService;
    }
    if (characteristic == BleUuids.otaControlCharacteristic ||
        characteristic == BleUuids.otaDataCharacteristic) {
      return BleUuids.otaService;
    }
    throw ArgumentError.value(
      characteristic,
      'characteristic',
      'no service mapping in BleUuids',
    );
  }

  static String _notificationKey(String deviceId, String characteristic) =>
      '$deviceId|${characteristic.toLowerCase()}';

  void _routeNotification(
    String deviceId,
    String characteristicId,
    Uint8List value,
    int? timestamp,
  ) {
    final controller =
        _notifications[_notificationKey(deviceId, characteristicId)];
    if (controller != null && !controller.isClosed) {
      controller.add(value);
    }
  }

  @override
  Stream<List<ControllerInfo>> scan() async* {
    _discovered.clear();

    await UniversalBle.startScan(
      scanFilter: ScanFilter(withServices: [BleUuids.navService]),
    );

    _scanTimer?.cancel();
    _scanTimer = Timer(scanTimeout, () => unawaited(stopScan()));

    await for (final device in UniversalBle.scanStream) {
      final name = device.name ?? '';
      if (!BleMapping.isAmbientNavDevice(
        advertisedServiceUuids: device.services,
        name: name,
        navServiceUuid: BleUuids.navService,
      )) {
        continue;
      }
      _discovered[device.deviceId] = BleMapping.controllerInfoFrom(
        id: device.deviceId,
        name: name,
        rssi: device.rssi ?? _unknownRssi,
      );
      yield List.unmodifiable(_discovered.values);
    }
  }

  @override
  Future<void> stopScan() async {
    _scanTimer?.cancel();
    _scanTimer = null;
    await UniversalBle.stopScan();
  }

  @override
  Future<void> connect(String id) async {
    await UniversalBle.connect(id, timeout: const Duration(seconds: 15));
    await UniversalBle.discoverServices(id);
    // Negotiate a larger MTU up front so OTA transfers are not stuck at the
    // 23-byte default. Peripherals that refuse simply keep the current value.
    try {
      await UniversalBle.requestMtu(id, _desiredMtu);
    } catch (_) {
      // Non-fatal: startOta re-reads the granted MTU and falls back to the
      // conservative chunk size.
    }
  }

  @override
  Future<void> disconnect(String id) async {
    for (final entry in _notifications.entries.toList()) {
      if (entry.key.startsWith('$id|')) {
        await entry.value.close();
        _notifications.remove(entry.key);
      }
    }
    await UniversalBle.disconnect(id);
  }

  @override
  Future<void> pair(String id, String passkey) async {
    // On Android this triggers bonding; on iOS bonding is initiated by the OS
    // on first access to an encrypted characteristic. The 6-digit passkey is
    // entered in the OS pairing dialog, so it is not passed to the stack here.
    try {
      await UniversalBle.pair(id);
    } catch (_) {
      throw const WrongPasskeyException();
    }
    // `pair` resolving is not proof of a bond on every platform — confirm.
    final paired = await UniversalBle.isPaired(id);
    if (paired == false) throw const WrongPasskeyException();
  }

  @override
  Stream<Telemetry> telemetry(String id) async* {
    final characteristic = BleUuids.voltageCharacteristic;
    final key = _notificationKey(id, characteristic);

    final controller = StreamController<Uint8List>.broadcast();
    await _notifications[key]?.close();
    _notifications[key] = controller;

    await UniversalBle.subscribeNotifications(
      id,
      _serviceFor(characteristic),
      characteristic,
    );

    try {
      await for (final value in controller.stream) {
        if (value.isEmpty) continue;
        yield Telemetry(
          voltageVolts: TelemetryCodec.decodeVoltage(value),
          rssi: await UniversalBle.readRssi(id),
          timestamp: DateTime.now(),
        );
      }
    } finally {
      _notifications.remove(key);
      await controller.close();
      // Best-effort: the link may already be gone when the listener detaches.
      try {
        await UniversalBle.unsubscribe(
          id,
          _serviceFor(characteristic),
          characteristic,
        );
      } catch (_) {
        // Ignored — nothing useful to do if the device is already away.
      }
    }
  }

  @override
  Future<LedConfig> readLedConfig(String id) async {
    final value = await _read(id, BleUuids.ledConfigCharacteristic);
    return LedConfigCodec.decode(value);
  }

  @override
  Future<void> writeLedConfig(String id, LedConfig config) {
    return _writeGuarded(
      id,
      BleUuids.ledConfigCharacteristic,
      LedConfigCodec.encode(config),
    );
  }

  @override
  Future<SensorConfig> readSensorConfig(String id) async {
    final value = await _read(id, BleUuids.sensorConfigCharacteristic);
    return SensorConfigCodec.decode(value);
  }

  @override
  Future<void> writeSensorConfig(String id, SensorConfig config) {
    return _writeGuarded(
      id,
      BleUuids.sensorConfigCharacteristic,
      SensorConfigCodec.encode(config),
    );
  }

  @override
  Future<void> sendNavCommand(String id, NavCommand command) {
    return UniversalBle.write(
      id,
      _serviceFor(BleUuids.navCharacteristic),
      BleUuids.navCharacteristic,
      NavCodec.encode(command),
      withoutResponse: true,
    );
  }

  @override
  Stream<OtaProgress> startOta(String id, List<int> firmware) async* {
    final total = firmware.length;

    try {
      final crc = ByteCodec.crc32(firmware);
      await _writeGuarded(
        id,
        BleUuids.otaControlCharacteristic,
        OtaCodec.encodeBegin(total, crc),
      );

      // Size chunks to the negotiated MTU (minus ATT + our 2-byte seq header).
      final mtu = await _negotiatedMtu(id);
      final chunkSize = (mtu - 3 - 2).clamp(OtaCodec.defaultChunkSize, 512);
      final chunks = OtaCodec.chunk(firmware, chunkSize: chunkSize);

      final dataService = _serviceFor(BleUuids.otaDataCharacteristic);
      var sent = 0;
      yield OtaProgress(
        state: OtaState.transferring,
        bytesSent: 0,
        totalBytes: total,
      );
      for (final c in chunks) {
        await UniversalBle.write(
          id,
          dataService,
          BleUuids.otaDataCharacteristic,
          c,
          withoutResponse: true,
        );
        sent += c.length - 2;
        yield OtaProgress(
          state: OtaState.transferring,
          bytesSent: sent.clamp(0, total),
          totalBytes: total,
        );
      }
      yield OtaProgress(
        state: OtaState.verifying,
        bytesSent: total,
        totalBytes: total,
      );
      await UniversalBle.write(
        id,
        _serviceFor(BleUuids.otaControlCharacteristic),
        BleUuids.otaControlCharacteristic,
        OtaCodec.encodeControl(OtaOp.commit),
      );
      yield OtaProgress(
        state: OtaState.done,
        bytesSent: total,
        totalBytes: total,
      );
    } on NotPairedException {
      rethrow;
    } catch (e) {
      yield OtaProgress(
        state: OtaState.failed,
        bytesSent: 0,
        totalBytes: total,
        error: e.toString(),
      );
    }
  }

  // --- helpers ---

  Future<Uint8List> _read(String id, String characteristic) {
    return UniversalBle.read(id, _serviceFor(characteristic), characteristic);
  }

  /// The MTU currently granted for [id], or the conservative default when the
  /// platform will not report one.
  Future<int> _negotiatedMtu(String id) async {
    try {
      return await UniversalBle.requestMtu(id, _desiredMtu);
    } catch (_) {
      // `OtaCodec.defaultChunkSize` already assumes the 23-byte ATT minimum;
      // returning it plus the headers keeps the clamp at that floor.
      return OtaCodec.defaultChunkSize + 3 + 2;
    }
  }

  /// Wrap a write so a permission/encryption error surfaces as
  /// [NotPairedException] (the characteristic requires a bonded link).
  Future<void> _writeGuarded(
    String id,
    String characteristic,
    Uint8List value,
  ) async {
    try {
      await UniversalBle.write(
        id,
        _serviceFor(characteristic),
        characteristic,
        value,
      );
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('auth') ||
          msg.contains('encrypt') ||
          msg.contains('bond') ||
          msg.contains('insufficient')) {
        throw NotPairedException(id);
      }
      rethrow;
    }
  }
}
