import '../domain/entities/route.dart';
import '../domain/repositories/routing_repository.dart';
import 'route_cache_store.dart';
import 'routing_api.dart';

/// Online routing with transparent offline caching: a successful online plan is
/// cached; if the network fails, a cached route for the same origin/destination
/// is returned so the planned trip still works offline.
class RoutingRepositoryImpl implements RoutingRepository {
  RoutingRepositoryImpl(this._api, this._cache);

  final RoutingApi _api;
  final RouteCacheStore _cache;

  @override
  Future<Routes> planRoute(GeoPoint origin, GeoPoint destination) async {
    try {
      final route = await _api.route(origin, destination);
      await _cache.save(origin, destination, route);
      return route;
    } catch (_) {
      final cached = _cache.load(origin, destination);
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<Routes?> cachedRoute(GeoPoint origin, GeoPoint destination) async {
    return _cache.load(origin, destination);
  }
}
