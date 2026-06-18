import 'package:flutter_riverpod/flutter_riverpod.dart';

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
final cameraModeProvider =
    StateProvider<CameraMode>((ref) => CameraMode.follow);
