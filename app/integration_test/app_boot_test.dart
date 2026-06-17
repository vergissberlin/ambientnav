import 'package:ambientnav/app.dart';
import 'package:ambientnav/core/persistence/local_store.dart';
import 'package:ambientnav/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots and navigates between the main tabs', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStoreProvider.overrideWithValue(InMemoryLocalStore()),
        ],
        child: const AmbientNavApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Move to the Controllers tab.
    await tester.tap(find.byIcon(Icons.memory_outlined));
    await tester.pumpAndSettle();

    // Move to Settings and confirm the theme selector is present.
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('themeSelector')), findsOneWidget);
  });
}
