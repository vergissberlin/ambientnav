import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/local_store.dart';
import '../theme/theme_controller.dart';

/// Compile-time default for the route simulation mode
/// (`--dart-define=SIMULATE=true`).
const bool kSimulateRouteDefault =
    bool.fromEnvironment('SIMULATE', defaultValue: false);

/// Persists the developer "route simulation" toggle. When enabled, planning a
/// route drives a virtual vehicle along it instead of relying on real GPS.
class SimulationController extends StateNotifier<bool> {
  SimulationController(this._store) : super(_read(_store));

  final LocalStore _store;
  static const String _key = 'route_simulation';

  static bool _read(LocalStore store) {
    final raw = store.getString(_key);
    if (raw == null) return kSimulateRouteDefault;
    return raw == 'true';
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    await _store.setString(_key, value.toString());
  }
}

final simulationEnabledProvider =
    StateNotifierProvider<SimulationController, bool>((ref) {
  return SimulationController(ref.watch(localStoreProvider));
});
