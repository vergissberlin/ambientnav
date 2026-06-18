import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../domain/entities/controller_info.dart';
import '../domain/entities/telemetry.dart';
import '../domain/repositories/controller_repository.dart';

/// State of the controller-management screen.
class ControllersState {
  const ControllersState({
    this.devices = const [],
    this.isScanning = false,
    this.error,
  });

  final List<ControllerInfo> devices;
  final bool isScanning;
  final String? error;

  ControllersState copyWith({
    List<ControllerInfo>? devices,
    bool? isScanning,
    String? error,
  }) {
    return ControllersState(
      devices: devices ?? this.devices,
      isScanning: isScanning ?? this.isScanning,
      error: error,
    );
  }
}

class ControllersController extends StateNotifier<ControllersState> {
  ControllersController(this._repository) : super(const ControllersState());

  final ControllerRepository _repository;
  StreamSubscription<List<ControllerInfo>>? _scanSub;
  final Map<String, StreamSubscription<Telemetry>> _telemetrySubs = {};

  Future<void> startScan() async {
    state = state.copyWith(isScanning: true, error: null);
    await _scanSub?.cancel();
    _scanSub = _repository.scan().listen(
          (devices) => state = state.copyWith(devices: devices),
          onError: (Object e) =>
              state = state.copyWith(isScanning: false, error: e.toString()),
          onDone: () => state = state.copyWith(isScanning: false),
        );
  }

  Future<void> stopScan() async {
    await _scanSub?.cancel();
    _scanSub = null;
    await _repository.stopScan();
    state = state.copyWith(isScanning: false);
  }

  Future<void> connect(String id) async {
    await _repository.connect(id);
    _patch(id, (d) => d.copyWith(isConnected: true));
    _telemetrySubs[id] = _repository.telemetry(id).listen((t) {
      _patch(
        id,
        (d) => d.copyWith(voltage: t.voltageVolts, rssi: t.rssi),
      );
    });
  }

  Future<void> disconnect(String id) async {
    await _telemetrySubs.remove(id)?.cancel();
    await _repository.disconnect(id);
    _patch(id, (d) => d.copyWith(isConnected: false, isPaired: false));
  }

  void _patch(String id, ControllerInfo Function(ControllerInfo) update) {
    state = state.copyWith(
      devices: [
        for (final d in state.devices) d.id == id ? update(d) : d,
      ],
    );
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    for (final sub in _telemetrySubs.values) {
      sub.cancel();
    }
    super.dispose();
  }
}

final controllersControllerProvider =
    StateNotifierProvider<ControllersController, ControllersState>((ref) {
  return ControllersController(ref.watch(controllerRepositoryProvider));
});
