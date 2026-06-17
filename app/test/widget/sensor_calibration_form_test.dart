import 'package:ambientnav/core/di/providers.dart';
import 'package:ambientnav/features/controllers/data/mock/mock_controller_repository.dart';
import 'package:ambientnav/features/controllers/domain/entities/sensor_config.dart';
import 'package:ambientnav/features/controllers/presentation/sensor_calibration_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

void main() {
  testWidgets('selects a sensor and writes the calibration back',
      (tester) async {
    final repo = MockControllerRepository();
    await repo.connect(MockControllerRepository.rearId);
    await repo.pair(MockControllerRepository.rearId, '123456');

    await pumpApp(
      tester,
      const Scaffold(
          body:
              SensorCalibrationForm(deviceId: MockControllerRepository.rearId)),
      overrides: [controllerRepositoryProvider.overrideWithValue(repo)],
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sensorDropdown')), findsOneWidget);

    // Change the active sensor to "left".
    await tester.tap(find.byKey(const Key('sensorDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Left').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('saveSensorConfig')));
    await tester.pumpAndSettle();

    final saved = await repo.readSensorConfig(MockControllerRepository.rearId);
    expect(saved.activeSensor, SensorType.left);
  });
}
