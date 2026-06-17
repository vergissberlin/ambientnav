import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../car_session_state.dart';

/// Android Auto integration scaffold.
///
/// Status: basic scaffold. Android Auto navigation apps use the Jetpack Car App
/// Library (`androidx.car.app`) with a `NavigationTemplate`, implemented as a
/// native `CarAppService` (`android/app/src/main/.../AmbientNavCarAppService.kt`).
/// Flutter has no first-class Auto plugin, so the native service bridges to Dart
/// via a MethodChannel that reads [carSessionStateProvider].
///
/// This class captures the shared data contract; the native service + channel
/// are a follow-up.
class AndroidAutoScaffold {
  AndroidAutoScaffold(this._container);

  final ProviderContainer _container;

  CarSessionState get session => _container.read(carSessionStateProvider);

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
