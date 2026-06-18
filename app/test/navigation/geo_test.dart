import 'package:ambientnav/core/utils/geo.dart';
import 'package:ambientnav/features/navigation/domain/entities/route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Geo.haversineMeters', () {
    test('matches a known distance (Berlin ~ 1 km apart)', () {
      // 0.009 degrees latitude ≈ ~1001 m.
      const a = GeoPoint(52.5200, 13.4050);
      const b = GeoPoint(52.5290, 13.4050);
      expect(Geo.haversineMeters(a, b), closeTo(1001, 5));
    });

    test('is zero for identical points', () {
      expect(Geo.haversineMeters(const GeoPoint(1, 2), const GeoPoint(1, 2)),
          closeTo(0, 1e-6));
    });
  });

  group('Geo.initialBearing', () {
    test('points north for a due-north step', () {
      final b = Geo.initialBearing(
          const GeoPoint(52.0, 13.0), const GeoPoint(52.01, 13.0));
      expect(b, closeTo(0, 1));
    });

    test('points east for a due-east step', () {
      final b = Geo.initialBearing(
          const GeoPoint(52.0, 13.0), const GeoPoint(52.0, 13.01));
      expect(b, closeTo(90, 1));
    });
  });

  group('Geo.interpolateAlong', () {
    final line = const [
      GeoPoint(0, 0),
      GeoPoint(0, 0.001),
      GeoPoint(0, 0.002),
    ];

    test('clamps to endpoints', () {
      expect(Geo.interpolateAlong(line, -10), line.first);
      expect(Geo.interpolateAlong(line, 1e9), line.last);
    });

    test('midpoint lands between the vertices', () {
      final total = Geo.polylineLength(line);
      final mid = Geo.interpolateAlong(line, total / 2);
      expect(mid.longitude, closeTo(0.001, 1e-4));
    });
  });
}
