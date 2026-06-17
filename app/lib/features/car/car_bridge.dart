import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'car_session_state.dart';

/// Forwards the shared [CarSessionState] to the native CarPlay / Android Auto
/// heads over a platform channel.
///
/// The phone UI and the car heads share one source of truth
/// ([carSessionStateProvider]); this bridge is the thin transport. The native
/// sides (CarPlay `CPMapTemplate`, Android Auto `NavigationTemplate`) render the
/// forwarded snapshot — see `app/docs/car-integration.md` for enabling them.
class CarBridge {
  CarBridge(this._container,
      {MethodChannel channel =
          const MethodChannel('digital.thinkport.ambientnav/car')})
      : _channel = channel;

  final ProviderContainer _container;
  final MethodChannel _channel;
  ProviderSubscription<CarSessionState>? _sub;

  /// Begin forwarding navigation snapshots to the native car heads.
  void start() {
    _sub = _container.listen<CarSessionState>(
      carSessionStateProvider,
      (_, next) => _send(next),
      fireImmediately: true,
    );
  }

  void dispose() {
    _sub?.close();
    _sub = null;
  }

  /// Serialize a snapshot to the wire map sent to native.
  static Map<String, dynamic> encode(CarSessionState s) => {
        'isNavigating': s.isNavigating,
        'maneuver': s.nextManeuver?.type.name,
        'instruction': s.nextManeuver?.instruction ?? '',
        'distanceMeters': s.distanceToManeuverMeters,
      };

  Future<void> _send(CarSessionState state) async {
    try {
      await _channel.invokeMethod('updateSession', encode(state));
    } on MissingPluginException {
      // No car head attached on this platform — ignore.
    } on PlatformException {
      // Native side not ready / no active car scene — ignore.
    }
  }
}
