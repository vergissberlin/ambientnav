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

/// True right after a camera permission request for the background feature
/// was denied, so the settings screen can surface a hint. Reset whenever the
/// toggle is turned off or a later request succeeds.
final cameraBackgroundPermissionDeniedProvider = StateProvider<bool>(
  (ref) => false,
);
