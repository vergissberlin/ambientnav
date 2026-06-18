import 'dart:math' as math;

import '../../features/navigation/domain/entities/route.dart';

/// Geographic helpers for the route simulator (pure, unit-tested).
class Geo {
  const Geo._();

  static const double earthRadiusM = 6371000.0;

  /// Great-circle distance between two points in metres (haversine).
  static double haversineMeters(GeoPoint a, GeoPoint b) {
    final lat1 = _rad(a.latitude);
    final lat2 = _rad(b.latitude);
    final dLat = _rad(b.latitude - a.latitude);
    final dLon = _rad(b.longitude - a.longitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return 2 * earthRadiusM * math.asin(math.min(1.0, math.sqrt(h)));
  }

  /// Total length of a polyline in metres.
  static double polylineLength(List<GeoPoint> points) {
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += haversineMeters(points[i - 1], points[i]);
    }
    return total;
  }

  /// Cumulative distance at each vertex (same length as [points], first = 0).
  static List<double> cumulativeDistances(List<GeoPoint> points) {
    final out = List<double>.filled(points.length, 0);
    for (var i = 1; i < points.length; i++) {
      out[i] = out[i - 1] + haversineMeters(points[i - 1], points[i]);
    }
    return out;
  }

  /// Point reached after travelling [meters] along the polyline. Clamps to the
  /// endpoints for negative / overshooting inputs.
  static GeoPoint interpolateAlong(List<GeoPoint> points, double meters) {
    if (points.isEmpty) return const GeoPoint(0, 0);
    if (points.length == 1 || meters <= 0) return points.first;
    var remaining = meters;
    for (var i = 1; i < points.length; i++) {
      final segLen = haversineMeters(points[i - 1], points[i]);
      if (remaining <= segLen || i == points.length - 1) {
        if (segLen == 0) return points[i];
        final t = (remaining / segLen).clamp(0.0, 1.0);
        return _lerp(points[i - 1], points[i], t);
      }
      remaining -= segLen;
    }
    return points.last;
  }

  static GeoPoint _lerp(GeoPoint a, GeoPoint b, double t) => GeoPoint(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );

  static double _rad(double deg) => deg * math.pi / 180.0;
}
