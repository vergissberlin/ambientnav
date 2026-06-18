import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../controllers/domain/entities/controller_role.dart';
import '../../controllers/presentation/controllers_controller.dart';
import '../domain/usecases/maneuver_to_ble_command.dart';
import 'nav_controller.dart';

/// App-level listener for navigation side effects (voice + BLE) that must keep
/// running when the user leaves the map tab or backgrounds the app.
class NavigationEffectsListener extends ConsumerWidget {
  const NavigationEffectsListener({super.key, required this.child});

  final Widget child;

  static const _maneuverToCommand = ManeuverToBleCommand();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<NavigationState>(navControllerProvider, (prev, next) {
      final maneuver = next.nextManeuver;
      if (next.phase != NavPhase.navigating || maneuver == null) return;
      if (prev?.nextManeuver == maneuver) return;

      try {
        ref.read(voiceGuidanceServiceProvider).speak(maneuver.instruction);
      } catch (_) {}

      final command =
          _maneuverToCommand(maneuver, next.distanceToManeuverMeters);
      final controllers = ref.read(controllersControllerProvider).devices;
      for (final c in controllers) {
        if (c.isConnected && c.role == ControllerRole.front) {
          ref.read(controllerRepositoryProvider).sendNavCommand(c.id, command);
        }
      }
    });

    return child;
  }
}
