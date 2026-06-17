import 'package:ambientnav/core/di/providers.dart';
import 'package:ambientnav/features/controllers/data/mock/mock_controller_repository.dart';
import 'package:ambientnav/features/controllers/presentation/led_config_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

void main() {
  testWidgets('auto-populates from the controller, edits and writes back',
      (tester) async {
    final repo = MockControllerRepository();
    await repo.connect(MockControllerRepository.frontId);
    await repo.pair(MockControllerRepository.frontId, '123456');

    await pumpApp(
      tester,
      const Scaffold(
          body: LedConfigForm(deviceId: MockControllerRepository.frontId)),
      overrides: [controllerRepositoryProvider.overrideWithValue(repo)],
    );
    await tester.pumpAndSettle();

    // Auto-populated from the mock's default front config (60 LEDs).
    final field = find.byKey(const Key('ledCountField'));
    expect(field, findsOneWidget);
    expect(find.text('60'), findsOneWidget);

    // Edit LED count and save.
    await tester.enterText(field, '90');
    await tester.tap(find.byKey(const Key('saveLedConfig')));
    await tester.pumpAndSettle();

    final saved = await repo.readLedConfig(MockControllerRepository.frontId);
    expect(saved.ledCount, 90);
  });
}
