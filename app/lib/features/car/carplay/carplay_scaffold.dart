import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../car_session_state.dart';

/// CarPlay integration scaffold.
///
/// Status: basic scaffold. A full CarPlay navigation app requires the Apple
/// CarPlay entitlement (manually provisioned) and renders via native templates
/// (`CPMapTemplate` + a maneuver banner), not arbitrary Flutter widgets. The
/// native glue lives in `ios/Runner/CarPlaySceneDelegate.swift`; this Dart side
/// reads [carSessionStateProvider] from a headless container and forwards the
/// next-maneuver snapshot to the native template over a MethodChannel.
///
/// Wiring the `flutter_carplay` package + entitlement is a follow-up; this class
/// captures the data contract so the integration is ready to drop in.
class CarPlayScaffold {
  CarPlayScaffold(this._container);

  final ProviderContainer _container;

  /// The latest snapshot to push to the CarPlay template.
  CarSessionState get session => _container.read(carSessionStateProvider);

  /// Begin observing navigation updates; [onUpdate] would push to the native
  /// CarPlay template.
  ProviderSubscription<CarSessionState> listen(
    void Function(CarSessionState) onUpdate,
  ) {
    return _container.listen<CarSessionState>(
      carSessionStateProvider,
      (_, next) => onUpdate(next),
      fireImmediately: true,
    );
  }
}
