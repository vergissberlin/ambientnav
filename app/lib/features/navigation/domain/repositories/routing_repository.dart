import '../entities/route.dart';

/// Plans routes between coordinates. Implemented by an online client
/// (Valhalla / OSRM via Dio) backed by an offline cache.
abstract interface class RoutingRepository {
  /// Plan a driving route from [origin] to [destination].
  Future<Routes> planRoute(GeoPoint origin, GeoPoint destination);

  /// Return a previously cached route for the given origin/destination, or
  /// null if none is cached. Enables offline use of a planned trip.
  Future<Routes?> cachedRoute(GeoPoint origin, GeoPoint destination);
}
