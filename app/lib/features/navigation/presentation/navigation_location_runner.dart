import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/entities/route.dart';
import '../domain/route_progress_tracker.dart';
import 'nav_controller.dart';

/// Drives real GPS progress along a planned route while navigation is active.
class NavigationLocationRunner {
  NavigationLocationRunner(this._ref);

  final Ref _ref;
  RouteProgressTracker? _tracker;

  bool get isRunning => _tracker != null;

  /// Requests navigation location permission and starts the GPS stream.
  Future<void> start(Routes route) async {
    stop();
    _tracker = RouteProgressTracker(route);
    _ref.read(locationServiceProvider).startNavigationSession(_onPosition);
  }

  void _onPosition(GeoPoint position) {
    final tracker = _tracker;
    if (tracker == null) return;

    final progress = tracker.update(position);
    final nav = _ref.read(navControllerProvider.notifier);

    while (_ref.read(navControllerProvider).nextManeuverIndex <
        progress.nextManeuverIndex) {
      final before = _ref.read(navControllerProvider).nextManeuverIndex;
      nav.advanceManeuver();
      if (_ref.read(navControllerProvider).nextManeuverIndex == before) break;
    }

    if (progress.arrived) {
      while (_ref.read(navControllerProvider).phase == NavPhase.navigating) {
        final before = _ref.read(navControllerProvider).nextManeuverIndex;
        nav.advanceManeuver();
        if (_ref.read(navControllerProvider).nextManeuverIndex == before) {
          break;
        }
      }
      stop();
      return;
    }

    nav.updateDistance(progress.distanceToManeuverMeters);
  }

  void stop() {
    _tracker = null;
    _ref.read(locationServiceProvider).stopNavigationSession();
  }
}

final navigationLocationRunnerProvider =
    Provider<NavigationLocationRunner>((ref) {
  return NavigationLocationRunner(ref);
});
