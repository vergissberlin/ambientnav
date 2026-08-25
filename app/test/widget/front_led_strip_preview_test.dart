import 'dart:math' as math;

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

  testWidgets('navStraight breathes wider at mid-cycle', (tester) async {
    await pumpApp(
      tester,
      const Scaffold(
        body: Center(
          child: FrontLedStripPreview(effect: FrontStripEffect.navStraight),
        ),
      ),
    );

    await tester.pump();
    final start = _ledColors(tester);

    await tester.pump(const Duration(milliseconds: 1200));
    final peak = _ledColors(tester);

    await tester.pump(const Duration(milliseconds: 1200));
    final end = _ledColors(tester);

    expect(_litCount(peak), greaterThan(_litCount(start)));
    expect(_litCount(peak), greaterThan(_litCount(end)));
    expect(_peakAlpha(peak), greaterThan(_peakAlpha(start)));
    expect(_peakAlpha(peak), greaterThan(_peakAlpha(end)));
    expect((_litCount(start) - _litCount(end)).abs(), lessThanOrEqualTo(1));
  });
}

List<Color> _ledColors(WidgetTester tester) {
  final leds = tester.widgetList<Container>(
    find.byWidgetPredicate((widget) {
      if (widget is! Container) return false;
      final decoration = widget.decoration;
      return decoration is BoxDecoration && decoration.borderRadius != BorderRadius.zero;
    }),
  );

  return leds
      .map((container) => (container.decoration as BoxDecoration).color ?? Colors.transparent)
      .toList(growable: false);
}

int _litCount(List<Color> colors) => colors.where((color) => color.alpha > 0).length;

int _peakAlpha(List<Color> colors) =>
    colors.map((color) => color.alpha).fold<int>(0, math.max);
