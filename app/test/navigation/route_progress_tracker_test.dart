import 'package:ambientnav/core/utils/geo.dart';
import 'package:ambientnav/features/navigation/domain/entities/maneuver.dart';
import 'package:ambientnav/features/navigation/domain/entities/route.dart';
import 'package:ambientnav/features/navigation/domain/route_progress_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

Routes _route() {
  return const Routes(
    geometry: [
      GeoPoint(52.0, 13.0000),
      GeoPoint(52.0, 13.0147),
      GeoPoint(52.0, 13.0294),
      GeoPoint(52.0, 13.0441),
    ],
    maneuvers: [
      Maneuver(
        type: ManeuverType.turnLeft,
        instruction: 'a',
        distanceMeters: 1000,
        latitude: 52.0,
        longitude: 13.0147,
      ),
      Maneuver(
        type: ManeuverType.turnRight,
        instruction: 'b',
        distanceMeters: 1000,
        latitude: 52.0,
        longitude: 13.0294,
      ),
      Maneuver(
        type: ManeuverType.arrive,
        instruction: 'c',
        distanceMeters: 1000,
        latitude: 52.0,
        longitude: 13.0441,
      ),
    ],
    distanceMeters: 3000,
    durationSeconds: 300,
  );
}

void main() {
  test('snapToPolyline projects onto the nearest segment', () {
    final route = _route();
    final snap = Geo.snapToPolyline(
      const GeoPoint(52.0001, 13.007),
      route.geometry,
    );
    expect(snap.distanceAlongMeters, greaterThan(0));
    expect(snap.distanceAlongMeters, lessThan(1000));
    expect(snap.bearingDeg, closeTo(90, 2));
  });

  test('tracker reports decreasing distance near the route start', () {
    final tracker = RouteProgressTracker(_route());
    final nearStart = tracker.update(const GeoPoint(52.0001, 13.001));
    final further = tracker.update(const GeoPoint(52.0001, 13.008));
    expect(nearStart.nextManeuverIndex, 0);
    expect(further.distanceToManeuverMeters,
        lessThan(nearStart.distanceToManeuverMeters));
  });

  test('tracker advances maneuver index along the route', () {
    final tracker = RouteProgressTracker(
      _route(),
      maneuverAdvanceThresholdMeters: 10,
    );
    final progress = tracker.update(const GeoPoint(52.0, 13.020));
    expect(progress.nextManeuverIndex, greaterThanOrEqualTo(1));
  });

  test('tracker marks arrival near the route end', () {
    final tracker = RouteProgressTracker(
      _route(),
      maneuverAdvanceThresholdMeters: 10,
    );
    final progress = tracker.update(const GeoPoint(52.0, 13.044));
    expect(progress.arrived, isTrue);
  });
}
