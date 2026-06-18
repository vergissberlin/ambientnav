/// Thrown when a mutating controller operation (config write, OTA) is attempted
/// over a link that is not yet bonded/paired.
///
/// Enforces the least-privilege rule: read-only telemetry is open, but every
/// mutating action requires an encrypted, authenticated (bonded) link.
class NotPairedException implements Exception {
  const NotPairedException(this.deviceId);
  final String deviceId;

  @override
  String toString() => 'NotPairedException: device $deviceId is not paired';
}

/// Thrown when the user-entered passkey is rejected during pairing.
class WrongPasskeyException implements Exception {
  const WrongPasskeyException();

  @override
  String toString() => 'WrongPasskeyException: passkey rejected';
}
