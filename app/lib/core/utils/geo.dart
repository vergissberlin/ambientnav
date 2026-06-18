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

  /// Initial bearing from [a] to [b] in degrees, 0–360 clockwise from north.
  static double initialBearing(GeoPoint a, GeoPoint b) {
    final lat1 = _rad(a.latitude);
    final lat2 = _rad(b.latitude);
    final dLon = _rad(b.longitude - a.longitude);
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final deg = math.atan2(y, x) * 180.0 / math.pi;
    return (deg + 360.0) % 360.0;
  }

  /// Heading (degrees) of the route at [meters] along the polyline — the
  /// direction of the segment currently being traversed.
  static double bearingAlong(List<GeoPoint> points, double meters) {
    if (points.length < 2) return 0;
    var remaining = meters <= 0 ? 0.0 : meters;
    for (var i = 1; i < points.length; i++) {
      final segLen = haversineMeters(points[i - 1], points[i]);
      if (remaining <= segLen || i == points.length - 1) {
        return initialBearing(points[i - 1], points[i]);
      }
      remaining -= segLen;
    }
    return initialBearing(points[points.length - 2], points.last);
  }

  static double _rad(double deg) => deg * math.pi / 180.0;

  /// Result of projecting a point onto a route polyline.
  static SnapResult snapToPolyline(GeoPoint point, List<GeoPoint> polyline) {
    if (polyline.isEmpty) {
      return const SnapResult(
        snapped: GeoPoint(0, 0),
        distanceAlongMeters: 0,
        bearingDeg: 0,
      );
    }
    if (polyline.length == 1) {
      return SnapResult(
        snapped: polyline.first,
        distanceAlongMeters: 0,
        bearingDeg: 0,
      );
    }

    var bestDist = double.infinity;
    var bestAlong = 0.0;
    var bestPoint = polyline.first;
    var bestBearing = 0.0;
    var cumulative = 0.0;

    for (var i = 1; i < polyline.length; i++) {
      final a = polyline[i - 1];
      final b = polyline[i];
      final segLen = haversineMeters(a, b);
      final proj = _projectOntoSegment(point, a, b);
      final distToSeg = haversineMeters(point, proj.point);
      if (distToSeg < bestDist) {
        bestDist = distToSeg;
        bestAlong = cumulative + proj.t * segLen;
        bestPoint = proj.point;
        bestBearing = segLen == 0 ? 0 : initialBearing(a, b);
      }
      cumulative += segLen;
    }

    return SnapResult(
      snapped: bestPoint,
      distanceAlongMeters: bestAlong,
      bearingDeg: bestBearing,
    );
  }

  static ({GeoPoint point, double t}) _projectOntoSegment(
    GeoPoint p,
    GeoPoint a,
    GeoPoint b,
  ) {
    final latMid = (a.latitude + b.latitude) / 2;
    final cosLat = math.cos(_rad(latMid));
    final scaleLon = earthRadiusM * math.pi / 180.0 * cosLat;
    final scaleLat = earthRadiusM * math.pi / 180.0;

    final bx = (b.longitude - a.longitude) * scaleLon;
    final by = (b.latitude - a.latitude) * scaleLat;
    final px = (p.longitude - a.longitude) * scaleLon;
    final py = (p.latitude - a.latitude) * scaleLat;

    final segLen2 = bx * bx + by * by;
    final t = segLen2 == 0 ? 0.0 : ((px * bx + py * by) / segLen2).clamp(0.0, 1.0);
    return (point: _lerp(a, b, t), t: t);
  }
}

/// A GPS point snapped onto a polyline with progress metadata.
class SnapResult {
  const SnapResult({
    required this.snapped,
    required this.distanceAlongMeters,
    required this.bearingDeg,
  });

  final GeoPoint snapped;
  final double distanceAlongMeters;
  final double bearingDeg;
}
