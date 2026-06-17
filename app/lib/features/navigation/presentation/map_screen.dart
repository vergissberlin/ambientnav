import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'nav_controller.dart';
import 'turn_by_turn_panel.dart';

/// Default MapLibre style (demo tiles). Replace with a self-hosted / OSM style
/// for production; kept here so the map renders out of the box.
const String kDefaultStyleUrl = 'https://demotiles.maplibre.org/style.json';

/// The main navigation screen: a MapLibre map with the next-maneuver banner and
/// route geometry overlaid.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapLibreMapController? _mapController;
  Line? _routeLine;

  Future<void> _drawRoute() async {
    final controller = _mapController;
    final route = ref.read(navControllerProvider).route;
    if (controller == null || route == null) return;
    if (_routeLine != null) {
      await controller.removeLine(_routeLine!);
      _routeLine = null;
    }
    if (route.geometry.isEmpty) return;
    _routeLine = await controller.addLine(
      LineOptions(
        geometry: [
          for (final p in route.geometry) LatLng(p.latitude, p.longitude),
        ],
        lineColor: '#FFB300',
        lineWidth: 5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final navState = ref.watch(navControllerProvider);

    ref.listen(navControllerProvider, (_, __) => _drawRoute());

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navTab),
        actions: [
          if (navState.offlineReady)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.offline_pin),
            ),
        ],
      ),
      body: Stack(
        children: [
          MapLibreMap(
            styleString: kDefaultStyleUrl,
            initialCameraPosition: const CameraPosition(
              target: LatLng(52.52, 13.405), // Berlin
              zoom: 11,
            ),
            onMapCreated: (c) => _mapController = c,
            onStyleLoadedCallback: _drawRoute,
            myLocationEnabled: true,
          ),
          Align(
            alignment: Alignment.topCenter,
            child: TurnByTurnPanel(
              maneuver: navState.nextManeuver,
              distanceMeters: navState.distanceToManeuverMeters,
            ),
          ),
        ],
      ),
    );
  }
}
