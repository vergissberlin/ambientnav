import 'package:ambientnav_ui/ambientnav_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Golden tests for the brand atoms.
///
/// Scope is deliberately narrow: atoms only, never screens. A golden over a
/// whole screen fails for every unrelated copy change and gets rubber-stamped,
/// which is worse than no golden at all.
///
/// **Ubuntu is authoritative.** These images are generated and verified on
/// `ubuntu-latest`, matching the CI job. Regenerating on macOS produces
/// subtly different antialiasing — use `just goldens` in a Linux environment,
/// or let CI tell you what changed.
///
/// Plain `matchesGoldenFile`, no golden package: `golden_toolkit` is
/// discontinued upstream and `alchemist` builds on it. The only thing they
/// really add is font loading, which is six lines once fonts are bundled.
void main() {
  group('AnButton', () {
    testGolden('variants', const _ButtonVariants());
    testGolden('sizes', const _ButtonSizes());
    testGolden('disabled', const _ButtonDisabled());
  });

  group('AnBadge', () {
    testGolden('tones', const _BadgeTones(), size: const Size(420, 400));
  });

  group('AnCard', () {
    testGolden('resting', const _CardResting());
  });

  group('AnLightStrip', () {
    testGolden('modes', const _LightStripModes(), size: const Size(560, 260));
  });
}

/// Pumps [child] on the brand dark theme and compares against
/// `goldens/<name>.png`.
void testGolden(String name, Widget child, {Size size = const Size(420, 320)}) {
  testWidgets(name, (tester) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AnAppTheme.dark,
        home: Scaffold(
          backgroundColor: AnColors.cockpit,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(AnSpace.s5),
              child: child,
            ),
          ),
        ),
      ),
    );
    // Settle the press/hover animations so the image is stable.
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  });
}

class _ButtonVariants extends StatelessWidget {
  const _ButtonVariants();

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    spacing: AnSpace.s3,
    children: [
      for (final variant in AnButtonVariant.values)
        AnButton(label: variant.name, variant: variant, onPressed: _noop),
    ],
  );
}

class _ButtonSizes extends StatelessWidget {
  const _ButtonSizes();

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    spacing: AnSpace.s3,
    children: [
      for (final size in AnButtonSize.values)
        AnButton(label: size.name, size: size, onPressed: _noop),
    ],
  );
}

class _ButtonDisabled extends StatelessWidget {
  const _ButtonDisabled();

  @override
  Widget build(BuildContext context) => const Column(
    mainAxisSize: MainAxisSize.min,
    spacing: AnSpace.s3,
    children: [
      AnButton(label: 'primary'),
      AnButton(label: 'gradient', variant: AnButtonVariant.gradient),
      AnButton(label: 'ghost', variant: AnButtonVariant.ghost),
    ],
  );
}

class _BadgeTones extends StatelessWidget {
  const _BadgeTones();

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    spacing: AnSpace.s3,
    children: [
      for (final tone in AnBadgeTone.values)
        AnBadge(label: tone.name, tone: tone),
      for (final tone in AnBadgeTone.values)
        AnBadge(label: tone.name, tone: tone, glow: true),
    ],
  );
}

class _CardResting extends StatelessWidget {
  const _CardResting();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 280,
    child: AnCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AnSpace.s2,
        children: [
          AnBadge(label: 'front', tone: AnBadgeTone.cyan),
          Text('Follow the light'),
        ],
      ),
    ),
  );
}

class _LightStripModes extends StatelessWidget {
  const _LightStripModes();

  @override
  Widget build(BuildContext context) => const Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: AnSpace.s4,
    children: [
      AnLightStrip(),
      AnLightStrip(mode: AnLightStripMode.guide),
      AnLightStrip(
        mode: AnLightStripMode.guide,
        direction: AnLightStripDirection.left,
      ),
      AnLightStrip(mode: AnLightStripMode.alert),
      AnLightStrip(mode: AnLightStripMode.alert, intensity: 1),
    ],
  );
}

void _noop() {}
