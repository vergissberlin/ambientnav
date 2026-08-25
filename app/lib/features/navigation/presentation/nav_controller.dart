// StateNotifier / StateNotifierProvider / StateProvider moved to
// legacy.dart in Riverpod 3. Tracked for migration to Notifier.
import 'package:flutter_riverpod/legacy.dart';

import '../domain/entities/maneuver.dart';
import '../domain/entities/route.dart';

/// Phase of a navigation session.
enum NavPhase { idle, planning, navigating, arrived, rerouting }

/// Immutable navigation state shared by the phone UI and the CarPlay /
/// Android Auto heads (one source of truth).
class NavigationState {
  const NavigationState({
    this.phase = NavPhase.idle,
    this.route,
    this.nextManeuverIndex = 0,
    this.distanceToManeuverMeters = 0,
    this.speedMps = 13.9,
    this.offlineReady = false,
    this.error,
  });

  final NavPhase phase;
  final Routes? route;
  final int nextManeuverIndex;
  final double distanceToManeuverMeters;

  /// Current travel speed, used to convert the front-strip preview's
  /// maneuver-lead time window into a distance threshold (see
  /// `map_screen.dart`'s `_stripEffectFor`). Defaults to the dev route
  /// simulator's own default (~50 km/h) and is kept in sync with it via
  /// [NavController.setSpeedMps]; real GPS navigation doesn't track live
  /// speed yet, so it stays at this default there.
  final double speedMps;
  final bool offlineReady;
  final String? error;

  Maneuver? get nextManeuver {
    final r = route;
    if (r == null || nextManeuverIndex >= r.maneuvers.length) return null;
    return r.maneuvers[nextManeuverIndex];
  }

  NavigationState copyWith({
    NavPhase? phase,
    Routes? route,
    int? nextManeuverIndex,
    double? distanceToManeuverMeters,
    double? speedMps,
    bool? offlineReady,
    String? error,
  }) {
    return NavigationState(
      phase: phase ?? this.phase,
      route: route ?? this.route,
      nextManeuverIndex: nextManeuverIndex ?? this.nextManeuverIndex,
      distanceToManeuverMeters:
          distanceToManeuverMeters ?? this.distanceToManeuverMeters,
      speedMps: speedMps ?? this.speedMps,
      offlineReady: offlineReady ?? this.offlineReady,
      error: error,
    );
  }
}

/// Drives [NavigationState]. Route planning is delegated to the routing
/// repository (wired in `core/di/providers.dart`); kept minimal here so it is
/// unit-testable without a map view.
class NavController extends StateNotifier<NavigationState> {
  NavController() : super(const NavigationState());

  void startPlanning() =>
      state = state.copyWith(phase: NavPhase.planning, error: null);

  void setRoute(Routes route) {
    // The first maneuver is always "depart" with distanceMeters == 0 (it IS
    // the route start, so there's no predecessor leg) — skip straight past
    // it so the strip/panel show the first *actionable* maneuver immediately
    // instead of one render frame of "depart" at distance 0, which would
    // otherwise flash before the location/simulation runner's first tick
    // corrects it a moment later.
    var index = 0;
    var cumulative = 0.0;
    for (; index < route.maneuvers.length; index++) {
      cumulative += route.maneuvers[index].distanceMeters;
      if (cumulative > 0) break;
    }
    final pastEnd = index >= route.maneuvers.length;
    state = NavigationState(
      phase: NavPhase.navigating,
      route: route,
      nextManeuverIndex: pastEnd ? route.maneuvers.length - 1 : index,
      distanceToManeuverMeters: pastEnd ? 0 : cumulative,
    );
  }

  void advanceManeuver() {
    final r = state.route;
    if (r == null) return;
    final next = state.nextManeuverIndex + 1;
    if (next >= r.maneuvers.length) {
      state = state.copyWith(phase: NavPhase.arrived);
      return;
    }
    state = state.copyWith(
      nextManeuverIndex: next,
      distanceToManeuverMeters: r.maneuvers[next].distanceMeters,
    );
  }

  void updateDistance(double meters) =>
      state = state.copyWith(distanceToManeuverMeters: meters);

  void setSpeedMps(double mps) => state = state.copyWith(speedMps: mps);

  void markOfflineReady() => state = state.copyWith(offlineReady: true);

  void stop() => state = const NavigationState();

  void fail(String message) =>
      state = state.copyWith(phase: NavPhase.idle, error: message);
}

final navControllerProvider =
    StateNotifierProvider<NavController, NavigationState>(
      (ref) => NavController(),
    );
