import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../data/geocoding_service.dart';
import '../domain/entities/route.dart';
import 'nav_controller.dart';

/// Orchestrates planning a trip: resolve the origin (device GPS, with a
/// fallback), call the routing repository, and push the result into
/// [navControllerProvider]. UI-independent so it is unit-testable without map /
/// TTS / GPS plugins.
class NavSession {
  NavSession(this._ref);

  final Ref _ref;

  /// Fallback origin (Berlin) when no GPS fix is available — keeps the flow
  /// usable on a simulator without a simulated location.
  static const GeoPoint fallbackOrigin = GeoPoint(52.52, 13.405);

  Future<void> planTo(GeoResult destination, {GeoPoint? originOverride}) async {
    final nav = _ref.read(navControllerProvider.notifier);
    nav.startPlanning();
    try {
      final origin = originOverride ??
          await _ref.read(locationServiceProvider).currentPosition() ??
          fallbackOrigin;
      final route = await _ref
          .read(routingRepositoryProvider)
          .planRoute(origin, destination.point);
      if (route.maneuvers.isEmpty && route.geometry.isEmpty) {
        nav.fail('no-route');
        return;
      }
      nav.setRoute(route);
    } catch (e) {
      nav.fail(e.toString());
    }
  }

  void stop() => _ref.read(navControllerProvider.notifier).stop();

  /// Download the planned route's map region for offline use.
  Future<void> downloadOffline({void Function(double)? onProgress}) async {
    final route = _ref.read(navControllerProvider).route;
    if (route == null) return;
    await _ref
        .read(offlineRepositoryProvider)
        .downloadRegionForRoute(route, onProgress: onProgress);
    _ref.read(navControllerProvider.notifier).markOfflineReady();
  }
}

final navSessionProvider = Provider<NavSession>((ref) => NavSession(ref));
