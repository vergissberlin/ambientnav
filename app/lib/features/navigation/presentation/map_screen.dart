import 'dart:async';
import 'dart:ui';

import 'package:ambientnav/core/l10n/app_localizations.dart';
import 'package:ambientnav_ui/ambientnav_ui.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/di/providers.dart';
import '../../../core/settings/camera_background_settings.dart';
import '../../../ui/molecules/front_led_strip_preview.dart';
import '../../../ui/molecules/simulated_camera_background.dart';
import '../../../ui/molecules/turn_by_turn_panel.dart';
import '../domain/entities/maneuver.dart';
import '../domain/entities/route.dart';
import 'nav_controller.dart';
import 'nav_session.dart';
import 'search_screen.dart';
import 'simulated_position.dart';

/// The main navigation screen: a MapLibre street map with the next-maneuver
/// banner and the planned route overlaid. While navigating the camera follows
/// the position heading-up; a button toggles a whole-route overview.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with WidgetsBindingObserver {
  MapLibreMapController? _mapController;
  Line? _routeLine;
  Line? _hazardZoneLine;
  Circle? _simCircle;

  /// True for a few seconds right after [NavPhase.arrived] is reached, so the
  /// strip gets one last "destination reached" flourish instead of just
  /// disappearing the instant [isNavigating] flips false.
  bool _celebrateArrival = false;
  Timer? _arrivalTimer;

  /// Live feed for the optional blurred navigation background. Only opened
  /// while [cameraBackgroundEnabledProvider] is on, and released whenever the
  /// app is backgrounded — it's an exclusively-held hardware handle.
  CameraController? _cameraController;
  bool _cameraInitializing = false;

  /// True once [_initCameraBackground] has found zero cameras on this device
  /// — the iOS Simulator and most Android emulators have no camera hardware,
  /// which would otherwise make the feature undemonstrable outside a real
  /// device. Drives [SimulatedCameraBackground] instead of a plain basemap
  /// fallback.
  bool _cameraSimulated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (ref.read(cameraBackgroundEnabledProvider)) {
      _initCameraBackground();
    }
  }

  @override
  void dispose() {
    _arrivalTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _disposeCameraBackground();
    } else if (state == AppLifecycleState.resumed &&
        ref.read(cameraBackgroundEnabledProvider)) {
      _initCameraBackground();
    }
  }

  /// Opens the rear camera for the blurred navigation background. When the
  /// device has no camera at all (the iOS Simulator, most Android emulators)
  /// falls back to [SimulatedCameraBackground] instead of a plain basemap, so
  /// the feature stays demonstrable in dev. Any other failure (revoked
  /// permission, already in use elsewhere) falls back to the normal basemap.
  Future<void> _initCameraBackground() async {
    if (_cameraController != null || _cameraSimulated || _cameraInitializing) {
      return;
    }
    _cameraInitializing = true;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _cameraSimulated = true);
        return;
      }
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _cameraController = controller);
    } catch (_) {
      // Camera unavailable — the map falls back to the full basemap below.
    } finally {
      _cameraInitializing = false;
    }
  }

  Future<void> _disposeCameraBackground() async {
    final controller = _cameraController;
    _cameraController = null;
    final wasSimulated = _cameraSimulated;
    _cameraSimulated = false;
    if (controller == null && !wasSimulated) return;
    if (mounted) setState(() {});
    await controller?.dispose();
  }

  /// A full-bleed, aspect-correct camera preview (the plugin's own
  /// [CameraPreview] doesn't crop to fill), blurred so it reads as ambience
  /// rather than a sharp video feed behind the roads/route graphic.
  Widget _buildBlurredCameraPreview(CameraController controller) {
    final previewSize = controller.value.previewSize;
    final preview = previewSize == null
        ? CameraPreview(controller)
        : FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: previewSize.height,
              height: previewSize.width,
              child: CameraPreview(controller),
            ),
          );
    return _blurred(preview);
  }

  Widget _blurred(Widget child) {
    return Positioned.fill(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: child,
      ),
    );
  }

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
    _hazardZoneLine = null;
    _simCircle = null;
  }

  Future<void> _onStyleLoaded() async {
    _styleLoaded = true;
    await _drawRouteLine();
    await _drawHazardZone(ref.read(hazardZoneGeometryProvider));
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

  /// Draw (or redraw) the scripted danger-spot segment from
  /// [hazardZoneGeometryProvider] — null hides it (simulation stopped or not
  /// yet started).
  Future<void> _drawHazardZone(List<GeoPoint>? geometry) async {
    final controller = _mapController;
    if (controller == null || !_styleLoaded) return;
    if (_hazardZoneLine != null) {
      await controller.removeLine(_hazardZoneLine!);
      _hazardZoneLine = null;
    }
    if (geometry == null || geometry.length < 2) return;
    _hazardZoneLine = await controller.addLine(
      LineOptions(
        geometry: [for (final p in geometry) LatLng(p.latitude, p.longitude)],
        lineColor: AnColors.magentaHex,
        lineWidth: 7,
      ),
    );
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

  /// Time (seconds) before a maneuver at which the strip starts signalling
  /// it, converted to a distance via [NavigationState.speedMps] so it
  /// reliably starts ~20s out regardless of driving speed. Firmware's own
  /// `orchestrator.cpp` uses a fixed 200m; the app deliberately shows it
  /// earlier and speed-aware, so the driver gets consistent advance notice
  /// on the phone preview.
  static const double _maneuverLeadSeconds = 20;

  /// Which effect the front strip preview shows right now (plus, for
  /// [FrontStripEffect.arriving], how far its centre-out fill has grown): an
  /// upcoming maneuver within [_maneuverLeadSeconds] always wins over
  /// hazard, which wins over [FrontStripEffect.off] — once a maneuver is
  /// passed (or hazard is toggled off), the strip goes dark rather than
  /// idling on [FrontStripEffect.ambient], which firmware would show but
  /// reads as visual noise on a phone screen between turns. Back-to-back
  /// maneuvers need no special case: once the current one is passed,
  /// [NavigationState.nextManeuver]/[NavigationState.distanceToManeuverMeters]
  /// already point at the following one, so if that one is also within the
  /// lead window its direction shows immediately instead of a dark gap.
  ({FrontStripEffect effect, double progress}) _stripEffectFor(
    NavigationState navState,
    bool hazard,
  ) {
    final maneuver = navState.nextManeuver;
    final leadMeters = navState.speedMps * _maneuverLeadSeconds;
    if (maneuver != null && navState.distanceToManeuverMeters < leadMeters) {
      switch (maneuver.type) {
        case ManeuverType.turnLeft:
        case ManeuverType.slightLeft:
          return (effect: FrontStripEffect.navLeft, progress: 1);
        case ManeuverType.turnRight:
        case ManeuverType.slightRight:
          return (effect: FrontStripEffect.navRight, progress: 1);
        case ManeuverType.straight:
        case ManeuverType.depart:
          return (effect: FrontStripEffect.navStraight, progress: 1);
        case ManeuverType.newName:
          return (effect: FrontStripEffect.navContinue, progress: 1);
        case ManeuverType.arrive:
          // Cap the growth window to this final leg's own length (distance
          // from the previous maneuver to the destination) when it's
          // shorter than the usual lead distance — otherwise a destination
          // just past a turn would start the fill already half (or more)
          // grown instead of from a single centre pixel.
          final legLength = maneuver.distanceMeters;
          final growthWindow = legLength > 0 && legLength < leadMeters
              ? legLength
              : leadMeters;
          final progress = growthWindow > 0
              ? (1 - navState.distanceToManeuverMeters / growthWindow).clamp(
                  0.0,
                  1.0,
                )
              : 1.0;
          return (effect: FrontStripEffect.arriving, progress: progress);
        case ManeuverType.uturn:
        case ManeuverType.roundabout:
          break; // no direction — fall through to hazard/off
      }
    }
    return (
      effect: hazard ? FrontStripEffect.hazard : FrontStripEffect.off,
      progress: 1,
    );
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
    final hazardActive = ref.watch(hazardPreviewProvider);
    final (:effect, :progress) = _stripEffectFor(navState, hazardActive);
    final stripEffect = _celebrateArrival ? FrontStripEffect.arriving : effect;
    final stripProgress = _celebrateArrival ? 1.0 : progress;
    final cameraBackgroundEnabled = ref.watch(cameraBackgroundEnabledProvider);
    final showCameraBackground =
        cameraBackgroundEnabled &&
        ((_cameraController?.value.isInitialized ?? false) || _cameraSimulated);

    ref.listen<bool>(cameraBackgroundEnabledProvider, (_, enabled) {
      if (enabled) {
        _initCameraBackground();
      } else {
        _disposeCameraBackground();
      }
    });
    ref.listen(navControllerProvider, (_, _) => _drawRouteLine());
    ref.listen(simulatedPositionProvider, (_, p) => _updateSimPosition(p));
    ref.listen(
      hazardZoneGeometryProvider,
      (_, geometry) => _drawHazardZone(geometry),
    );
    ref.listen<NavPhase>(navControllerProvider.select((s) => s.phase), (
      prev,
      next,
    ) {
      if (next == NavPhase.arrived && prev != NavPhase.arrived) {
        _arrivalTimer?.cancel();
        setState(() => _celebrateArrival = true);
        _arrivalTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _celebrateArrival = false);
        });
      } else if (next == NavPhase.idle && _celebrateArrival) {
        // Stopped manually mid-celebration (e.g. the FAB) — don't leave the
        // strip animating over an otherwise-empty screen.
        _arrivalTimer?.cancel();
        setState(() => _celebrateArrival = false);
      }
    });

    // Real-GPS heading-up follow is handled natively by MapLibre; the simulator
    // drives the camera manually (its position isn't the OS location).
    final trackingMode = (isNavigating && following && !simulating)
        ? MyLocationTrackingMode.trackingGps
        : MyLocationTrackingMode.none;

    // Roads/route only, transparent basemap when the camera background is
    // showing, so it — half-transparent below — lets the blur through.
    final effectiveStyleUrl = showCameraBackground
        ? kMapStyleUrlTransparent
        : styleUrl;
    final map = MapLibreMap(
      key: ValueKey(effectiveStyleUrl),
      styleString: effectiveStyleUrl,
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
    );

    final appBar = AnAppBar(
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
        if (isNavigating)
          IconButton(
            tooltip: l10n.toggleHazardLights,
            isSelected: hazardActive,
            icon: const Icon(Icons.warning_amber_rounded),
            onPressed: () =>
                ref.read(hazardPreviewProvider.notifier).state = !hazardActive,
          ),
      ],
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: appBar,
      // See the matching comment in controllers_list_screen.dart — the outer
      // HomeShell's `extendBody: true` otherwise lands this FAB behind the
      // glass bottom nav bar.
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: isNavigating
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
      ),
      body: Stack(
        children: [
          if (showCameraBackground)
            _cameraController != null
                ? _buildBlurredCameraPreview(_cameraController!)
                : _blurred(
                    SimulatedCameraBackground(speedMps: navState.speedMps),
                  ),
          showCameraBackground ? Opacity(opacity: 0.65, child: map) : map,
          Padding(
            padding: EdgeInsets.only(
              top:
                  MediaQuery.paddingOf(context).top +
                  appBar.preferredSize.height,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TurnByTurnPanel(
                    maneuver: navState.nextManeuver,
                    distanceMeters: navState.distanceToManeuverMeters,
                  ),
                  if (isNavigating || _celebrateArrival)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: FrontLedStripPreview(
                        effect: stripEffect,
                        progress: stripProgress,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
