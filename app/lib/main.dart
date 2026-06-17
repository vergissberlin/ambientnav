import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/persistence/hive_local_store.dart';
import 'core/persistence/local_store.dart';
import 'core/theme/theme_controller.dart';
import 'features/car/car_bridge.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Open persistent storage; fall back to in-memory if it fails so the app
  // still launches.
  LocalStore store;
  try {
    store = await HiveLocalStore.open();
  } catch (_) {
    store = InMemoryLocalStore();
  }

  // Own the container so the CarPlay / Android Auto bridge can share the same
  // navigation state as the phone UI.
  final container = ProviderContainer(
    overrides: [
      localStoreProvider.overrideWithValue(store),
    ],
  );
  CarBridge(container).start();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AmbientNavApp(),
    ),
  );
}
