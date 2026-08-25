import 'package:ambientnav/features/navigation/presentation/navigation_app_bar_title.dart';
import 'package:ambientnav/features/navigation/presentation/nav_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

void main() {
  testWidgets('lays out the logo beside the label in portrait', (tester) async {
    await pumpApp(
      tester,
      const MediaQuery(
        data: MediaQueryData(size: Size(390, 844), devicePixelRatio: 1),
        child: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: NavigationAppBarTitle(
              label: 'Navigate',
              phase: NavPhase.navigating,
              speedMps: 13.9,
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    final logo = tester.getRect(find.byKey(const Key('navigationHeaderLogo')));
    final label = tester.getRect(find.byKey(const Key('navigationHeaderLabel')));

    expect(logo.right, lessThan(label.left));
  });

  testWidgets('lays out the logo above the label in landscape', (tester) async {
    await pumpApp(
      tester,
      const MediaQuery(
        data: MediaQueryData(size: Size(844, 390), devicePixelRatio: 1),
        child: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: NavigationAppBarTitle(
              label: 'Navigate',
              phase: NavPhase.navigating,
              speedMps: 13.9,
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    final logo = tester.getRect(find.byKey(const Key('navigationHeaderLogo')));
    final label = tester.getRect(find.byKey(const Key('navigationHeaderLabel')));

    expect(logo.bottom, lessThan(label.top));
  });

  test('returns a shorter cycle duration as speed increases', () {
    final idle = navigationLogoCycleDurationFor(
      phase: NavPhase.idle,
      speedMps: 13.9,
    );
    final slow = navigationLogoCycleDurationFor(
      phase: NavPhase.navigating,
      speedMps: 2,
    );
    final fast = navigationLogoCycleDurationFor(
      phase: NavPhase.navigating,
      speedMps: 25,
    );

    expect(idle, isNull);
    expect(slow, isNotNull);
    expect(fast, isNotNull);
    expect(fast!.inMilliseconds, lessThan(slow!.inMilliseconds));
  });
}
