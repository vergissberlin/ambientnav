import 'package:ambientnav/features/controllers/presentation/controllers_list_screen.dart';
import 'package:ambientnav/ui/atoms/battery_gauge.dart';
import 'package:ambientnav/ui/atoms/rssi_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

void main() {
  testWidgets('scan shows the mock controllers with RSSI and battery', (
    tester,
  ) async {
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

  testWidgets('controllers list fits on a narrow phone viewport', (
    tester,
  ) async {
    final errors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details);
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);

    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpApp(tester, const ControllersListScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('AmbientNav-Front'), findsOneWidget);
    expect(find.textContaining('AmbientNav-Rear'), findsOneWidget);
    expect(find.byType(RssiIndicator), findsNWidgets(2));
    expect(find.byType(BatteryGauge), findsNWidgets(2));

    final overflowErrors = errors
        .where((details) => details.exceptionAsString().contains('overflowed'))
        .toList();
    expect(overflowErrors, isEmpty);
  });
}
