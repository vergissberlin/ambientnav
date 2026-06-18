import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../features/navigation/domain/entities/route.dart';

/// Wraps `geolocator` for one-shot fixes and continuous navigation sessions.
class LocationService {
  StreamSubscription<GeoPoint>? _navigationSub;

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

  /// Requests location permission when navigation starts. Accepts while-in-use
  /// or always; optionally prompts for always to improve background reliability.
  Future<bool> ensureNavigationPermission() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;

      final whenInUse = await Permission.locationWhenInUse.request();
      if (!whenInUse.isGranted) return false;

      // Optional upgrade — user may keep "while using".
      await Permission.locationAlways.request();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Continuous high-accuracy fixes for active turn-by-turn navigation.
  Stream<GeoPoint> navigationPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: _navigationLocationSettings(),
    ).map((pos) => GeoPoint(pos.latitude, pos.longitude));
  }

  /// Starts listening to [navigationPositionStream] and forwards fixes.
  void startNavigationSession(void Function(GeoPoint position) onPosition) {
    stopNavigationSession();
    _navigationSub = navigationPositionStream().listen(onPosition);
  }

  /// Stops the active navigation location stream.
  void stopNavigationSession() {
    _navigationSub?.cancel();
    _navigationSub = null;
  }

  LocationSettings _navigationLocationSettings() {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 5,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText:
              'AmbientNav is navigating in the background.',
          notificationTitle: 'Navigation active',
          enableWakeLock: true,
        ),
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5,
    );
  }
}
