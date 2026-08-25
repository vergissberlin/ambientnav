import 'package:ambientnav/features/navigation/presentation/navigation_info_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

void main() {
  Future<Rect> _overlayRect(WidgetTester tester, {required Size size}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await pumpApp(
      tester,
      Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: NavigationInfoOverlay(child: const SizedBox(height: 20)),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tester.getRect(find.byKey(const Key('navigationInfoOverlayFrame')));
  }

  testWidgets('keeps the overlay narrow and left-aligned in landscape', (
    tester,
  ) async {
    final portrait = await _overlayRect(tester, size: const Size(390, 844));
    final landscape = await _overlayRect(tester, size: const Size(844, 390));

    expect(portrait.width, closeTo(390, 1));
    expect(landscape.width, lessThan(portrait.width));
    expect(landscape.width, lessThanOrEqualTo(420));
    expect(landscape.left, 0);
    expect(landscape.top, 0);
  });
}
