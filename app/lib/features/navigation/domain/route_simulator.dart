import '../../../core/utils/geo.dart';
import 'entities/route.dart';

/// One simulated position update along a route.
class SimStep {
  const SimStep({
    required this.position,
    required this.nextManeuverIndex,
    required this.distanceToManeuverMeters,
    required this.arrived,
  });

  final GeoPoint position;
  final int nextManeuverIndex;
  final double distanceToManeuverMeters;
  final bool arrived;
}

/// Drives a virtual vehicle along a planned [Routes] for the dev simulation
/// mode. Pure and Timer-free: call [step] with an elapsed-seconds delta. A
/// driver (e.g. a Timer) advances it in the app; tests call [step] directly.
class RouteSimulator {
  RouteSimulator(this.route, {this.speedMps = 13.9})
      : _geometry = route.geometry,
        _geometryLength = Geo.polylineLength(route.geometry),
        _cumManeuver = _cumulativeManeuverDistances(route);

  /// ~50 km/h default.
  final Routes route;
  final double speedMps;

  final List<GeoPoint> _geometry;
  final double _geometryLength;
  final List<double> _cumManeuver;

  double _traveled = 0;

  double get traveledMeters => _traveled;

  static List<double> _cumulativeManeuverDistances(Routes route) {
    final out = <double>[];
    var acc = 0.0;
    for (final m in route.maneuvers) {
      acc += m.distanceMeters;
      out.add(acc);
    }
    return out;
  }

  /// Advance by [dtSeconds] and return the new simulated state.
  SimStep step(double dtSeconds) {
    _traveled += speedMps * dtSeconds;
    if (_traveled < 0) _traveled = 0;
    return _snapshot();
  }

  SimStep _snapshot() {
    final position = _geometry.isEmpty
        ? const GeoPoint(0, 0)
        : Geo.interpolateAlong(_geometry, _traveled);

    // Next maneuver: the first whose cumulative distance is still ahead.
    var nextIndex = _cumManeuver.length;
    for (var i = 0; i < _cumManeuver.length; i++) {
      if (_cumManeuver[i] > _traveled + 0.001) {
        nextIndex = i;
        break;
      }
    }

    final arrived = nextIndex >= _cumManeuver.length &&
        _traveled >= (_geometryLength == 0 ? 0 : _geometryLength - 0.5);

    final distanceToManeuver = nextIndex < _cumManeuver.length
        ? (_cumManeuver[nextIndex] - _traveled).clamp(0.0, double.infinity)
        : 0.0;

    return SimStep(
      position: position,
      nextManeuverIndex: nextIndex >= _cumManeuver.length
          ? _cumManeuver.length - 1
          : nextIndex,
      distanceToManeuverMeters: distanceToManeuver,
      arrived: arrived,
    );
  }
}
