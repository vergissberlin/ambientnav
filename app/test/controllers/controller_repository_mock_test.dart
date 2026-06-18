import 'package:ambientnav/core/security/pairing_exception.dart';
import 'package:ambientnav/features/controllers/data/mock/mock_controller_repository.dart';
import 'package:ambientnav/features/controllers/domain/entities/led_config.dart';
import 'package:ambientnav/features/controllers/domain/entities/ota_update.dart';
import 'package:ambientnav/features/controllers/domain/entities/sensor_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockControllerRepository repo;

  setUp(() => repo = MockControllerRepository());

  test('scan discovers the front and rear devices', () async {
    final emissions = await repo.scan().toList();
    expect(emissions.last.map((d) => d.name),
        containsAll(['AmbientNav-Front', 'AmbientNav-Rear']));
  });

  test('writing config is blocked until paired (least privilege)', () async {
    await repo.connect(MockControllerRepository.frontId);
    expect(
      () => repo.writeLedConfig(MockControllerRepository.frontId,
          const LedConfig(ledCount: 30, brightness: 100)),
      throwsA(isA<NotPairedException>()),
    );
  });

  test('LED config round-trips after pairing', () async {
    await repo.connect(MockControllerRepository.frontId);
    await repo.pair(MockControllerRepository.frontId, '123456');
    const cfg = LedConfig(ledCount: 30, brightness: 100, effect: 2);
    await repo.writeLedConfig(MockControllerRepository.frontId, cfg);
    final read = await repo.readLedConfig(MockControllerRepository.frontId);
    expect(read, cfg);
  });

  test('sensor config round-trips after pairing', () async {
    await repo.connect(MockControllerRepository.rearId);
    await repo.pair(MockControllerRepository.rearId, '123456');
    const cfg = SensorConfig(
      activeSensor: SensorType.left,
      calibrationOffsetCm: -3,
      maxRangeCm: 300,
    );
    await repo.writeSensorConfig(MockControllerRepository.rearId, cfg);
    final read = await repo.readSensorConfig(MockControllerRepository.rearId);
    expect(read, cfg);
  });

  test('wrong passkey is rejected', () async {
    await repo.connect(MockControllerRepository.frontId);
    expect(
      () => repo.pair(MockControllerRepository.frontId, '000000'),
      throwsA(isA<WrongPasskeyException>()),
    );
  });

  test('OTA stream terminates in done', () async {
    await repo.connect(MockControllerRepository.frontId);
    await repo.pair(MockControllerRepository.frontId, '123456');
    final firmware = List<int>.filled(200, 0xAB);
    final progress = await repo
        .startOta(MockControllerRepository.frontId, firmware)
        .toList();
    expect(progress.last.state, OtaState.done);
    expect(progress.last.bytesSent, 200);
    expect(progress.any((p) => p.state == OtaState.transferring), isTrue);
  });

  test('OTA blocked until paired', () async {
    await repo.connect(MockControllerRepository.frontId);
    expect(
      () => repo.startOta(MockControllerRepository.frontId, [1, 2, 3]).toList(),
      throwsA(isA<NotPairedException>()),
    );
  });

  test('telemetry stream reports voltage and rssi', () async {
    await repo.connect(MockControllerRepository.frontId);
    final first = await repo.telemetry(MockControllerRepository.frontId).first;
    expect(first.voltageVolts, greaterThan(3.0));
    expect(first.voltageVolts, lessThanOrEqualTo(4.2));
    expect(first.rssi, lessThan(0));
  });
}
