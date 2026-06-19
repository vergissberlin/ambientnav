import '../../../core/utils/geo.dart';
import 'entities/route.dart';

/// Progress along a planned route derived from a live GPS fix.
class RouteProgress {
  const RouteProgress({
    required this.snappedPosition,
    required this.bearingDeg,
    required this.nextManeuverIndex,
    required this.distanceToManeuverMeters,
    required this.arrived,
  });

  final GeoPoint snappedPosition;
  final double bearingDeg;
  final int nextManeuverIndex;
  final double distanceToManeuverMeters;
  final bool arrived;
}

/// Map-matches GPS positions onto a planned [Routes] geometry and reports
/// maneuver progress. Pure and unit-testable.
class RouteProgressTracker {
  RouteProgressTracker(
    this.route, {
    this.maneuverAdvanceThresholdMeters = 30,
  })  : _geometry = route.geometry,
        _geometryLength = Geo.polylineLength(route.geometry),
        _cumManeuver = _cumulativeManeuverDistances(route);

  final Routes route;
  final double maneuverAdvanceThresholdMeters;

  final List<GeoPoint> _geometry;
  final double _geometryLength;
  final List<double> _cumManeuver;

  static List<double> _cumulativeManeuverDistances(Routes route) {
    final out = <double>[];
    var acc = 0.0;
    for (final m in route.maneuvers) {
      acc += m.distanceMeters;
      out.add(acc);
    }
    return out;
  }

  RouteProgress update(GeoPoint rawPosition) {
    final snap = Geo.snapToPolyline(rawPosition, _geometry);
    final traveled = snap.distanceAlongMeters;

    var nextIndex = _cumManeuver.length;
    for (var i = 0; i < _cumManeuver.length; i++) {
      if (_cumManeuver[i] > traveled + maneuverAdvanceThresholdMeters) {
        nextIndex = i;
        break;
      }
    }

    final arrived = nextIndex >= _cumManeuver.length &&
        _geometryLength > 0 &&
        traveled >= _geometryLength - maneuverAdvanceThresholdMeters;

    final distanceToManeuver = nextIndex < _cumManeuver.length
        ? (_cumManeuver[nextIndex] - traveled).clamp(0.0, double.infinity)
        : 0.0;

    return RouteProgress(
      snappedPosition: snap.snapped,
      bearingDeg: snap.bearingDeg,
      nextManeuverIndex: nextIndex >= _cumManeuver.length
          ? (_cumManeuver.isEmpty ? 0 : _cumManeuver.length - 1)
          : nextIndex,
      distanceToManeuverMeters: distanceToManeuver,
      arrived: arrived,
    );
  }
}
