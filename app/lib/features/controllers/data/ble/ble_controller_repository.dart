import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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

/// Real [ControllerRepository] backed by `flutter_blue_plus`. Reuses the shared
/// codecs and UUIDs; keeps GATT plumbing thin (mapping/sequencing logic lives in
/// the unit-tested [BleMapping] / [OtaCodec]).
///
/// Used in production when `--dart-define=USE_MOCK=false`. Hardware behaviour is
/// not exercised in CI (the mock repository is the test/CI default).
class BleControllerRepository implements ControllerRepository {
  BleControllerRepository();

  final Map<String, BluetoothDevice> _devices = {};
  final Map<String, List<BluetoothService>> _services = {};

  @override
  Stream<List<ControllerInfo>> scan() {
    FlutterBluePlus.startScan(
      withServices: [Guid(BleUuids.navService)],
      timeout: const Duration(seconds: 15),
    );
    return FlutterBluePlus.scanResults.map((results) {
      final out = <ControllerInfo>[];
      for (final r in results) {
        final name = r.device.platformName;
        final advertised =
            r.advertisementData.serviceUuids.map((g) => g.str).toList();
        if (!BleMapping.isAmbientNavDevice(
          advertisedServiceUuids: advertised,
          name: name,
          navServiceUuid: BleUuids.navService,
        )) {
          continue;
        }
        final id = r.device.remoteId.str;
        _devices[id] = r.device;
        out.add(BleMapping.controllerInfoFrom(
          id: id,
          name: name,
          rssi: r.rssi,
        ));
      }
      return out;
    });
  }

  @override
  Future<void> stopScan() => FlutterBluePlus.stopScan();

  @override
  Future<void> connect(String id) async {
    final device = _device(id);
    await device.connect(timeout: const Duration(seconds: 15));
    _services[id] = await device.discoverServices();
  }

  @override
  Future<void> disconnect(String id) async {
    await _device(id).disconnect();
    _services.remove(id);
  }

  @override
  Future<void> pair(String id, String passkey) async {
    try {
      // On Android this triggers bonding; on iOS bonding is initiated by the OS
      // on first access to an encrypted characteristic. The 6-digit passkey is
      // entered in the OS pairing dialog.
      await _device(id).createBond();
    } catch (_) {
      throw const WrongPasskeyException();
    }
  }

  @override
  Stream<Telemetry> telemetry(String id) async* {
    final voltageChar = _char(id, BleUuids.voltageCharacteristic);
    await voltageChar.setNotifyValue(true);
    await for (final value in voltageChar.lastValueStream) {
      if (value.isEmpty) continue;
      final rssi = await _device(id).readRssi();
      yield Telemetry(
        voltageVolts: TelemetryCodec.decodeVoltage(value),
        rssi: rssi,
        timestamp: DateTime.now(),
      );
    }
  }

  @override
  Future<LedConfig> readLedConfig(String id) async {
    final value = await _char(id, BleUuids.ledConfigCharacteristic).read();
    return LedConfigCodec.decode(value);
  }

  @override
  Future<void> writeLedConfig(String id, LedConfig config) async {
    await _writeGuarded(
      _char(id, BleUuids.ledConfigCharacteristic),
      LedConfigCodec.encode(config),
    );
  }

  @override
  Future<SensorConfig> readSensorConfig(String id) async {
    final value = await _char(id, BleUuids.sensorConfigCharacteristic).read();
    return SensorConfigCodec.decode(value);
  }

  @override
  Future<void> writeSensorConfig(String id, SensorConfig config) async {
    await _writeGuarded(
      _char(id, BleUuids.sensorConfigCharacteristic),
      SensorConfigCodec.encode(config),
    );
  }

  @override
  Future<void> sendNavCommand(String id, NavCommand command) async {
    await _char(id, BleUuids.navCharacteristic)
        .write(NavCodec.encode(command), withoutResponse: true);
  }

  @override
  Stream<OtaProgress> startOta(String id, List<int> firmware) async* {
    final control = _char(id, BleUuids.otaControlCharacteristic);
    final data = _char(id, BleUuids.otaDataCharacteristic);
    final total = firmware.length;

    try {
      final crc = ByteCodec.crc32(firmware);
      await _writeGuarded(control, OtaCodec.encodeBegin(total, crc));

      // Size chunks to the negotiated MTU (minus ATT + our 2-byte seq header).
      final mtu = _device(id).mtuNow;
      final chunkSize = (mtu - 3 - 2).clamp(OtaCodec.defaultChunkSize, 512);
      final chunks = OtaCodec.chunk(firmware, chunkSize: chunkSize);

      var sent = 0;
      yield OtaProgress(
          state: OtaState.transferring, bytesSent: 0, totalBytes: total);
      for (final c in chunks) {
        await data.write(c, withoutResponse: true);
        sent += c.length - 2;
        yield OtaProgress(
          state: OtaState.transferring,
          bytesSent: sent.clamp(0, total),
          totalBytes: total,
        );
      }
      yield OtaProgress(
          state: OtaState.verifying, bytesSent: total, totalBytes: total);
      await control.write(OtaCodec.encodeControl(OtaOp.commit));
      yield OtaProgress(
          state: OtaState.done, bytesSent: total, totalBytes: total);
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

  BluetoothDevice _device(String id) {
    final d = _devices[id] ?? BluetoothDevice.fromId(id);
    return d;
  }

  BluetoothCharacteristic _char(String id, String charUuid) {
    final services = _services[id];
    if (services == null) {
      throw StateError('Device $id not connected / services not discovered');
    }
    final target = Guid(charUuid);
    for (final s in services) {
      for (final c in s.characteristics) {
        if (c.uuid == target) return c;
      }
    }
    throw StateError('Characteristic $charUuid not found on $id');
  }

  /// Wrap a write so a permission/encryption error surfaces as
  /// [NotPairedException] (the characteristic requires a bonded link).
  Future<void> _writeGuarded(
      BluetoothCharacteristic characteristic, List<int> value) async {
    try {
      await characteristic.write(value);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('auth') ||
          msg.contains('encrypt') ||
          msg.contains('bond') ||
          msg.contains('insufficient')) {
        throw NotPairedException(characteristic.remoteId.str);
      }
      rethrow;
    }
  }
}
