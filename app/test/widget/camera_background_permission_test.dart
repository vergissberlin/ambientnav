import 'package:ambientnav/core/di/providers.dart';
import 'package:ambientnav/core/camera/camera_service.dart';
import 'package:ambientnav/core/l10n/app_localizations.dart';
import 'package:ambientnav/core/permissions/permission_service.dart';
import 'package:ambientnav/core/settings/camera_background_settings.dart';
import 'package:ambientnav/features/settings/presentation/settings_screen.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

class FakePermissionService extends PermissionService {
  FakePermissionService(this.granted);

  final bool granted;
  int cameraRequests = 0;

  @override
  Future<bool> ensureCameraPermission() async {
    cameraRequests += 1;
    return granted;
  }
}

class FakeCameraService extends CameraService {
  FakeCameraService(this.cameras);

  final List<CameraDescription> cameras;

  @override
  Future<List<CameraDescription>> availableCameras() async => cameras;
}

void main() {
  testWidgets('requests camera permission before enabling the background', (
    tester,
  ) async {
    final permissionService = FakePermissionService(false);
    final cameraService = FakeCameraService([
      const CameraDescription(
        name: 'back',
        lensDirection: CameraLensDirection.back,
        sensorOrientation: 90,
      ),
    ]);

    await pumpApp(
      tester,
      const SettingsScreen(),
      overrides: [
        cameraServiceProvider.overrideWithValue(cameraService),
        permissionServiceProvider.overrideWithValue(permissionService),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cameraNavBackgroundSwitch')));
    await tester.pumpAndSettle();

    expect(permissionService.cameraRequests, 1);

    final context = tester.element(find.byType(SettingsScreen));
    final l10n = AppLocalizations.of(context);
    final container = ProviderScope.containerOf(context, listen: false);
    expect(container.read(cameraBackgroundEnabledProvider), isFalse);
    expect(container.read(cameraBackgroundPermissionDeniedProvider), isTrue);
    expect(find.text(l10n.cameraNavBackgroundPermissionDenied), findsOneWidget);
  });

  testWidgets(
    'enables the simulated background without requesting permission when no camera exists',
    (tester) async {
      final permissionService = FakePermissionService(false);
      final cameraService = FakeCameraService(const []);

      await pumpApp(
        tester,
        const SettingsScreen(),
        overrides: [
          cameraServiceProvider.overrideWithValue(cameraService),
          permissionServiceProvider.overrideWithValue(permissionService),
        ],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cameraNavBackgroundSwitch')));
      await tester.pumpAndSettle();

      expect(permissionService.cameraRequests, 0);

      final context = tester.element(find.byType(SettingsScreen));
      final container = ProviderScope.containerOf(context, listen: false);
      expect(container.read(cameraBackgroundEnabledProvider), isTrue);
      expect(container.read(cameraBackgroundPermissionDeniedProvider), isFalse);
      expect(container.read(cameraBackgroundNoCameraAvailableProvider), isTrue);
      expect(
        find.text(AppLocalizations.of(context).cameraNavBackgroundNoCamera),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shows a transparency slider only after enabling the camera background',
    (tester) async {
      final permissionService = FakePermissionService(true);
      final cameraService = FakeCameraService([
        const CameraDescription(
          name: 'back',
          lensDirection: CameraLensDirection.back,
          sensorOrientation: 90,
        ),
      ]);

      await pumpApp(
        tester,
        const SettingsScreen(),
        overrides: [
          cameraServiceProvider.overrideWithValue(cameraService),
          permissionServiceProvider.overrideWithValue(permissionService),
        ],
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('cameraNavBackgroundTransparencySlider')),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('cameraNavBackgroundSwitch')));
      await tester.pumpAndSettle();

      final slider = find.byKey(
        const Key('cameraNavBackgroundTransparencySlider'),
      );
      expect(slider, findsOneWidget);

      final context = tester.element(find.byType(SettingsScreen));
      final container = ProviderScope.containerOf(context, listen: false);
      expect(
        container.read(cameraBackgroundTransparencyProvider),
        closeTo(0.72, 0.001),
      );

      await tester.drag(slider, const Offset(200, 0));
      await tester.pumpAndSettle();

      expect(
        container.read(cameraBackgroundTransparencyProvider),
        greaterThan(0.72),
      );
    },
  );
}
