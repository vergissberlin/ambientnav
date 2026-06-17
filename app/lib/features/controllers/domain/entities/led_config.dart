/// Configuration of a WS2812B LED strip attached to a controller.
///
/// Encoded onto the LED-config characteristic (`…DEF6`). See
/// `data/ble/codecs/led_config_codec.dart` for the wire format.
class LedConfig {
  const LedConfig({
    required this.ledCount,
    required this.brightness,
    this.effect = 0,
    this.effectParams = const [0, 0, 0, 0],
  });

  /// Number of LEDs on the strip (1 … 65535).
  final int ledCount;

  /// Overall brightness 0 … 255.
  final int brightness;

  /// Effect identifier (firmware-defined catalogue).
  final int effect;

  /// Up to four effect parameter bytes (e.g. RGB color, speed).
  final List<int> effectParams;

  static const int maxLeds = 65535;
  static const int maxBrightness = 255;

  /// Whether all fields are within the wire-encodable bounds.
  bool get isValid =>
      ledCount >= 1 &&
      ledCount <= maxLeds &&
      brightness >= 0 &&
      brightness <= maxBrightness &&
      effect >= 0 &&
      effect <= 255 &&
      effectParams.length == 4 &&
      effectParams.every((p) => p >= 0 && p <= 255);

  LedConfig copyWith({
    int? ledCount,
    int? brightness,
    int? effect,
    List<int>? effectParams,
  }) {
    return LedConfig(
      ledCount: ledCount ?? this.ledCount,
      brightness: brightness ?? this.brightness,
      effect: effect ?? this.effect,
      effectParams: effectParams ?? this.effectParams,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LedConfig &&
      other.ledCount == ledCount &&
      other.brightness == brightness &&
      other.effect == effect &&
      _listEq(other.effectParams, effectParams);

  @override
  int get hashCode =>
      Object.hash(ledCount, brightness, effect, Object.hashAll(effectParams));

  static bool _listEq(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
