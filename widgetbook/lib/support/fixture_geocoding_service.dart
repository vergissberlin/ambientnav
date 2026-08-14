import 'package:ambientnav/features/navigation/data/geocoding_service.dart';
import 'package:ambientnav/features/navigation/domain/entities/route.dart';

/// Offline stand-in for [GeocodingService].
///
/// This is not just convenience — it is required. The real service queries
/// Nominatim on every keystroke, and Nominatim's usage policy forbids
/// automated querying. Without this, opening the SearchScreen use case (or
/// running the catalogue smoke test in CI) would fire real traffic at a free
/// public endpoint.
///
/// No app change was needed: `search` is an overridable instance method.
class FixtureGeocodingService extends GeocodingService {
  FixtureGeocodingService({this.delay = const Duration(milliseconds: 400)});

  /// Roughly the latency the debounced field is designed around, so the
  /// spinner is actually visible.
  final Duration delay;

  static const List<GeoResult> _places = [
    GeoResult(
      label: 'Leipzig Hauptbahnhof, Leipzig, Sachsen, Deutschland',
      point: GeoPoint(51.3454, 12.3811),
    ),
    GeoResult(
      label: 'Zoo Leipzig, Pfaffendorfer Straße, Leipzig',
      point: GeoPoint(51.3466, 12.3707),
    ),
    GeoResult(
      label: 'Völkerschlachtdenkmal, Leipzig',
      point: GeoPoint(51.3122, 12.4131),
    ),
    GeoResult(
      label: 'Karl-Heine-Straße, Leipzig-Plagwitz',
      point: GeoPoint(51.3306, 12.3392),
    ),
  ];

  @override
  Future<List<GeoResult>> search(String query, {int limit = 5}) async {
    await Future<void>.delayed(delay);
    if (query.trim().isEmpty) return const [];
    return _places.take(limit).toList();
  }
}
