import 'package:ambientnav/core/l10n/app_localizations.dart';
import 'package:ambientnav_ui/ambientnav_ui.dart';
import 'package:ambientnav_widgetbook/directories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

/// Pumps every registered use case.
///
/// Cheap to maintain and disproportionately useful: it turns the catalogue into
/// a rendering regression suite, so a token rename or a changed constructor
/// fails here rather than being discovered by someone scrolling Widgetbook.
void main() {
  final useCases = _flatten(kDirectories).toList();

  test('the catalogue is registered', () {
    expect(
      useCases.length,
      greaterThanOrEqualTo(15),
      reason: 'kDirectories looks suspiciously small — did a folder drop out?',
    );
  });

  for (final (path, useCase) in useCases) {
    testWidgets('builds: $path', (tester) async {
      await tester.pumpWidget(
        // A WidgetbookScope is required, not cosmetic: use cases that declare
        // knobs call context.knobs, which asserts on the ambient
        // WidgetbookState and would otherwise fail every "Playground" case.
        WidgetbookScope(
          state: WidgetbookState(root: WidgetbookRoot(children: kDirectories)),
          child: MaterialApp(
            // AppLocalizations.of throws without these — app/l10n.yaml sets
            // nullable-getter: false. Mirrors what LocalizationAddon injects.
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AnAppTheme.dark,
            home: Scaffold(body: Builder(builder: useCase.builder)),
          ),
        ),
      );

      // Two pumps rather than pumpAndSettle: several use cases animate on a
      // token duration, and MockControllerRepository.telemetry() is an infinite
      // emitter, so a settling pump would hang once provider-bound use cases
      // are added.
      await tester.pump();
      await tester.pump(AnMotion.slow);

      expect(tester.takeException(), isNull);
    });
  }
}

/// Depth-first walk yielding `Folder/Component/Use case` paths.
Iterable<(String, WidgetbookUseCase)> _flatten(
  Iterable<WidgetbookNode> nodes, [
  String prefix = '',
]) sync* {
  for (final node in nodes) {
    final path = prefix.isEmpty ? node.name : '$prefix/${node.name}';
    if (node is WidgetbookUseCase) {
      yield (path, node);
    }
    final children = node.children;
    if (children != null) yield* _flatten(children, path);
  }
}
