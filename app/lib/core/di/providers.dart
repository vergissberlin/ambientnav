import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/controllers/data/ble/ble_controller_repository.dart';
import '../../features/controllers/data/mock/mock_controller_repository.dart';
import '../../features/controllers/domain/repositories/controller_repository.dart';
import '../../features/navigation/data/geocoding_service.dart';
import '../../features/navigation/data/route_cache_store.dart';
import '../../features/navigation/data/routing_api.dart';
import '../../features/navigation/data/routing_repository_impl.dart';
import '../../features/navigation/domain/repositories/routing_repository.dart';
import '../../features/navigation/presentation/voice/voice_guidance_service.dart';
import '../../features/offline/data/offline_region_manager.dart';
import '../../features/offline/domain/offline_repository.dart';
import '../location/location_service.dart';
import '../security/pairing_service.dart';
import '../theme/theme_controller.dart';

/// Compile-time switch: `--dart-define=USE_MOCK=true` (default true so the app
/// runs end-to-end without hardware; CI/tests always use the mock).
const bool kUseMock = bool.fromEnvironment('USE_MOCK', defaultValue: true);

/// The controller repository. Overridden in tests with the mock; in production
/// the real `flutter_blue_plus` implementation is used when [kUseMock] is false.
final controllerRepositoryProvider = Provider<ControllerRepository>((ref) {
  return kUseMock ? MockControllerRepository() : BleControllerRepository();
});

final pairingServiceProvider = Provider<PairingService>((ref) {
  return PairingService(ref.watch(controllerRepositoryProvider));
});

// ── Navigation / routing ──────────────────────────────────────────────────────

/// Public OSRM demo endpoint (free, rate-limited). Swap for a self-hosted
/// Valhalla/OSRM instance in production.
final routingApiProvider = Provider<RoutingApi>((ref) {
  return RoutingApi(
    baseUrl: 'https://router.project-osrm.org',
    engine: RoutingEngine.osrm,
  );
});

final routeCacheStoreProvider = Provider<RouteCacheStore>((ref) {
  return RouteCacheStore(ref.watch(localStoreProvider));
});

final routingRepositoryProvider = Provider<RoutingRepository>((ref) {
  return RoutingRepositoryImpl(
    ref.watch(routingApiProvider),
    ref.watch(routeCacheStoreProvider),
  );
});

final geocodingServiceProvider = Provider<GeocodingService>((ref) {
  return GeocodingService();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// MapLibre style URL — OpenFreeMap Liberty (free, no API key, street detail).
const String kMapStyleUrl = 'https://tiles.openfreemap.org/styles/liberty';

final offlineRepositoryProvider = Provider<OfflineRepository>((ref) {
  return OfflineRegionManager(styleUrl: kMapStyleUrl);
});

final voiceGuidanceServiceProvider = Provider<VoiceGuidanceService>((ref) {
  return VoiceGuidanceService();
});
