import 'package:ambientnav/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

class _FooterHarness extends StatefulWidget {
  const _FooterHarness({super.key, this.bottomPadding = EdgeInsets.zero});

  final EdgeInsets bottomPadding;

  @override
  State<_FooterHarness> createState() => _FooterHarnessState();
}

class _FooterHarnessState extends State<_FooterHarness> {
  bool _landscape = false;

  void setLandscape(bool value) {
    setState(() => _landscape = value);
  }

  @override
  Widget build(BuildContext context) {
    final size = _landscape ? const Size(844, 390) : const Size(390, 844);
    return MediaQuery(
      data: MediaQueryData(
        size: size,
        devicePixelRatio: 1,
        padding: widget.bottomPadding,
      ),
      child: Scaffold(
        body: const SizedBox.expand(),
        bottomNavigationBar: ResponsiveHomeFooterBar(
          selectedIndex: 0,
          onDestinationSelected: (_) {},
        ),
      ),
    );
  }
}

void main() {
  testWidgets('footer collapses in landscape and restores in portrait', (
    tester,
  ) async {
    final key = GlobalKey<_FooterHarnessState>();

    await pumpApp(tester, _FooterHarness(key: key));
    await tester.pumpAndSettle();

    final portraitHeight = tester
        .getSize(find.byType(ResponsiveHomeFooterBar))
        .height;
    expect(portraitHeight, greaterThan(0));

    key.currentState!.setLandscape(true);
    await tester.pump();
    await tester.pumpAndSettle();

    final landscapeHeight = tester
        .getSize(find.byType(ResponsiveHomeFooterBar))
        .height;
    expect(landscapeHeight, lessThan(portraitHeight));
    expect(landscapeHeight, lessThan(1));

    key.currentState!.setLandscape(false);
    await tester.pump();
    await tester.pumpAndSettle();

    final restoredHeight = tester
        .getSize(find.byType(ResponsiveHomeFooterBar))
        .height;
    expect(restoredHeight, greaterThan(0));
    expect(restoredHeight, closeTo(portraitHeight, 1));
  });

  testWidgets('footer does not inherit bottom safe-area padding', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const _FooterHarness(bottomPadding: EdgeInsets.only(bottom: 34)),
    );
    await tester.pumpAndSettle();

    final footerHeight = tester
        .getSize(find.byType(ResponsiveHomeFooterBar))
        .height;
    expect(footerHeight, closeTo(80, 1));
  });
}
