import 'package:ambientnav/features/navigation/data/geocoding_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GeocodingService.parse', () {
    test('maps a Nominatim jsonv2 response to GeoResults', () {
      final json = [
        {
          'display_name': 'Berlin Hauptbahnhof, Mitte, Berlin, Germany',
          'lat': '52.5251',
          'lon': '13.3694',
        },
        {
          'display_name': 'Berlin, Germany',
          'lat': '52.5200',
          'lon': '13.4050',
        },
      ];
      final results = GeocodingService.parse(json);
      expect(results.length, 2);
      expect(results.first.label, contains('Hauptbahnhof'));
      expect(results.first.point.latitude, closeTo(52.5251, 1e-4));
      expect(results.first.point.longitude, closeTo(13.3694, 1e-4));
    });

    test('skips entries with missing or invalid coordinates', () {
      final json = [
        {'display_name': 'No coords'},
        {'display_name': '', 'lat': '1.0', 'lon': '2.0'},
        {'display_name': 'Bad', 'lat': 'abc', 'lon': '2.0'},
      ];
      expect(GeocodingService.parse(json), isEmpty);
    });
  });
}
