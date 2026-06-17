import 'package:ambientnav/core/persistence/local_store.dart';
import 'package:ambientnav/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemeController', () {
    test('defaults to system', () {
      final c = ThemeController(InMemoryLocalStore());
      expect(c.state, ThemeMode.system);
    });

    test('persists and restores the selected mode', () async {
      final store = InMemoryLocalStore();
      final c = ThemeController(store);
      await c.setMode(ThemeMode.dark);
      expect(c.state, ThemeMode.dark);

      // A fresh controller backed by the same store restores the choice.
      final restored = ThemeController(store);
      expect(restored.state, ThemeMode.dark);
    });

    test('cycles system -> light -> dark -> system', () async {
      final c = ThemeController(InMemoryLocalStore());
      await c.cycle();
      expect(c.state, ThemeMode.light);
      await c.cycle();
      expect(c.state, ThemeMode.dark);
      await c.cycle();
      expect(c.state, ThemeMode.system);
    });
  });
}
