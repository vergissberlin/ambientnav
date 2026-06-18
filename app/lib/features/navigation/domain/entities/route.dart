import 'maneuver.dart';

/// A geographic coordinate.
class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);
  final double latitude;
  final double longitude;

  Map<String, double> toJson() => {'lat': latitude, 'lon': longitude};

  factory GeoPoint.fromJson(Map<String, dynamic> json) => GeoPoint(
      (json['lat'] as num).toDouble(), (json['lon'] as num).toDouble());

  @override
  bool operator ==(Object other) =>
      other is GeoPoint &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

/// A planned route: ordered geometry plus the maneuver list. Cacheable so the
/// planned trip works offline.
class Routes {
  const Routes({
    required this.geometry,
    required this.maneuvers,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<GeoPoint> geometry;
  final List<Maneuver> maneuvers;
  final double distanceMeters;
  final double durationSeconds;

  /// The bounding box of the route geometry, used to download an offline
  /// MapLibre region. Returns `[southWest, northEast]`.
  List<GeoPoint> get boundingBox {
    if (geometry.isEmpty) {
      return const [GeoPoint(0, 0), GeoPoint(0, 0)];
    }
    var minLat = geometry.first.latitude;
    var maxLat = geometry.first.latitude;
    var minLon = geometry.first.longitude;
    var maxLon = geometry.first.longitude;
    for (final p in geometry) {
      minLat = p.latitude < minLat ? p.latitude : minLat;
      maxLat = p.latitude > maxLat ? p.latitude : maxLat;
      minLon = p.longitude < minLon ? p.longitude : minLon;
      maxLon = p.longitude > maxLon ? p.longitude : maxLon;
    }
    return [GeoPoint(minLat, minLon), GeoPoint(maxLat, maxLon)];
  }

  Map<String, dynamic> toJson() => {
        'geometry': geometry.map((p) => p.toJson()).toList(),
        'maneuvers': maneuvers
            .map((m) => {
                  'type': m.type.name,
                  'instruction': m.instruction,
                  'distance': m.distanceMeters,
                  'lat': m.latitude,
                  'lon': m.longitude,
                })
            .toList(),
        'distance': distanceMeters,
        'duration': durationSeconds,
      };

  factory Routes.fromJson(Map<String, dynamic> json) {
    return Routes(
      geometry: (json['geometry'] as List)
          .map((e) => GeoPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      maneuvers: (json['maneuvers'] as List).map((e) {
        final m = e as Map<String, dynamic>;
        return Maneuver(
          type: ManeuverType.values.firstWhere(
            (t) => t.name == m['type'],
            orElse: () => ManeuverType.straight,
          ),
          instruction: m['instruction'] as String,
          distanceMeters: (m['distance'] as num).toDouble(),
          latitude: (m['lat'] as num).toDouble(),
          longitude: (m['lon'] as num).toDouble(),
        );
      }).toList(),
      distanceMeters: (json['distance'] as num).toDouble(),
      durationSeconds: (json['duration'] as num).toDouble(),
    );
  }
}
