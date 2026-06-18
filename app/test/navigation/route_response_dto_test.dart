import 'package:ambientnav/features/navigation/data/dto/route_response_dto.dart';
import 'package:ambientnav/features/navigation/domain/entities/maneuver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('decodePolyline', () {
    test('decodes the classic precision-5 example', () {
      final points = RouteResponseDto.decodePolyline(
        '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
      );
      expect(points.length, 3);
      expect(points.first.latitude, closeTo(38.5, 1e-5));
      expect(points.first.longitude, closeTo(-120.2, 1e-5));
      expect(points.last.latitude, closeTo(43.252, 1e-3));
    });
  });

  group('OSRM parsing', () {
    test('parses geometry, maneuvers, distance and duration', () {
      final json = {
        'routes': [
          {
            'distance': 1234.5,
            'duration': 567.8,
            'geometry': '_p~iF~ps|U_ulLnnqC',
            'legs': [
              {
                'steps': [
                  {
                    'name': 'Main St',
                    'distance': 100.0,
                    'maneuver': {
                      'type': 'depart',
                      'location': [-120.2, 38.5],
                    },
                  },
                  {
                    'name': 'Second Ave',
                    'distance': 250.0,
                    'maneuver': {
                      'type': 'turn',
                      'modifier': 'left',
                      'location': [-120.95, 40.7],
                    },
                  },
                ],
              },
            ],
          },
        ],
      };
      final route = RouteResponseDto.fromOsrm(json);
      expect(route.distanceMeters, 1234.5);
      expect(route.durationSeconds, 567.8);
      expect(route.geometry.length, 2);
      expect(route.maneuvers.length, 2);
      expect(route.maneuvers[0].type, ManeuverType.depart);
      expect(route.maneuvers[1].type, ManeuverType.turnLeft);
      expect(route.maneuvers[1].distanceMeters, 250.0);
    });

    test('throws when no routes present', () {
      expect(() => RouteResponseDto.fromOsrm({'routes': []}),
          throwsFormatException);
    });
  });

  group('Valhalla parsing', () {
    test('parses trip legs into maneuvers and km->m conversion', () {
      final json = {
        'trip': {
          'summary': {'length': 1.5, 'time': 300.0},
          'legs': [
            {
              'shape': '_p~iF~ps|U_ulLnnqC',
              'maneuvers': [
                {
                  'type': 1,
                  'instruction': 'Drive east.',
                  'length': 0.5,
                  'begin_shape_index': 0,
                },
                {
                  'type': 15,
                  'instruction': 'Turn left.',
                  'length': 1.0,
                  'begin_shape_index': 1,
                },
              ],
            },
          ],
        },
      };
      final route = RouteResponseDto.fromValhalla(json);
      expect(route.distanceMeters, 1500.0); // 1.5 km
      expect(route.maneuvers.first.type, ManeuverType.depart);
      expect(route.maneuvers[1].type, ManeuverType.turnLeft);
      expect(route.maneuvers.first.distanceMeters, 500.0); // 0.5 km
    });
  });
}
