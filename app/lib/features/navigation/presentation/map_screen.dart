import 'package:ambientnav/core/l10n/app_localizations.dart';
import 'package:ambientnav_ui/ambientnav_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/geo.dart';
import '../domain/entities/route.dart';
import 'nav_controller.dart';
import 'nav_session.dart';
import 'search_screen.dart';
import 'simulated_position.dart';
import '../../../ui/molecules/turn_by_turn_panel.dart';

/// The main navigation screen: a MapLibre street map with the next-maneuver
/// banner and the planned route overlaid. While navigating the camera follows
/// the position heading-up; a button toggles a whole-route overview.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapLibreMapController? _mapController;
  Line? _routeLine;
  Circle? _simCircle;

  /// Three stacked lines (wide+blurred to narrow+sharp) tracing the portion
  /// of the route already driven — a glow effect layered on top of the plain
  /// [_routeLine]. All three share one geometry, updated together.
  Line? _traveledGlowOuter;
  Line? _traveledGlowMid;
  Line? _traveledGlowCore;

  /// Annotations may only be added once the style has loaded — since
  /// maplibre_gl 0.24.1 the annotation managers are initialised explicitly and
  /// `addLine`/`addCircle` throw before that, where they used to no-op. The
  /// provider listeners below can fire between `onMapCreated` and
  /// `onStyleLoadedCallback`, so every annotation call is gated on this.
  bool _styleLoaded = false;

  /// The map widget is keyed on the style URL, so switching theme rebuilds it
  /// from scratch. Drop the controller and the now-dangling annotation handles
  /// so they are recreated against the new style rather than removed by id.
  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
    _styleLoaded = false;
    _routeLine = null;
    _simCircle = null;
    _traveledGlowOuter = null;
    _traveledGlowMid = null;
    _traveledGlowCore = null;
  }

  Future<void> _onStyleLoaded() async {
    _styleLoaded = true;
    await _drawRouteLine();
    await _updateTraveledGlow();
    await _updateSimPosition(ref.read(simulatedPositionProvider));
  }

  String _navErrorMessage(AppLocalizations l10n, String? error) {
    switch (error) {
      case 'no-route':
        return l10n.noRouteFound;
      case 'location-permission-denied':
        return l10n.locationPermissionDenied;
      default:
        return error ?? l10n.noRouteFound;
    }
  }

  /// Closer zoom as the next maneuver approaches, so the intersection is legible.
  double _followZoom(double distanceToManeuver) =>
      distanceToManeuver < 150 ? 17.5 : 16.5;

  /// Draw (or redraw) the route polyline — without moving the camera.
  Future<void> _drawRouteLine() async {
    final controller = _mapController;
    final route = ref.read(navControllerProvider).route;
    if (controller == null || !_styleLoaded) return;
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
        lineColor: AnColors.cyanHex,
        lineWidth: 5,
      ),
    );
  }

  /// Redraw the "already driven" glow to match the latest progress —
  /// three stacked lines (wide+blurred under narrow+sharp) over the plain
  /// route line, from the route start up to [NavigationState.distanceAlongMeters].
  Future<void> _updateTraveledGlow() async {
    final controller = _mapController;
    if (controller == null || !_styleLoaded) return;
    final navState = ref.read(navControllerProvider);
    final route = navState.route;
    if (route == null || route.geometry.length < 2) {
      await _removeTraveledGlow();
      return;
    }
    final coords = _traveledCoordinates(
      route.geometry,
      navState.distanceAlongMeters,
    );
    if (coords.length < 2) {
      await _removeTraveledGlow();
      return;
    }
    final geometry = [for (final p in coords) LatLng(p.latitude, p.longitude)];
    if (_traveledGlowOuter == null) {
      _traveledGlowOuter = await controller.addLine(
        LineOptions(
          geometry: geometry,
          lineColor: AnColors.cyanHex,
          lineWidth: 14,
          lineBlur: 6,
          lineOpacity: 0.22,
        ),
      );
      _traveledGlowMid = await controller.addLine(
        LineOptions(
          geometry: geometry,
          lineColor: AnColors.cyanHex,
          lineWidth: 8,
          lineBlur: 3,
          lineOpacity: 0.45,
        ),
      );
      _traveledGlowCore = await controller.addLine(
        LineOptions(
          geometry: geometry,
          lineColor: AnColors.cyanHex,
          lineWidth: 5,
        ),
      );
    } else {
      await controller.updateLine(
        _traveledGlowOuter!,
        LineOptions(geometry: geometry),
      );
      await controller.updateLine(
        _traveledGlowMid!,
        LineOptions(geometry: geometry),
      );
      await controller.updateLine(
        _traveledGlowCore!,
        LineOptions(geometry: geometry),
      );
    }
  }

  Future<void> _removeTraveledGlow() async {
    final controller = _mapController;
    if (controller == null) return;
    if (_traveledGlowOuter != null) {
      await controller.removeLine(_traveledGlowOuter!);
      _traveledGlowOuter = null;
    }
    if (_traveledGlowMid != null) {
      await controller.removeLine(_traveledGlowMid!);
      _traveledGlowMid = null;
    }
    if (_traveledGlowCore != null) {
      await controller.removeLine(_traveledGlowCore!);
      _traveledGlowCore = null;
    }
  }

  /// The route's coordinates from the start up to [traveledMeters], ending
  /// exactly at the interpolated point so the glow's tip tracks smoothly
  /// between vertices rather than jumping from one to the next.
  List<GeoPoint> _traveledCoordinates(
    List<GeoPoint> geometry,
    double traveledMeters,
  ) {
    if (traveledMeters <= 0) return const [];
    final cumulative = Geo.cumulativeDistances(geometry);
    final out = <GeoPoint>[geometry.first];
    for (var i = 1; i < geometry.length; i++) {
      if (cumulative[i] >= traveledMeters) break;
      out.add(geometry[i]);
    }
    out.add(Geo.interpolateAlong(geometry, traveledMeters));
    return out;
  }

  /// Frame the whole route (overview).
  Future<void> _fitRouteBounds() async {
    final controller = _mapController;
    final route = ref.read(navControllerProvider).route;
    if (controller == null || route == null || route.geometry.isEmpty) return;
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

  /// Move (or create) the virtual-vehicle marker and, in follow mode, keep the
  /// camera centred + oriented in the travel direction.
  Future<void> _updateSimPosition(SimPose? pose) async {
    final controller = _mapController;
    if (controller == null || !_styleLoaded) return;
    if (pose == null) {
      if (_simCircle != null) {
        await controller.removeCircle(_simCircle!);
        _simCircle = null;
      }
      return;
    }
    final latLng = LatLng(pose.position.latitude, pose.position.longitude);
    if (_simCircle == null) {
      _simCircle = await controller.addCircle(
        CircleOptions(
          geometry: latLng,
          circleRadius: 8,
          circleColor: AnColors.violetHex,
          circleStrokeColor: AnColors.whiteHex,
          circleStrokeWidth: 2,
        ),
      );
    } else {
      await controller.updateCircle(
        _simCircle!,
        CircleOptions(geometry: latLng),
      );
    }
    if (ref.read(cameraModeProvider) == CameraMode.follow) {
      final dist = ref.read(navControllerProvider).distanceToManeuverMeters;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: latLng,
            bearing: pose.bearingDeg,
            tilt: 50,
            zoom: _followZoom(dist),
          ),
        ),
      );
    }
  }

  Future<void> _openSearch() async {
    final result = await SearchScreen.show(context);
    if (result == null) return;
    await ref.read(navSessionProvider).planTo(result);
    final error = ref.read(navControllerProvider).error;
    if (error != null && mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_navErrorMessage(l10n, error))));
    }
  }

  void _toggleOverview() {
    final notifier = ref.read(cameraModeProvider.notifier);
    if (ref.read(cameraModeProvider) == CameraMode.overview) {
      notifier.state = CameraMode.follow;
      // Re-centre immediately on the latest simulated pose, if any.
      _updateSimPosition(ref.read(simulatedPositionProvider));
    } else {
      notifier.state = CameraMode.overview;
      _fitRouteBounds();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final styleUrl = isDark ? kMapStyleUrlDark : kMapStyleUrl;
    final navState = ref.watch(navControllerProvider);
    final isNavigating = navState.phase == NavPhase.navigating;
    final simulating = ref.watch(simulatedPositionProvider) != null;
    final cameraMode = ref.watch(cameraModeProvider);
    final following = cameraMode == CameraMode.follow;

    ref.listen(navControllerProvider, (_, _) {
      _drawRouteLine();
      _updateTraveledGlow();
    });
    ref.listen(simulatedPositionProvider, (_, p) => _updateSimPosition(p));

    // Real-GPS heading-up follow is handled natively by MapLibre; the simulator
    // drives the camera manually (its position isn't the OS location).
    final trackingMode = (isNavigating && following && !simulating)
        ? MyLocationTrackingMode.trackingGps
        : MyLocationTrackingMode.none;

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
              tooltip: following ? l10n.routeOverview : l10n.followRoute,
              icon: Icon(following ? Icons.alt_route : Icons.navigation),
              onPressed: _toggleOverview,
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
            key: ValueKey(styleUrl),
            styleString: styleUrl,
            initialCameraPosition: const CameraPosition(
              target: LatLng(52.52, 13.405), // Berlin
              zoom: 12,
            ),
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            myLocationEnabled: true,
            myLocationTrackingMode: trackingMode,
            myLocationRenderMode: trackingMode == MyLocationTrackingMode.none
                ? MyLocationRenderMode.normal
                : MyLocationRenderMode.compass,
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
