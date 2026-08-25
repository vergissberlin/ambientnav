import 'package:ambientnav/features/navigation/presentation/navigation_info_strip_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

void main() {
  Future<Rect> _stripRect(WidgetTester tester, {required Size size}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await pumpApp(
      tester,
      Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: NavigationInfoStripFrame(
                child: const SizedBox(height: 14),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tester.getRect(find.byKey(const Key('navigationInfoStripFrame')));
  }

  testWidgets('shrinks the strip frame in landscape', (tester) async {
    final portrait = await _stripRect(tester, size: const Size(390, 844));
    final landscape = await _stripRect(tester, size: const Size(844, 390));

    expect(portrait.width, closeTo(390, 1));
    expect(landscape.width, lessThan(portrait.width));
    expect(landscape.width, lessThanOrEqualTo(320));
    expect(landscape.left, 0);
  });
}
