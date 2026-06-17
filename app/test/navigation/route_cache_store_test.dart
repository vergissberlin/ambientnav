import 'package:ambientnav/core/persistence/local_store.dart';
import 'package:ambientnav/features/navigation/data/route_cache_store.dart';
import 'package:ambientnav/features/navigation/domain/entities/maneuver.dart';
import 'package:ambientnav/features/navigation/domain/entities/route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RouteCacheStore store;
  const origin = GeoPoint(52.52, 13.405);
  const destination = GeoPoint(48.137, 11.575);

  final route = Routes(
    geometry: const [GeoPoint(52.52, 13.405), GeoPoint(48.137, 11.575)],
    maneuvers: const [
      Maneuver(
        type: ManeuverType.depart,
        instruction: 'Go',
        distanceMeters: 100,
        latitude: 52.52,
        longitude: 13.405,
      ),
    ],
    distanceMeters: 500000,
    durationSeconds: 18000,
  );

  setUp(() => store = RouteCacheStore(InMemoryLocalStore()));

  test('returns null before anything is cached', () {
    expect(store.load(origin, destination), isNull);
  });

  test('saves and loads a route losslessly', () async {
    await store.save(origin, destination, route);
    final loaded = store.load(origin, destination)!;
    expect(loaded.distanceMeters, route.distanceMeters);
    expect(loaded.geometry.length, route.geometry.length);
    expect(loaded.maneuvers.first.instruction, 'Go');
    expect(loaded.maneuvers.first.type, ManeuverType.depart);
  });
}
