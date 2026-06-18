/// Lifecycle of an over-the-air firmware update.
enum OtaState {
  idle,
  transferring,
  verifying,
  applying,
  done,
  failed,
}

/// Progress of an OTA transfer, streamed by `ControllerRepository.startOta`.
class OtaProgress {
  const OtaProgress({
    required this.state,
    required this.bytesSent,
    required this.totalBytes,
    this.error,
  });

  const OtaProgress.idle()
      : state = OtaState.idle,
        bytesSent = 0,
        totalBytes = 0,
        error = null;

  final OtaState state;
  final int bytesSent;
  final int totalBytes;
  final String? error;

  /// Fraction transferred 0.0 … 1.0.
  double get fraction =>
      totalBytes == 0 ? 0 : (bytesSent / totalBytes).clamp(0.0, 1.0);

  bool get isTerminal => state == OtaState.done || state == OtaState.failed;

  @override
  bool operator ==(Object other) =>
      other is OtaProgress &&
      other.state == state &&
      other.bytesSent == bytesSent &&
      other.totalBytes == totalBytes &&
      other.error == error;

  @override
  int get hashCode => Object.hash(state, bytesSent, totalBytes, error);
}
