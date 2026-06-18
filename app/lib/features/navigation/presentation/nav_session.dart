import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dev/dev_settings.dart';
import '../../../core/di/providers.dart';
import '../data/geocoding_service.dart';
import '../domain/entities/route.dart';
import 'nav_controller.dart';
import 'navigation_location_runner.dart';
import 'route_simulation_runner.dart';
import 'simulated_position.dart';

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

      if (!_ref.read(simulationEnabledProvider)) {
        final granted =
            await _ref.read(locationServiceProvider).ensureNavigationPermission();
        if (!granted) {
          nav.fail('location-permission-denied');
          return;
        }
      }

      nav.setRoute(route);
      // Start each trip in heading-up follow mode.
      _ref.read(cameraModeProvider.notifier).state = CameraMode.follow;

      if (_ref.read(simulationEnabledProvider)) {
        // Dev: drive a virtual vehicle along the route instead of real GPS.
        try {
          _ref.read(routeSimulationRunnerProvider).start(route);
        } catch (_) {}
      } else {
        await _ref.read(navigationLocationRunnerProvider).start(route);
      }
    } catch (e) {
      nav.fail(e.toString());
    }
  }

  void stop() {
    _ref.read(routeSimulationRunnerProvider).stop();
    _ref.read(navigationLocationRunnerProvider).stop();
    _ref.read(cameraModeProvider.notifier).state = CameraMode.follow;
    _ref.read(navControllerProvider.notifier).stop();
  }

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
