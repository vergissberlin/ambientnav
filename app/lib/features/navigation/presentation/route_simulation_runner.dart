import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/route.dart';
import '../domain/route_simulator.dart';
import 'nav_controller.dart';
import 'simulated_position.dart';

/// Drives the [RouteSimulator] with a periodic timer, feeding the simulated
/// progress into [navControllerProvider] and publishing the virtual position to
/// [simulatedPositionProvider]. Used only in the dev route-simulation mode.
class RouteSimulationRunner {
  RouteSimulationRunner(this._ref);

  final Ref _ref;
  Timer? _timer;
  RouteSimulator? _sim;

  static const Duration tickInterval = Duration(milliseconds: 200);
  static const double _dt = 0.2;

  bool get isRunning => _timer != null;

  void start(Routes route, {double speedMps = 13.9}) {
    stop();
    if (route.geometry.isEmpty && route.maneuvers.isEmpty) return;
    _sim = RouteSimulator(route, speedMps: speedMps);
    _timer = Timer.periodic(tickInterval, (_) => _onTick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _sim = null;
    _ref.read(simulatedPositionProvider.notifier).state = null;
  }

  void _onTick() {
    final sim = _sim;
    if (sim == null) return;
    final step = sim.step(_dt);
    _ref.read(simulatedPositionProvider.notifier).state =
        SimPose(position: step.position, bearingDeg: step.bearingDeg);

    final nav = _ref.read(navControllerProvider.notifier);

    // Advance the controller's maneuver pointer to match the simulator.
    while (_ref.read(navControllerProvider).nextManeuverIndex <
        step.nextManeuverIndex) {
      final before = _ref.read(navControllerProvider).nextManeuverIndex;
      nav.advanceManeuver();
      if (_ref.read(navControllerProvider).nextManeuverIndex == before) break;
    }

    if (step.arrived) {
      // Exhaust the remaining maneuvers so the state reaches "arrived".
      while (_ref.read(navControllerProvider).phase == NavPhase.navigating) {
        final before = _ref.read(navControllerProvider).nextManeuverIndex;
        nav.advanceManeuver();
        if (_ref.read(navControllerProvider).nextManeuverIndex == before) break;
      }
      stop();
      return;
    }

    nav.updateDistance(step.distanceToManeuverMeters);
  }
}

final routeSimulationRunnerProvider =
    Provider<RouteSimulationRunner>((ref) => RouteSimulationRunner(ref));
