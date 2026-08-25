import 'package:ambientnav/ui/molecules/front_led_strip_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

void main() {
  testWidgets('uses a square background frame', (tester) async {
    await pumpApp(
      tester,
      const Scaffold(
        body: Center(
          child: FrontLedStripPreview(effect: FrontStripEffect.ambient),
        ),
      ),
    );
    await tester.pump();

    final container = tester.widget<Container>(
      find.byKey(const Key('frontLedStripPreviewFrame')),
    );
    final decoration = container.decoration as BoxDecoration;

    expect(decoration.borderRadius, BorderRadius.zero);
  });
}
