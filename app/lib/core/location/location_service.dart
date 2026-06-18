import 'package:geolocator/geolocator.dart';

import '../../features/navigation/domain/entities/route.dart';

/// Wraps `geolocator` to get the device's current position as a [GeoPoint],
/// requesting permission as needed. Returns null when location is unavailable
/// or denied so callers can fall back (e.g. to the map centre) — important on
/// the simulator, which may have no GPS fix.
class LocationService {
  const LocationService();

  Future<GeoPoint?> currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      return GeoPoint(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }
}
