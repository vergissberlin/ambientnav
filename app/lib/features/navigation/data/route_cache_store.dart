import 'dart:convert';

import '../../../core/persistence/local_store.dart';
import '../domain/entities/route.dart';

/// Caches planned routes (geometry + maneuvers) so a trip planned online can be
/// followed offline.
class RouteCacheStore {
  RouteCacheStore(this._store);

  final LocalStore _store;

  static String keyFor(GeoPoint origin, GeoPoint destination) {
    String f(double v) => v.toStringAsFixed(5);
    return 'route:${f(origin.latitude)},${f(origin.longitude)}'
        '->${f(destination.latitude)},${f(destination.longitude)}';
  }

  Future<void> save(GeoPoint origin, GeoPoint destination, Routes route) async {
    await _store.setString(
      keyFor(origin, destination),
      jsonEncode(route.toJson()),
    );
  }

  Routes? load(GeoPoint origin, GeoPoint destination) {
    final raw = _store.getString(keyFor(origin, destination));
    if (raw == null) return null;
    return Routes.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
