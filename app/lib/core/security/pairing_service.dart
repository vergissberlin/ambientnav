import '../../features/controllers/domain/repositories/controller_repository.dart';
import 'pairing_exception.dart';

/// Result of a pairing attempt.
enum PairingResult { success, wrongPasskey, invalidFormat, error }

/// Coordinates passkey-based BLE pairing/bonding before any mutating controller
/// operation is allowed. Validates the passkey format locally, then delegates
/// to the repository which triggers the OS-level LE Secure Connections bond.
class PairingService {
  PairingService(this._repository);

  final ControllerRepository _repository;

  /// A controller passkey is exactly 6 digits.
  static final RegExp _passkeyPattern = RegExp(r'^\d{6}$');

  static bool isValidPasskeyFormat(String passkey) =>
      _passkeyPattern.hasMatch(passkey);

  Future<PairingResult> pair(String deviceId, String passkey) async {
    if (!isValidPasskeyFormat(passkey)) {
      return PairingResult.invalidFormat;
    }
    try {
      await _repository.pair(deviceId, passkey);
      return PairingResult.success;
    } on WrongPasskeyException {
      return PairingResult.wrongPasskey;
    } catch (_) {
      return PairingResult.error;
    }
  }
}
