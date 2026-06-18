import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    this.offlineReady = false,
    this.error,
  });

  final NavPhase phase;
  final Routes? route;
  final int nextManeuverIndex;
  final double distanceToManeuverMeters;
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
    bool? offlineReady,
    String? error,
  }) {
    return NavigationState(
      phase: phase ?? this.phase,
      route: route ?? this.route,
      nextManeuverIndex: nextManeuverIndex ?? this.nextManeuverIndex,
      distanceToManeuverMeters:
          distanceToManeuverMeters ?? this.distanceToManeuverMeters,
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
    state = NavigationState(
      phase: NavPhase.navigating,
      route: route,
      nextManeuverIndex: 0,
      distanceToManeuverMeters:
          route.maneuvers.isNotEmpty ? route.maneuvers.first.distanceMeters : 0,
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

  void markOfflineReady() => state = state.copyWith(offlineReady: true);

  void stop() => state = const NavigationState();

  void fail(String message) =>
      state = state.copyWith(phase: NavPhase.idle, error: message);
}

final navControllerProvider =
    StateNotifierProvider<NavController, NavigationState>(
        (ref) => NavController());
