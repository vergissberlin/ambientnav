import 'package:ambientnav/features/navigation/domain/entities/maneuver.dart';
import 'package:ambientnav/ui/molecules/turn_by_turn_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

void main() {
  const maneuver = Maneuver(
    type: ManeuverType.turnLeft,
    instruction: 'Kurt-Eisner-Straße',
    distanceMeters: 62,
    latitude: 52.5,
    longitude: 13.4,
  );

  Future<double> _panelHeight(
    WidgetTester tester, {
    required Size size,
    required double width,
  }) async {
    await pumpApp(
      tester,
      MediaQuery(
        data: MediaQueryData(size: size, devicePixelRatio: 1),
        child: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              child: const TurnByTurnPanel(
                maneuver: maneuver,
                distanceMeters: 62,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tester.getSize(find.byType(TurnByTurnPanel)).height;
  }

  testWidgets('compresses the banner in landscape', (tester) async {
    final portraitHeight = await _panelHeight(
      tester,
      size: const Size(390, 844),
      width: 360,
    );
    final landscapeHeight = await _panelHeight(
      tester,
      size: const Size(844, 390),
      width: 760,
    );

    expect(landscapeHeight, lessThan(portraitHeight));
    expect(landscapeHeight, lessThan(72));
  });
}
