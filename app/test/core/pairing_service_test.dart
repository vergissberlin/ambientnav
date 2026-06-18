import 'package:ambientnav/core/security/pairing_service.dart';
import 'package:ambientnav/features/controllers/data/mock/mock_controller_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PairingService', () {
    late PairingService service;

    setUp(() {
      service = PairingService(MockControllerRepository());
    });

    test('validates passkey format', () {
      expect(PairingService.isValidPasskeyFormat('123456'), isTrue);
      expect(PairingService.isValidPasskeyFormat('12345'), isFalse);
      expect(PairingService.isValidPasskeyFormat('abcdef'), isFalse);
      expect(PairingService.isValidPasskeyFormat('1234567'), isFalse);
    });

    test('rejects malformed passkey without contacting the device', () async {
      final result =
          await service.pair(MockControllerRepository.frontId, 'abc');
      expect(result, PairingResult.invalidFormat);
    });

    test('succeeds with the correct passkey', () async {
      final result =
          await service.pair(MockControllerRepository.frontId, '123456');
      expect(result, PairingResult.success);
    });

    test('reports wrong passkey', () async {
      final result =
          await service.pair(MockControllerRepository.frontId, '999999');
      expect(result, PairingResult.wrongPasskey);
    });
  });
}
