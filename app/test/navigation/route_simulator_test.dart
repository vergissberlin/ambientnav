import 'package:ambientnav/features/navigation/domain/entities/maneuver.dart';
import 'package:ambientnav/features/navigation/domain/entities/route.dart';
import 'package:ambientnav/features/navigation/domain/route_simulator.dart';
import 'package:flutter_test/flutter_test.dart';

Routes _route() {
  // ~3 segments along a straight east-bound line; 3 maneuvers of 1 km each.
  return const Routes(
    geometry: [
      GeoPoint(52.0, 13.0000),
      GeoPoint(52.0, 13.0147), // ~1 km east
      GeoPoint(52.0, 13.0294), // ~2 km
      GeoPoint(52.0, 13.0441), // ~3 km
    ],
    maneuvers: [
      Maneuver(
          type: ManeuverType.turnLeft,
          instruction: 'a',
          distanceMeters: 1000,
          latitude: 52.0,
          longitude: 13.0147),
      Maneuver(
          type: ManeuverType.turnRight,
          instruction: 'b',
          distanceMeters: 1000,
          latitude: 52.0,
          longitude: 13.0294),
      Maneuver(
          type: ManeuverType.arrive,
          instruction: 'c',
          distanceMeters: 1000,
          latitude: 52.0,
          longitude: 13.0441),
    ],
    distanceMeters: 3000,
    durationSeconds: 300,
  );
}

void main() {
  test('advances maneuvers monotonically and reaches arrived', () {
    final sim = RouteSimulator(_route(), speedMps: 100); // fast for the test
    var lastIndex = 0;
    var arrived = false;
    for (var i = 0; i < 100 && !arrived; i++) {
      final s = sim.step(1.0); // 100 m per step
      expect(s.nextManeuverIndex, greaterThanOrEqualTo(lastIndex));
      lastIndex = s.nextManeuverIndex;
      arrived = s.arrived;
    }
    expect(arrived, isTrue);
    expect(sim.traveledMeters, greaterThanOrEqualTo(3000));
  });

  test('distance to the next maneuver decreases as we travel', () {
    final sim = RouteSimulator(_route(), speedMps: 100);
    final first = sim.step(1.0);
    final second = sim.step(1.0);
    expect(second.distanceToManeuverMeters,
        lessThan(first.distanceToManeuverMeters));
  });

  test('reports the travel heading (~east) along the east-bound route', () {
    final sim = RouteSimulator(_route(), speedMps: 100);
    final s = sim.step(1.0);
    expect(s.bearingDeg, closeTo(90, 2));
  });

  test('progress scales with the elapsed delta', () {
    final slow = RouteSimulator(_route(), speedMps: 10)..step(1.0);
    final fast = RouteSimulator(_route(), speedMps: 20)..step(1.0);
    expect(fast.traveledMeters, closeTo(slow.traveledMeters * 2, 0.001));
  });
}
