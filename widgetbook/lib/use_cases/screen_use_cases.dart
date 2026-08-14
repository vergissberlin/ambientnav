import 'package:ambientnav/core/di/providers.dart';
import 'package:ambientnav/features/controllers/data/mock/mock_controller_repository.dart';
import 'package:ambientnav/features/controllers/presentation/controllers_controller.dart';
import 'package:ambientnav/features/controllers/presentation/controllers_list_screen.dart';
import 'package:ambientnav/features/controllers/presentation/led_config_form.dart';
import 'package:ambientnav/features/controllers/presentation/pairing_screen.dart';
import 'package:ambientnav/features/controllers/presentation/sensor_calibration_form.dart';
import 'package:ambientnav/features/navigation/presentation/search_screen.dart';
import 'package:ambientnav/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgetbook/widgetbook.dart';

import '../support/fixture_geocoding_service.dart';
import '../support/use_case_scope.dart';

/// Provider-bound organisms and whole screens.
///
/// These stay where they are in `features/**/presentation/` — catalogued, never
/// moved. Screens are the one tier where relocating files would cause real
/// import churn for no benefit.
List<WidgetbookNode> providerBoundOrganisms() => [
  _ledConfigForm,
  _sensorCalibrationForm,
  _pairingDialog,
];

List<WidgetbookNode> screens() => [
  _settingsScreen,
  _controllersListScreen,
  _searchScreen,
];

// ── LedConfigForm ────────────────────────────────────────────────────────────

final _ledConfigForm = WidgetbookComponent(
  name: 'LedConfigForm',
  useCases: [
    WidgetbookUseCase(
      // The form returns a bare ListView, so it needs a Scaffold ancestor —
      // the same reason led_config_form_test.dart wraps it in one.
      name: 'Paired (writes succeed)',
      builder: (context) => const MockRepoScope(
        child: Scaffold(
          body: LedConfigForm(deviceId: MockControllerRepository.frontId),
        ),
      ),
    ),
    WidgetbookUseCase(
      // Saving here surfaces NotPairedException as l10n.notPaired — a path
      // that otherwise needs an unpaired physical controller.
      name: 'Not paired (save is rejected)',
      builder: (context) => const MockRepoScope(
        paired: false,
        child: Scaffold(
          body: LedConfigForm(deviceId: MockControllerRepository.frontId),
        ),
      ),
    ),
  ],
);

// ── SensorCalibrationForm ────────────────────────────────────────────────────

final _sensorCalibrationForm = WidgetbookComponent(
  name: 'SensorCalibrationForm',
  useCases: [
    WidgetbookUseCase(
      // Sensor config lives on the rear controller.
      name: 'Paired rear controller',
      builder: (context) => const MockRepoScope(
        deviceId: MockControllerRepository.rearId,
        child: Scaffold(
          body: SensorCalibrationForm(
            deviceId: MockControllerRepository.rearId,
          ),
        ),
      ),
    ),
  ],
);

// ── PairingDialog ────────────────────────────────────────────────────────────

final _pairingDialog = WidgetbookComponent(
  name: 'PairingDialog',
  useCases: [
    WidgetbookUseCase(
      // Rendered inline rather than through PairingDialog.show, which needs a
      // Navigator push the catalogue has no route for. The mock accepts 123456.
      name: 'Passkey entry',
      builder: (context) => const MockRepoScope(
        paired: false,
        child: Center(
          child: PairingDialog(deviceId: MockControllerRepository.frontId),
        ),
      ),
    ),
  ],
);

// ── SettingsScreen ───────────────────────────────────────────────────────────

final _settingsScreen = WidgetbookComponent(
  name: 'SettingsScreen',
  useCases: [
    WidgetbookUseCase(
      // Only needs localStoreProvider — themeController and the simulation
      // switch both read from it.
      name: 'Default',
      builder: (context) => const UseCaseScope(child: SettingsScreen()),
    ),
  ],
);

// ── ControllersListScreen ────────────────────────────────────────────────────

final _controllersListScreen = WidgetbookComponent(
  name: 'ControllersListScreen',
  useCases: [
    WidgetbookUseCase(
      name: 'Empty (before scanning)',
      builder: (context) => const MockRepoScope(child: ControllersListScreen()),
    ),
    WidgetbookUseCase(
      // The mock stages its two devices over ~300ms, so the list fills in a
      // moment after the use case opens.
      name: 'Scanning',
      builder: (context) =>
          const MockRepoScope(child: _AutoScan(child: ControllersListScreen())),
    ),
  ],
);

/// Kicks off a scan after the first frame, so the list populates without the
/// reviewer having to press the FAB.
class _AutoScan extends ConsumerStatefulWidget {
  const _AutoScan({required this.child});

  final Widget child;

  @override
  ConsumerState<_AutoScan> createState() => _AutoScanState();
}

class _AutoScanState extends ConsumerState<_AutoScan> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(controllersControllerProvider.notifier).startScan();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ── SearchScreen ─────────────────────────────────────────────────────────────

final _searchScreen = WidgetbookComponent(
  name: 'SearchScreen',
  useCases: [
    WidgetbookUseCase(
      // FixtureGeocodingService is required, not convenience: the real service
      // queries Nominatim on every keystroke, and its usage policy forbids
      // automated querying.
      name: 'Offline fixtures',
      builder: (context) => UseCaseScope(
        overrides: [
          geocodingServiceProvider.overrideWithValue(FixtureGeocodingService()),
        ],
        child: const Scaffold(body: SearchScreen()),
      ),
    ),
  ],
);
