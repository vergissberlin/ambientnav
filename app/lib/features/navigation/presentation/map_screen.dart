import 'package:ambientnav/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/di/providers.dart';
import '../../controllers/domain/entities/controller_role.dart';
import '../../controllers/presentation/controllers_controller.dart';
import '../domain/usecases/maneuver_to_ble_command.dart';
import '../domain/entities/route.dart';
import 'nav_controller.dart';
import 'nav_session.dart';
import 'search_screen.dart';
import 'simulated_position.dart';
import 'turn_by_turn_panel.dart';

/// The main navigation screen: a MapLibre street map with the next-maneuver
/// banner and the planned route overlaid. A search button plans a trip.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapLibreMapController? _mapController;
  Line? _routeLine;
  Circle? _simCircle;
  static const _maneuverToCommand = ManeuverToBleCommand();

  /// Move (or create) the virtual-vehicle marker and follow it.
  Future<void> _updateSimPosition(GeoPoint? p) async {
    final controller = _mapController;
    if (controller == null) return;
    if (p == null) {
      if (_simCircle != null) {
        await controller.removeCircle(_simCircle!);
        _simCircle = null;
      }
      return;
    }
    final latLng = LatLng(p.latitude, p.longitude);
    if (_simCircle == null) {
      _simCircle = await controller.addCircle(CircleOptions(
        geometry: latLng,
        circleRadius: 8,
        circleColor: '#1E88E5',
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 2,
      ));
    } else {
      await controller.updateCircle(
          _simCircle!, CircleOptions(geometry: latLng));
    }
    await controller.animateCamera(CameraUpdate.newLatLng(latLng));
  }

  Future<void> _drawRoute() async {
    final controller = _mapController;
    final route = ref.read(navControllerProvider).route;
    if (controller == null) return;
    if (_routeLine != null) {
      await controller.removeLine(_routeLine!);
      _routeLine = null;
    }
    if (route == null || route.geometry.isEmpty) return;
    _routeLine = await controller.addLine(
      LineOptions(
        geometry: [
          for (final p in route.geometry) LatLng(p.latitude, p.longitude),
        ],
        lineColor: '#FFB300',
        lineWidth: 5,
      ),
    );
    // Frame the route.
    final box = route.boundingBox;
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(box[0].latitude, box[0].longitude),
          northeast: LatLng(box[1].latitude, box[1].longitude),
        ),
        left: 40,
        right: 40,
        top: 120,
        bottom: 80,
      ),
    );
  }

  Future<void> _openSearch() async {
    final result = await SearchScreen.show(context);
    if (result == null) return;
    await ref.read(navSessionProvider).planTo(result);
    final error = ref.read(navControllerProvider).error;
    if (error != null && mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.noRouteFound)));
    }
  }

  /// Speak the maneuver and push it to a connected front controller's LEDs.
  void _onManeuver(NavigationState? prev, NavigationState next) {
    _drawRoute();
    final maneuver = next.nextManeuver;
    if (next.phase != NavPhase.navigating || maneuver == null) return;
    if (prev?.nextManeuver == maneuver) return;

    // Voice guidance (guarded — TTS plugin may be absent in tests).
    try {
      ref.read(voiceGuidanceServiceProvider).speak(maneuver.instruction);
    } catch (_) {}

    // Forward to a connected front controller, if any.
    final command = _maneuverToCommand(maneuver, next.distanceToManeuverMeters);
    final controllers = ref.read(controllersControllerProvider).devices;
    for (final c in controllers) {
      if (c.isConnected && c.role == ControllerRole.front) {
        ref.read(controllerRepositoryProvider).sendNavCommand(c.id, command);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final navState = ref.watch(navControllerProvider);
    final isNavigating = navState.phase == NavPhase.navigating;
    final simulating = ref.watch(simulatedPositionProvider) != null;

    ref.listen(navControllerProvider, _onManeuver);
    ref.listen(simulatedPositionProvider, (_, p) => _updateSimPosition(p));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navTab),
        actions: [
          if (simulating)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Chip(
                label: Text('SIM'),
                visualDensity: VisualDensity.compact,
              ),
            ),
          if (navState.offlineReady)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.offline_pin),
            ),
          if (isNavigating)
            IconButton(
              tooltip: l10n.downloadOffline,
              icon: const Icon(Icons.download_for_offline),
              onPressed: () => ref.read(navSessionProvider).downloadOffline(),
            ),
        ],
      ),
      floatingActionButton: isNavigating
          ? FloatingActionButton.extended(
              onPressed: () => ref.read(navSessionProvider).stop(),
              icon: const Icon(Icons.close),
              label: Text(l10n.stopNavigation),
            )
          : FloatingActionButton.extended(
              onPressed: _openSearch,
              icon: const Icon(Icons.search),
              label: Text(l10n.searchDestination),
            ),
      body: Stack(
        children: [
          MapLibreMap(
            styleString: kMapStyleUrl,
            initialCameraPosition: const CameraPosition(
              target: LatLng(52.52, 13.405), // Berlin
              zoom: 12,
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
