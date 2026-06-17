import 'package:ambientnav/features/controllers/presentation/ota_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

void main() {
  testWidgets('install is disabled until a firmware file is picked',
      (tester) async {
    await pumpApp(
      tester,
      const Scaffold(body: OtaScreen(deviceId: 'mock-front')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pickFirmware')), findsOneWidget);

    final installButton = tester.widget<FilledButton>(
      find.byKey(const Key('installFirmware')),
    );
    expect(installButton.onPressed, isNull); // disabled with no file selected
  });
}
