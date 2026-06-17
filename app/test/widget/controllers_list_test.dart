import 'package:ambientnav/features/controllers/presentation/controllers_list_screen.dart';
import 'package:ambientnav/features/controllers/presentation/widgets/battery_gauge.dart';
import 'package:ambientnav/features/controllers/presentation/widgets/rssi_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

void main() {
  testWidgets('scan shows the mock controllers with RSSI and battery',
      (tester) async {
    await pumpApp(tester, const ControllersListScreen());
    await tester.pumpAndSettle();

    // Start scanning.
    await tester.tap(find.byType(FloatingActionButton));
    // Let the scripted scan stream emit both devices (300 ms staged).
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('AmbientNav-Front'), findsOneWidget);
    expect(find.textContaining('AmbientNav-Rear'), findsOneWidget);
    expect(find.byType(RssiIndicator), findsNWidgets(2));
    expect(find.byType(BatteryGauge), findsNWidgets(2));
  });
}
