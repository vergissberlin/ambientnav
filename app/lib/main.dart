import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/persistence/hive_local_store.dart';
import 'core/persistence/local_store.dart';
import 'core/theme/theme_controller.dart';

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

  runApp(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(store),
      ],
      child: const AmbientNavApp(),
    ),
  );
}
