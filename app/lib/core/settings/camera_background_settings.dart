// StateNotifier / StateNotifierProvider / StateProvider moved to
// legacy.dart in Riverpod 3. Tracked for migration to Notifier.
import 'package:flutter_riverpod/legacy.dart';

import '../persistence/local_store.dart';
import '../theme/theme_controller.dart';

/// Persists the "camera as navigation background" toggle. When enabled, the
/// nav screen shows a blurred live camera feed behind a semi-transparent,
/// roads-only map instead of the full basemap.
class CameraBackgroundController extends StateNotifier<bool> {
  CameraBackgroundController(this._store) : super(_read(_store));

  final LocalStore _store;
  static const String _key = 'camera_nav_background';

  static bool _read(LocalStore store) => store.getString(_key) == 'true';

  Future<void> setEnabled(bool value) async {
    state = value;
    await _store.setString(_key, value.toString());
  }
}

final cameraBackgroundEnabledProvider =
    StateNotifierProvider<CameraBackgroundController, bool>((ref) {
      return CameraBackgroundController(ref.watch(localStoreProvider));
    });

/// Persists the camera-background blur strength. Higher values make the
/// camera preview more blurred behind the roads-only map.
class CameraBackgroundBlurController extends StateNotifier<double> {
  CameraBackgroundBlurController(this._store) : super(_read(_store));

  final LocalStore _store;
  static const String _key = 'camera_nav_background_blur';
  static const double _defaultValue = 18.0;

  static double _read(LocalStore store) {
    final raw = store.getString(_key);
    final parsed = raw == null ? null : double.tryParse(raw);
    if (parsed == null) return _defaultValue;
    return parsed.clamp(0.0, 30.0);
  }

  Future<void> setBlur(double value) async {
    final clamped = value.clamp(0.0, 30.0);
    state = clamped;
    await _store.setString(_key, clamped.toString());
  }
}

final cameraBackgroundBlurProvider =
    StateNotifierProvider<CameraBackgroundBlurController, double>((ref) {
      return CameraBackgroundBlurController(ref.watch(localStoreProvider));
    });

/// True right after a camera permission request for the background feature
/// was denied, so the settings screen can surface a hint. Reset whenever the
/// toggle is turned off or a later request succeeds.
final cameraBackgroundPermissionDeniedProvider = StateProvider<bool>(
  (ref) => false,
);

/// True when the app tried to enable the background but the current device or
/// simulator reports no available cameras. Used to show a simulator-specific
/// hint instead of a permission error.
final cameraBackgroundNoCameraAvailableProvider = StateProvider<bool>(
  (ref) => false,
);
