import 'dart:io';

import 'package:ambientnav_widgetbook/directories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

/// Fails when a component in either UI layer has no use case registered.
///
/// This is the counterweight to the hand-written tree in `directories.dart`:
/// codegen would discover components automatically, so without a guard the
/// manual list silently rots. Adding a widget and forgetting to catalogue it
/// now breaks the build instead.
///
/// Scope is deliberately narrow — only the two UI layers are scanned, so adding
/// a feature screen never fails CI. Exemptions require a reason, which keeps
/// bypasses visible in review.
const Map<String, String> kUseCaseExempt = {};

/// Directories that hold widgets expected to be catalogued.
const List<String> kScannedDirs = [
  '../app/lib/ui',
  '../packages/ambientnav_ui/lib/atoms',
];

void main() {
  test('every component in the UI layers has a use case', () {
    final declared = <String, String>{};

    for (final path in kScannedDirs) {
      final dir = Directory(path);
      expect(
        dir.existsSync(),
        isTrue,
        reason: 'expected a UI layer at $path — did it move?',
      );

      for (final entity in dir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        for (final match in _declaration.allMatches(
          entity.readAsStringSync(),
        )) {
          declared[match.group(1)!] = entity.path;
        }
      }
    }

    expect(
      declared,
      isNotEmpty,
      reason: 'the scan matched nothing — the regex or the paths are wrong',
    );

    final catalogued = _componentNames(kDirectories).toSet();
    final missing =
        declared.keys
            .toSet()
            .difference(catalogued)
            .difference(kUseCaseExempt.keys.toSet())
            .toList()
          ..sort();

    expect(
      missing,
      isEmpty,
      reason:
          'Components with no Widgetbook use case: ${missing.join(', ')}.\n'
          'Register them in widgetbook/lib/directories.dart, or add them to '
          'kUseCaseExempt with a reason.',
    );

    final stale = kUseCaseExempt.keys
        .where((name) => !declared.containsKey(name))
        .toList();
    expect(
      stale,
      isEmpty,
      reason: 'kUseCaseExempt lists components that no longer exist: $stale',
    );
  });
}

/// Public widget classes. Private ones (`_Foo`) are implementation details of
/// the file they live in and are not expected to be catalogued.
final _declaration = RegExp(
  r'^class\s+([A-Z]\w*)\s+extends\s+'
  r'(StatelessWidget|StatefulWidget|ConsumerWidget|ConsumerStatefulWidget)\b',
  multiLine: true,
);

Iterable<String> _componentNames(Iterable<WidgetbookNode> nodes) sync* {
  for (final node in nodes) {
    if (node is WidgetbookComponent) yield node.name;
    final children = node.children;
    if (children != null) yield* _componentNames(children);
  }
}
