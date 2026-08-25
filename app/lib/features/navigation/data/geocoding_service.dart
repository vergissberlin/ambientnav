import 'package:dio/dio.dart';

import '../../../core/utils/geo.dart';
import '../domain/entities/route.dart';

/// A geocoded place: a human-readable [label] and its coordinate.
class GeoResult {
  const GeoResult({required this.label, required this.point});
  final String label;
  final GeoPoint point;

  @override
  bool operator ==(Object other) =>
      other is GeoResult && other.label == label && other.point == point;

  @override
  int get hashCode => Object.hash(label, point);
}

/// Forward geocoding via OpenStreetMap Nominatim (free, no key).
///
/// Security/etiquette: HTTPS only and a descriptive User-Agent, per the
/// Nominatim usage policy. For production, host your own Nominatim and swap the
/// base URL.
class GeocodingService {
  GeocodingService({
    Dio? dio,
    this.baseUrl = 'https://nominatim.openstreetmap.org',
  }) : assert(baseUrl.startsWith('https://'), 'Geocoding must use HTTPS'),
       _dio = dio ?? Dio();

  final Dio _dio;
  final String baseUrl;

  Future<List<GeoResult>> search(
    String query, {
    int limit = 5,
    GeoPoint? origin,
  }) async {
    if (query.trim().isEmpty) return const [];
    final res = await _dio.get<List<dynamic>>(
      '$baseUrl/search',
      queryParameters: {'q': query, 'format': 'jsonv2', 'limit': limit},
      options: Options(headers: {'User-Agent': 'AmbientNav/0.4 (flutter app)'}),
    );
    final results = parse(res.data ?? const []);
    if (origin == null) return results;
    final indexed = results.asMap().entries.toList();
    indexed.sort((a, b) {
      final da = Geo.haversineMeters(origin, a.value.point);
      final db = Geo.haversineMeters(origin, b.value.point);
      final byDistance = da.compareTo(db);
      return byDistance != 0 ? byDistance : a.key.compareTo(b.key);
    });
    return [for (final entry in indexed) entry.value];
  }

  /// Pure parser for a Nominatim `jsonv2` response — unit-tested.
  static List<GeoResult> parse(List<dynamic> json) {
    final out = <GeoResult>[];
    for (final item in json) {
      final m = item as Map<String, dynamic>;
      final lat = double.tryParse('${m['lat']}');
      final lon = double.tryParse('${m['lon']}');
      final label = (m['display_name'] as String?)?.trim() ?? '';
      if (lat == null || lon == null || label.isEmpty) continue;
      out.add(GeoResult(label: label, point: GeoPoint(lat, lon)));
    }
    return out;
  }
}
