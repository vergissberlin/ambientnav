// StateNotifier / StateNotifierProvider / StateProvider moved to
// legacy.dart in Riverpod 3. Tracked for migration to Notifier.
import 'package:flutter_riverpod/legacy.dart';

import '../domain/entities/route.dart';

/// The virtual vehicle pose (position + travel heading) while the dev
/// route-simulation mode is active, or null when not simulating.
class SimPose {
  const SimPose({required this.position, required this.bearingDeg});
  final GeoPoint position;
  final double bearingDeg;
}

/// Live simulated pose; the map follows it and shows a "SIM" badge.
final simulatedPositionProvider = StateProvider<SimPose?>((ref) => null);

/// How the navigation camera behaves.
enum CameraMode {
  /// Heading-up, zoomed-in follow of the current position.
  follow,

  /// Whole route framed (north-up overview).
  overview,
}

/// Current camera mode while navigating. Defaults to [CameraMode.follow].
final cameraModeProvider = StateProvider<CameraMode>(
  (ref) => CameraMode.follow,
);

/// Whether the simulated front-strip preview's hazard lights are toggled on.
/// UI-only — this drives [FrontLedStripPreview], not real hardware; the app
/// has no BLE hazard command wired up (see `nav_command.dart`'s `Blinker`
/// enum, which the app never sends anything but `Blinker.off` for today).
final hazardPreviewProvider = StateProvider<bool>((ref) => false);

/// The scripted danger-spot's geometry (see `route_simulation_runner.dart`),
/// so the map screen can draw it — null when not simulating or once the
/// simulation has stopped.
final hazardZoneGeometryProvider = StateProvider<List<GeoPoint>?>(
  (ref) => null,
);
