import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/controllers/data/mock/mock_controller_repository.dart';
import '../../features/controllers/domain/repositories/controller_repository.dart';
import '../security/pairing_service.dart';

/// Compile-time switch: `--dart-define=USE_MOCK=true` (default true so the app
/// runs end-to-end without hardware; CI/tests always use the mock).
const bool kUseMock = bool.fromEnvironment('USE_MOCK', defaultValue: true);

/// The controller repository. Overridden in tests with a mock; in production
/// the real BLE implementation is selected when [kUseMock] is false.
///
/// NOTE: the real `BleControllerRepository` (flutter_blue_plus) is added in a
/// follow-up; until then the mock is always used so the app is runnable.
final controllerRepositoryProvider = Provider<ControllerRepository>((ref) {
  return MockControllerRepository();
});

final pairingServiceProvider = Provider<PairingService>((ref) {
  return PairingService(ref.watch(controllerRepositoryProvider));
});
