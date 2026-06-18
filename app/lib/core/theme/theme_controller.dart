import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/local_store.dart';

/// Persists and exposes the selected [ThemeMode] (system / light / dark).
class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController(this._store) : super(_read(_store));

  final LocalStore _store;

  static const String _key = 'theme_mode';

  static ThemeMode _read(LocalStore store) {
    switch (store.getString(_key)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _store.setString(_key, mode.name);
  }

  /// Cycle system → light → dark → system, handy for a single toggle button.
  Future<void> cycle() async {
    final next = switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    await setMode(next);
  }
}

/// Overridden in `core/di/providers.dart` with the real [LocalStore].
final localStoreProvider = Provider<LocalStore>((ref) {
  throw UnimplementedError('localStoreProvider must be overridden');
});

final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeMode>((ref) {
  return ThemeController(ref.watch(localStoreProvider));
});
