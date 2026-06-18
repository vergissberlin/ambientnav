import '../../domain/entities/maneuver.dart';
import '../../domain/entities/route.dart';

/// Parses routing-engine JSON into the backend-independent [Routes] entity.
///
/// Supports the two engines named in the project docs: Valhalla and OSRM.
class RouteResponseDto {
  const RouteResponseDto._();

  /// Parse an OSRM `/route` response (`routes[0]` with `legs[].steps[]`).
  static Routes fromOsrm(Map<String, dynamic> json) {
    final routes = json['routes'] as List?;
    if (routes == null || routes.isEmpty) {
      throw const FormatException('OSRM response has no routes');
    }
    final route = routes.first as Map<String, dynamic>;
    final geometry = _osrmGeometry(route['geometry']);
    final maneuvers = <Maneuver>[];
    for (final leg in (route['legs'] as List? ?? const [])) {
      for (final step in ((leg as Map)['steps'] as List? ?? const [])) {
        final s = step as Map<String, dynamic>;
        final man = s['maneuver'] as Map<String, dynamic>;
        final loc = (man['location'] as List).cast<num>();
        maneuvers.add(Maneuver(
          type:
              _osrmManeuver(man['type'] as String?, man['modifier'] as String?),
          instruction: (s['name'] as String?)?.trim().isNotEmpty == true
              ? s['name'] as String
              : (man['type'] as String? ?? 'continue'),
          distanceMeters: (s['distance'] as num?)?.toDouble() ?? 0,
          latitude: loc[1].toDouble(),
          longitude: loc[0].toDouble(),
        ));
      }
    }
    return Routes(
      geometry: geometry,
      maneuvers: maneuvers,
      distanceMeters: (route['distance'] as num?)?.toDouble() ?? 0,
      durationSeconds: (route['duration'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Parse a Valhalla `/route` response (`trip.legs[].maneuvers[]`).
  static Routes fromValhalla(Map<String, dynamic> json) {
    final trip = json['trip'] as Map<String, dynamic>?;
    if (trip == null) {
      throw const FormatException('Valhalla response has no trip');
    }
    final legs = trip['legs'] as List? ?? const [];
    final geometry = <GeoPoint>[];
    final maneuvers = <Maneuver>[];
    for (final leg in legs) {
      final l = leg as Map<String, dynamic>;
      final shape = decodePolyline(l['shape'] as String? ?? '', precision: 6);
      geometry.addAll(shape);
      for (final man in (l['maneuvers'] as List? ?? const [])) {
        final m = man as Map<String, dynamic>;
        final beginIndex = (m['begin_shape_index'] as num?)?.toInt() ?? 0;
        final point = beginIndex < shape.length
            ? shape[beginIndex]
            : (shape.isNotEmpty ? shape.last : const GeoPoint(0, 0));
        maneuvers.add(Maneuver(
          type: _valhallaManeuver((m['type'] as num?)?.toInt() ?? 0),
          instruction: m['instruction'] as String? ?? '',
          distanceMeters: ((m['length'] as num?)?.toDouble() ?? 0) * 1000,
          latitude: point.latitude,
          longitude: point.longitude,
        ));
      }
    }
    final summary = trip['summary'] as Map<String, dynamic>?;
    return Routes(
      geometry: geometry,
      maneuvers: maneuvers,
      distanceMeters: ((summary?['length'] as num?)?.toDouble() ?? 0) * 1000,
      durationSeconds: (summary?['time'] as num?)?.toDouble() ?? 0,
    );
  }

  static List<GeoPoint> _osrmGeometry(dynamic geometry) {
    if (geometry is String) {
      return decodePolyline(geometry, precision: 5);
    }
    if (geometry is Map && geometry['coordinates'] is List) {
      return (geometry['coordinates'] as List)
          .map((c) => GeoPoint(
                (c[1] as num).toDouble(),
                (c[0] as num).toDouble(),
              ))
          .toList();
    }
    return const [];
  }

  static ManeuverType _osrmManeuver(String? type, String? modifier) {
    switch (type) {
      case 'depart':
        return ManeuverType.depart;
      case 'arrive':
        return ManeuverType.arrive;
      case 'roundabout':
      case 'rotary':
        return ManeuverType.roundabout;
    }
    switch (modifier) {
      case 'left':
        return ManeuverType.turnLeft;
      case 'right':
        return ManeuverType.turnRight;
      case 'slight left':
        return ManeuverType.slightLeft;
      case 'slight right':
        return ManeuverType.slightRight;
      case 'uturn':
        return ManeuverType.uturn;
      default:
        return ManeuverType.straight;
    }
  }

  static ManeuverType _valhallaManeuver(int type) {
    // Subset of Valhalla maneuver type codes.
    switch (type) {
      case 1:
      case 2:
      case 3:
        return ManeuverType.depart;
      case 4:
      case 5:
      case 6:
        return ManeuverType.arrive;
      case 15:
      case 16:
        return ManeuverType.turnLeft;
      case 9:
      case 10:
        return ManeuverType.turnRight;
      case 14:
        return ManeuverType.slightLeft;
      case 11:
        return ManeuverType.slightRight;
      case 13:
        return ManeuverType.uturn;
      case 26:
      case 27:
        return ManeuverType.roundabout;
      default:
        return ManeuverType.straight;
    }
  }

  /// Decode a Google/OSRM-style encoded polyline at the given [precision]
  /// (5 for OSRM, 6 for Valhalla).
  static List<GeoPoint> decodePolyline(String encoded, {int precision = 5}) {
    if (encoded.isEmpty) return const [];
    final factor = 1 / (precision == 6 ? 1e6 : 1e5);
    final points = <GeoPoint>[];
    var index = 0;
    var lat = 0;
    var lng = 0;
    while (index < encoded.length) {
      var result = 0;
      var shift = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      result = 0;
      shift = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(GeoPoint(lat * factor, lng * factor));
    }
    return points;
  }
}
