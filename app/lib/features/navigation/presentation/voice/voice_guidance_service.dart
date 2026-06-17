import 'package:flutter_tts/flutter_tts.dart';

/// Speaks navigation instructions. Thin wrapper over [FlutterTts] so it can be
/// faked in tests (the engine is injected).
class VoiceGuidanceService {
  VoiceGuidanceService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;

  /// Whether spoken guidance is emitted.
  bool enabled = true;
  String _lastSpoken = '';

  /// Set the spoken language (BCP-47, e.g. `en-US`, `de-DE`).
  Future<void> setLanguage(String languageCode) async {
    await _tts.setLanguage(languageCode);
  }

  /// Speak [instruction], skipping immediate duplicates so a maneuver isn't
  /// repeated on every position update.
  Future<void> speak(String instruction) async {
    if (!enabled || instruction.isEmpty || instruction == _lastSpoken) {
      return;
    }
    _lastSpoken = instruction;
    await _tts.stop();
    await _tts.speak(instruction);
  }

  Future<void> stop() async {
    _lastSpoken = '';
    await _tts.stop();
  }
}
