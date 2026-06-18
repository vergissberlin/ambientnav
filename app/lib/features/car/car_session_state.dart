import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../navigation/domain/entities/maneuver.dart';
import '../navigation/domain/entities/route.dart';
import '../navigation/presentation/nav_controller.dart';

/// Minimal navigation snapshot consumed by the CarPlay / Android Auto heads.
///
/// Both car integrations run a headless [ProviderContainer] and read this
/// derived provider, so the phone UI and the car UI share one source of truth.
class CarSessionState {
  const CarSessionState({
    required this.isNavigating,
    this.nextManeuver,
    this.distanceToManeuverMeters = 0,
    this.routeGeometry = const [],
  });

  final bool isNavigating;
  final Maneuver? nextManeuver;
  final double distanceToManeuverMeters;
  final List<GeoPoint> routeGeometry;
}

/// Derives the car snapshot from the shared navigation state.
final carSessionStateProvider = Provider<CarSessionState>((ref) {
  final nav = ref.watch(navControllerProvider);
  return CarSessionState(
    isNavigating: nav.phase == NavPhase.navigating,
    nextManeuver: nav.nextManeuver,
    distanceToManeuverMeters: nav.distanceToManeuverMeters,
    routeGeometry: nav.route?.geometry ?? const [],
  );
});
