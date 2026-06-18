import 'package:ambientnav/features/controllers/data/ble/ble_mapping.dart';
import 'package:ambientnav/features/controllers/data/ble/ble_uuids.dart';
import 'package:ambientnav/features/controllers/domain/entities/controller_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BleMapping.isAmbientNavDevice', () {
    test('matches when the nav service is advertised', () {
      expect(
        BleMapping.isAmbientNavDevice(
          advertisedServiceUuids: [BleUuids.navService.toUpperCase()],
          name: 'Unknown',
          navServiceUuid: BleUuids.navService,
        ),
        isTrue,
      );
    });

    test('matches by name prefix when service is absent', () {
      expect(
        BleMapping.isAmbientNavDevice(
          advertisedServiceUuids: const [],
          name: 'AmbientNav-Front',
          navServiceUuid: BleUuids.navService,
        ),
        isTrue,
      );
    });

    test('ignores unrelated devices', () {
      expect(
        BleMapping.isAmbientNavDevice(
          advertisedServiceUuids: const [
            '0000180f-0000-1000-8000-00805f9b34fb'
          ],
          name: 'SomeHeartRateMonitor',
          navServiceUuid: BleUuids.navService,
        ),
        isFalse,
      );
    });
  });

  group('BleMapping.roleFromName / controllerInfoFrom', () {
    test('infers rear vs front from the name', () {
      expect(BleMapping.roleFromName('AmbientNav-Rear'), ControllerRole.rear);
      expect(BleMapping.roleFromName('AmbientNav-Front'), ControllerRole.front);
    });

    test('builds ControllerInfo with a fallback name', () {
      final info =
          BleMapping.controllerInfoFrom(id: 'AA:BB', name: '', rssi: -60);
      expect(info.id, 'AA:BB');
      expect(info.name, 'AmbientNav');
      expect(info.rssi, -60);
      expect(info.role, ControllerRole.front);
    });
  });
}
