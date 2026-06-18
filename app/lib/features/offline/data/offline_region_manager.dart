import 'package:maplibre_gl/maplibre_gl.dart';

import '../../navigation/domain/entities/route.dart';
import '../domain/offline_repository.dart';

/// MapLibre-backed [OfflineRepository]. Wraps `downloadOfflineRegion` so the
/// rest of the app stays free of the plugin's API surface (flagged as a
/// maturity risk in the plan).
class OfflineRegionManager implements OfflineRepository {
  OfflineRegionManager({
    required this.styleUrl,
    this.minZoom = 6,
    this.maxZoom = 16,
    this.paddingDegrees = 0.02,
  });

  /// MapLibre style URL (OSM-based tiles).
  final String styleUrl;
  final double minZoom;
  final double maxZoom;

  /// Bounding-box padding so the corridor around the route is covered.
  final double paddingDegrees;

  @override
  Future<void> downloadRegionForRoute(
    Routes route, {
    void Function(double progress)? onProgress,
  }) async {
    final box = route.boundingBox;
    final sw = box[0];
    final ne = box[1];
    final bounds = LatLngBounds(
      southwest: LatLng(
        sw.latitude - paddingDegrees,
        sw.longitude - paddingDegrees,
      ),
      northeast: LatLng(
        ne.latitude + paddingDegrees,
        ne.longitude + paddingDegrees,
      ),
    );

    await downloadOfflineRegion(
      OfflineRegionDefinition(
        bounds: bounds,
        mapStyleUrl: styleUrl,
        minZoom: minZoom,
        maxZoom: maxZoom,
      ),
      metadata: {'name': 'route-${DateTime.now().millisecondsSinceEpoch}'},
      onEvent: (event) {
        if (event is InProgress) {
          onProgress?.call(event.progress / 100.0);
        } else if (event is Success) {
          onProgress?.call(1.0);
        }
      },
    );
  }
}
