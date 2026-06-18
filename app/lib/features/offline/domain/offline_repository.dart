import '../../navigation/domain/entities/route.dart';

/// Downloads offline map data so a planned route works without connectivity.
abstract interface class OfflineRepository {
  /// Download the map region covering [route]'s bounding box (with padding).
  /// [onProgress] reports 0.0 … 1.0.
  Future<void> downloadRegionForRoute(
    Routes route, {
    void Function(double progress)? onProgress,
  });
}
