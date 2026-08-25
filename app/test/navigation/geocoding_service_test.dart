import 'package:ambientnav/features/navigation/data/geocoding_service.dart';
import 'package:ambientnav/features/navigation/domain/entities/route.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  const origin = GeoPoint(52.5200, 13.4050);

  group('GeocodingService.parse', () {
    test('maps a Nominatim jsonv2 response to GeoResults', () {
      final json = [
        {
          'display_name': 'Berlin Hauptbahnhof, Mitte, Berlin, Germany',
          'lat': '52.5251',
          'lon': '13.3694',
        },
        {'display_name': 'Berlin, Germany', 'lat': '52.5200', 'lon': '13.4050'},
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

  group('GeocodingService.search', () {
    test('sorts results by distance to the origin', () async {
      final dio = _MockDio();
      final service = GeocodingService(dio: dio);
      final json = [
        {
          'display_name': 'Far Place',
          'lat': '48.1371',
          'lon': '11.5754',
        },
        {
          'display_name': 'Near Place',
          'lat': '52.5208',
          'lon': '13.4095',
        },
      ];

      when(
        () => dio.get<List<dynamic>>(
          'https://nominatim.openstreetmap.org/search',
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<List<dynamic>>(
          requestOptions: RequestOptions(path: '/search'),
          data: json,
        ),
      );

      final results = await service.search('A.T.U.', origin: origin);

      expect(results.map((r) => r.label), ['Near Place', 'Far Place']);
    });

    test('keeps API order when origin is not available', () async {
      final dio = _MockDio();
      final service = GeocodingService(dio: dio);
      final json = [
        {
          'display_name': 'First Result',
          'lat': '48.1371',
          'lon': '11.5754',
        },
        {
          'display_name': 'Second Result',
          'lat': '52.5208',
          'lon': '13.4095',
        },
      ];

      when(
        () => dio.get<List<dynamic>>(
          'https://nominatim.openstreetmap.org/search',
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<List<dynamic>>(
          requestOptions: RequestOptions(path: '/search'),
          data: json,
        ),
      );

      final results = await service.search('A.T.U.');

      expect(results.map((r) => r.label), ['First Result', 'Second Result']);
    });
  });
}
