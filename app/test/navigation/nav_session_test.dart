import 'package:ambientnav/core/di/providers.dart';
import 'package:ambientnav/core/location/location_service.dart';
import 'package:ambientnav/core/persistence/local_store.dart';
import 'package:ambientnav/core/theme/theme_controller.dart';
import 'package:ambientnav/features/navigation/data/geocoding_service.dart';
import 'package:ambientnav/features/navigation/domain/entities/maneuver.dart';
import 'package:ambientnav/features/navigation/domain/entities/route.dart';
import 'package:ambientnav/features/navigation/domain/repositories/routing_repository.dart';
import 'package:ambientnav/features/navigation/presentation/nav_controller.dart';
import 'package:ambientnav/features/navigation/presentation/nav_session.dart';
import 'package:ambientnav/features/navigation/presentation/navigation_location_runner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeLocationService extends LocationService {
  @override
  Future<GeoPoint?> currentPosition() async => const GeoPoint(52.52, 13.405);

  @override
  Future<bool> ensureNavigationPermission() async => true;

  @override
  void startNavigationSession(void Function(GeoPoint position) onPosition) {}

  @override
  void stopNavigationSession() {}
}

class _FakeNavigationLocationRunner extends NavigationLocationRunner {
  _FakeNavigationLocationRunner(super.ref);

  @override
  Future<void> start(Routes route) async {}

  @override
  void stop() {}
}

class _FakeRouting implements RoutingRepository {
  _FakeRouting(this._route, {this.fail = false});
  final Routes _route;
  final bool fail;

  @override
  Future<Routes> planRoute(GeoPoint origin, GeoPoint destination) async {
    if (fail) throw Exception('offline');
    return _route;
  }

  @override
  Future<Routes?> cachedRoute(GeoPoint origin, GeoPoint destination) async =>
      null;
}

final _route = Routes(
  geometry: const [GeoPoint(52.52, 13.405), GeoPoint(52.50, 13.45)],
  maneuvers: const [
    Maneuver(
      type: ManeuverType.turnLeft,
      instruction: 'Turn left',
      distanceMeters: 100,
      latitude: 52.52,
      longitude: 13.405,
    ),
  ],
  distanceMeters: 1500,
  durationSeconds: 300,
);

const _dest = GeoResult(label: 'Dest', point: GeoPoint(52.50, 13.45));

List<Override> _testOverrides(RoutingRepository routing) => [
      localStoreProvider.overrideWithValue(InMemoryLocalStore()),
      routingRepositoryProvider.overrideWithValue(routing),
      locationServiceProvider.overrideWithValue(_FakeLocationService()),
      navigationLocationRunnerProvider.overrideWith(
        (ref) => _FakeNavigationLocationRunner(ref),
      ),
    ];

void main() {
  test('planTo sets the route and enters navigating', () async {
    final container = ProviderContainer(overrides: [
      ..._testOverrides(_FakeRouting(_route)),
    ]);
    addTearDown(container.dispose);

    await container.read(navSessionProvider).planTo(
          _dest,
          originOverride: const GeoPoint(52.52, 13.405),
        );

    final state = container.read(navControllerProvider);
    expect(state.phase, NavPhase.navigating);
    expect(state.route, isNotNull);
    expect(state.nextManeuver?.instruction, 'Turn left');
  });

  test('planTo reports an error when routing fails', () async {
    final container = ProviderContainer(overrides: [
      ..._testOverrides(_FakeRouting(_route, fail: true)),
    ]);
    addTearDown(container.dispose);

    await container.read(navSessionProvider).planTo(
          _dest,
          originOverride: const GeoPoint(52.52, 13.405),
        );

    final state = container.read(navControllerProvider);
    expect(state.phase, NavPhase.idle);
    expect(state.error, isNotNull);
  });

  test('stop clears the navigation state', () async {
    final container = ProviderContainer(overrides: [
      ..._testOverrides(_FakeRouting(_route)),
    ]);
    addTearDown(container.dispose);

    final session = container.read(navSessionProvider);
    await session.planTo(_dest, originOverride: const GeoPoint(52.52, 13.405));
    expect(container.read(navControllerProvider).phase, NavPhase.navigating);

    session.stop();
    expect(container.read(navControllerProvider).phase, NavPhase.idle);
  });
}
