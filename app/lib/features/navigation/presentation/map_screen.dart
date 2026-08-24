import 'dart:async';

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

  /// The route currently backing [_routeLine] — lets `_drawRouteLine` skip
  /// work on ticks that only changed progress/distance, not the route
  /// itself. Without this it removed+re-added the whole polyline on every
  /// single position update (every ~200ms in the simulator).
  Routes? _drawnRoute;

  /// Two stacked lines (wide+blurred, then narrower+blurred) tracing the
  /// portion of the route already driven — a glow layered on top of the
  /// plain [_routeLine], which supplies the sharp core. Both share one
  /// geometry, updated together.
  Line? _traveledGlowOuter;
  Line? _traveledGlowMid;

  /// `distanceAlongMeters` the glow lines were last drawn at. Updates are
  /// skipped for movements smaller than [_glowUpdateMinDeltaMeters] — a
  /// driving car doesn't need the glow re-sent to the platform channel every
  /// single GPS fix or 200ms sim tick.
  double _lastGlowDistanceAlong = -1;
  static const double _glowUpdateMinDeltaMeters = 5;

  /// Re-entrancy guards: `ref.listen` can fire again before a prior
  /// `_updateTraveledGlow`/`_drawRouteLine` call's awaited platform-channel
  /// round trips finish. Without this, two overlapping calls could both see
  /// a glow line as "not yet created" and both create it, or one could
  /// `removeLine` an annotation the other is mid-`updateLine` on — which
  /// throws `you can only set existing annotations` and, at sim-tick
  /// frequency, floods the log and burns CPU on repeated failed calls.
  bool _glowBusy = false;
  bool _glowPending = false;
  bool _routeLineBusy = false;
  bool _routeLinePending = false;

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
    _drawnRoute = null;
    _simCircle = null;
    _traveledGlowOuter = null;
    _traveledGlowMid = null;
    _lastGlowDistanceAlong = -1;
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

  /// Draw (or redraw) the route polyline — without moving the camera. A
  /// no-op when [route] is unchanged from the last draw (see [_drawnRoute]),
  /// so pure progress/distance ticks don't touch this annotation at all.
  Future<void> _drawRouteLine() async {
    if (_routeLineBusy) {
      _routeLinePending = true;
      return;
    }
    _routeLineBusy = true;
    try {
      await _drawRouteLineImpl();
    } finally {
      _routeLineBusy = false;
      if (_routeLinePending) {
        _routeLinePending = false;
        unawaited(_drawRouteLine());
      }
    }
  }

  Future<void> _drawRouteLineImpl() async {
    final controller = _mapController;
    final route = ref.read(navControllerProvider).route;
    if (controller == null || !_styleLoaded) return;
    if (identical(route, _drawnRoute)) return;
    _drawnRoute = route;
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

  /// Redraw the "already driven" glow to match the latest progress — two
  /// stacked lines (wide+blurred, then narrower+blurred) over the plain
  /// route line, from the route start up to
  /// [NavigationState.distanceAlongMeters]. Coalesces overlapping calls (see
  /// [_glowBusy]) and skips sub-[_glowUpdateMinDeltaMeters] movements.
  Future<void> _updateTraveledGlow() async {
    if (_glowBusy) {
      _glowPending = true;
      return;
    }
    _glowBusy = true;
    try {
      await _updateTraveledGlowImpl();
    } finally {
      _glowBusy = false;
      if (_glowPending) {
        _glowPending = false;
        unawaited(_updateTraveledGlow());
      }
    }
  }

  Future<void> _updateTraveledGlowImpl() async {
    final controller = _mapController;
    if (controller == null || !_styleLoaded) return;
    final navState = ref.read(navControllerProvider);
    final route = navState.route;
    final distanceAlong = navState.distanceAlongMeters;
    if (route == null || route.geometry.length < 2) {
      await _removeTraveledGlow();
      return;
    }
    final coords = _traveledCoordinates(route.geometry, distanceAlong);
    if (coords.length < 2) {
      await _removeTraveledGlow();
      return;
    }
    // Skip the platform-channel round trip for imperceptibly small moves —
    // but never for the first draw or right after a reset.
    if (_traveledGlowOuter != null &&
        (distanceAlong - _lastGlowDistanceAlong).abs() <
            _glowUpdateMinDeltaMeters) {
      return;
    }
    _lastGlowDistanceAlong = distanceAlong;
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
    } else {
      await Future.wait([
        controller.updateLine(
          _traveledGlowOuter!,
          LineOptions(geometry: geometry),
        ),
        controller.updateLine(
          _traveledGlowMid!,
          LineOptions(geometry: geometry),
        ),
      ]);
    }
  }

  Future<void> _removeTraveledGlow() async {
    final controller = _mapController;
    if (controller == null) return;
    _lastGlowDistanceAlong = -1;
    if (_traveledGlowOuter != null) {
      final line = _traveledGlowOuter!;
      _traveledGlowOuter = null;
      await controller.removeLine(line);
    }
    if (_traveledGlowMid != null) {
      final line = _traveledGlowMid!;
      _traveledGlowMid = null;
      await controller.removeLine(line);
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
