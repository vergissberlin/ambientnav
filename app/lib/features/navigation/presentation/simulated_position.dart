import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/route.dart';

/// The current virtual position while the dev route-simulation mode is active,
/// or null when not simulating. The map follows it and shows a "SIM" badge.
final simulatedPositionProvider = StateProvider<GeoPoint?>((ref) => null);
