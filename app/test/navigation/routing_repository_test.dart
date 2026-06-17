import 'package:ambientnav/core/persistence/local_store.dart';
import 'package:ambientnav/features/navigation/data/route_cache_store.dart';
import 'package:ambientnav/features/navigation/data/routing_api.dart';
import 'package:ambientnav/features/navigation/data/routing_repository_impl.dart';
import 'package:ambientnav/features/navigation/domain/entities/route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRoutingApi extends Mock implements RoutingApi {}

void main() {
  const origin = GeoPoint(52.52, 13.405);
  const destination = GeoPoint(48.137, 11.575);
  final route = Routes(
    geometry: const [GeoPoint(52.52, 13.405)],
    maneuvers: const [],
    distanceMeters: 1000,
    durationSeconds: 600,
  );

  setUpAll(() {
    registerFallbackValue(const GeoPoint(0, 0));
  });

  test('caches a successful online plan', () async {
    final api = _MockRoutingApi();
    final cache = RouteCacheStore(InMemoryLocalStore());
    when(() => api.route(any(), any())).thenAnswer((_) async => route);

    final repo = RoutingRepositoryImpl(api, cache);
    final planned = await repo.planRoute(origin, destination);

    expect(planned.distanceMeters, 1000);
    expect(cache.load(origin, destination), isNotNull);
  });

  test('falls back to cache when the network fails (offline)', () async {
    final api = _MockRoutingApi();
    final cache = RouteCacheStore(InMemoryLocalStore());
    await cache.save(origin, destination, route);
    when(() => api.route(any(), any())).thenThrow(Exception('offline'));

    final repo = RoutingRepositoryImpl(api, cache);
    final planned = await repo.planRoute(origin, destination);

    expect(planned.distanceMeters, 1000);
  });

  test('rethrows when offline and nothing cached', () async {
    final api = _MockRoutingApi();
    final cache = RouteCacheStore(InMemoryLocalStore());
    when(() => api.route(any(), any())).thenThrow(Exception('offline'));

    final repo = RoutingRepositoryImpl(api, cache);
    expect(() => repo.planRoute(origin, destination), throwsException);
  });
}
