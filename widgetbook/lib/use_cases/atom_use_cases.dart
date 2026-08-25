import 'package:ambientnav_ui/ambientnav_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// The brand primitives from `packages/ambientnav_ui/lib/atoms/`, ported from
/// `design-system/components/`.
List<WidgetbookNode> brandAtoms() => [
  _anButton,
  _anBadge,
  _anCard,
  _anPanel,
  _anLightStrip,
  _anGlassBar,
  _anAppBar,
];

/// Centres a use case on the cockpit ground so glows read correctly — brand
/// atoms are designed against a dark surface, not Widgetbook's default.
Widget _stage(BuildContext context, Widget child) {
  return ColoredBox(
    color: AnBrandTheme.of(context).cockpit,
    child: Center(
      child: Padding(padding: const EdgeInsets.all(AnSpace.s5), child: child),
    ),
  );
}

// ── AnButton ─────────────────────────────────────────────────────────────────

final _anButton = WidgetbookComponent(
  name: 'AnButton',
  useCases: [
    WidgetbookUseCase(
      name: 'Variants',
      builder: (context) => _stage(
        context,
        Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AnSpace.s4,
          children: [
            for (final variant in AnButtonVariant.values)
              AnButton(label: variant.name, variant: variant, onPressed: () {}),
            const Divider(height: AnSpace.s6),
            const AnButton(label: 'disabled', onPressed: null),
          ],
        ),
      ),
    ),
    WidgetbookUseCase(
      name: 'Sizes',
      builder: (context) => _stage(
        context,
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: AnSpace.s4,
          children: [
            for (final size in AnButtonSize.values)
              AnButton(label: size.name, size: size, onPressed: () {}),
          ],
        ),
      ),
    ),
    WidgetbookUseCase(
      name: 'With icons',
      builder: (context) => _stage(
        context,
        Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AnSpace.s4,
          children: [
            AnButton(
              label: 'Start guidance',
              iconLeft: const Icon(Icons.navigation, size: 18),
              onPressed: () {},
            ),
            AnButton(
              label: 'Pair controller',
              variant: AnButtonVariant.secondary,
              iconRight: const Icon(Icons.bluetooth, size: 18),
              onPressed: () {},
            ),
          ],
        ),
      ),
    ),
    WidgetbookUseCase(
      name: 'Playground',
      builder: (context) => _stage(
        context,
        AnButton(
          label: context.knobs.string(
            label: 'label',
            initialValue: 'Follow the light',
          ),
          variant: context.knobs.object.dropdown(
            label: 'variant',
            options: AnButtonVariant.values,
            labelBuilder: (v) => v.name,
          ),
          size: context.knobs.object.segmented(
            label: 'size',
            options: AnButtonSize.values,
            labelBuilder: (v) => v.name,
          ),
          onPressed: context.knobs.boolean(label: 'enabled', initialValue: true)
              ? () {}
              : null,
        ),
      ),
    ),
  ],
);

// ── AnBadge ──────────────────────────────────────────────────────────────────

final _anBadge = WidgetbookComponent(
  name: 'AnBadge',
  useCases: [
    WidgetbookUseCase(
      name: 'Tones',
      builder: (context) => _stage(
        context,
        Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AnSpace.s4,
          children: [
            Wrap(
              spacing: AnSpace.s3,
              runSpacing: AnSpace.s3,
              children: [
                for (final tone in AnBadgeTone.values)
                  AnBadge(label: tone.name, tone: tone),
              ],
            ),
            Wrap(
              spacing: AnSpace.s3,
              runSpacing: AnSpace.s3,
              children: [
                for (final tone in AnBadgeTone.values)
                  AnBadge(label: '${tone.name} glow', tone: tone, glow: true),
              ],
            ),
          ],
        ),
      ),
    ),
    WidgetbookUseCase(
      name: 'In context',
      builder: (context) => _stage(
        context,
        const Wrap(
          spacing: AnSpace.s3,
          runSpacing: AnSpace.s3,
          children: [
            AnBadge(label: 'front', tone: AnBadgeTone.cyan),
            AnBadge(label: 'rear', tone: AnBadgeTone.violet),
            AnBadge(label: 'sim', tone: AnBadgeTone.neutral),
            AnBadge(label: 'too close', tone: AnBadgeTone.magenta, glow: true),
            AnBadge(
              label: 'paired',
              tone: AnBadgeTone.neutral,
              icon: Icon(Icons.lock, size: 12),
            ),
          ],
        ),
      ),
    ),
    WidgetbookUseCase(
      name: 'Playground',
      builder: (context) => _stage(
        context,
        AnBadge(
          label: context.knobs.string(
            label: 'label',
            initialValue: 'connected',
          ),
          tone: context.knobs.object.dropdown(
            label: 'tone',
            options: AnBadgeTone.values,
            labelBuilder: (t) => t.name,
          ),
          glow: context.knobs.boolean(label: 'glow'),
        ),
      ),
    ),
  ],
);

// ── AnCard ───────────────────────────────────────────────────────────────────

final _anCard = WidgetbookComponent(
  name: 'AnCard',
  useCases: [
    WidgetbookUseCase(
      name: 'Glow variants',
      builder: (context) {
        final brand = AnBrandTheme.of(context);
        return _stage(
          context,
          Wrap(
            spacing: AnSpace.s4,
            runSpacing: AnSpace.s4,
            children: [
              for (final glow in AnCardGlow.values)
                SizedBox(
                  width: 240,
                  child: AnCard(
                    glow: glow,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: AnSpace.s2,
                      children: [
                        AnBadge(label: glow.name),
                        Text(
                          'Hover to see the ${glow.name} bloom.',
                          style: TextStyle(color: brand.text2),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
    WidgetbookUseCase(
      name: 'Playground',
      builder: (context) {
        final brand = AnBrandTheme.of(context);
        return _stage(
          context,
          SizedBox(
            width: 320,
            child: AnCard(
              glow: context.knobs.object.dropdown(
                label: 'glow',
                options: AnCardGlow.values,
                labelBuilder: (g) => g.name,
              ),
              padding: EdgeInsets.all(
                context.knobs.double.slider(
                  label: 'padding',
                  initialValue: 28,
                  min: 8,
                  max: 48,
                ),
              ),
              child: Text(
                context.knobs.string(
                  label: 'content',
                  initialValue: 'Guide Cyan leads the way.',
                ),
                style: TextStyle(color: brand.text2),
              ),
            ),
          ),
        );
      },
    ),
  ],
);

// ── AnPanel ──────────────────────────────────────────────────────────────────

final _anPanel = WidgetbookComponent(
  name: 'AnPanel',
  useCases: [
    WidgetbookUseCase(
      name: 'Glow variants',
      builder: (context) {
        final brand = AnBrandTheme.of(context);
        return _stage(
          context,
          Wrap(
            spacing: AnSpace.s4,
            runSpacing: AnSpace.s4,
            children: [
              for (final glow in AnCardGlow.values)
                SizedBox(
                  width: 240,
                  child: AnPanel(
                    glow: glow,
                    interactive: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: AnSpace.s2,
                      children: [
                        AnBadge(label: glow.name),
                        Text(
                          'Follow the light',
                          style: TextStyle(color: brand.text2),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
    WidgetbookUseCase(
      name: 'Accent modes',
      builder: (context) {
        final brand = AnBrandTheme.of(context);
        return _stage(
          context,
          Column(
            mainAxisSize: MainAxisSize.min,
            spacing: AnSpace.s4,
            children: [
              Wrap(
                spacing: AnSpace.s4,
                runSpacing: AnSpace.s4,
                children: [
                  for (final accent in AnPanelAccent.values)
                    SizedBox(
                      width: 200,
                      child: AnPanel(
                        glow: AnCardGlow.cyan,
                        accent: accent,
                        child: Text(
                          accent.name,
                          style: TextStyle(color: brand.text2),
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                'pulse and scanline are animated and are not pinned by golden '
                'tests — only staticAccent is.',
                style: TextStyle(color: brand.text4),
              ),
            ],
          ),
        );
      },
    ),
    WidgetbookUseCase(
      name: 'Playground',
      builder: (context) {
        final brand = AnBrandTheme.of(context);
        return _stage(
          context,
          SizedBox(
            width: 320,
            child: AnPanel(
              glow: context.knobs.object.dropdown(
                label: 'glow',
                options: AnCardGlow.values,
                labelBuilder: (g) => g.name,
              ),
              accent: context.knobs.object.dropdown(
                label: 'accent',
                options: AnPanelAccent.values,
                labelBuilder: (a) => a.name,
              ),
              bracketLength: context.knobs.double.slider(
                label: 'bracketLength',
                initialValue: 20,
                min: 4,
                max: 60,
              ),
              bracketThickness: context.knobs.double.slider(
                label: 'bracketThickness',
                initialValue: 2,
                min: 1,
                max: 8,
              ),
              interactive: context.knobs.boolean(
                label: 'interactive',
                initialValue: true,
              ),
              child: Text(
                'Guide Cyan leads the way.',
                style: TextStyle(color: brand.text2),
              ),
            ),
          ),
        );
      },
    ),
  ],
);

// ── AnLightStrip ─────────────────────────────────────────────────────────────

final _anLightStrip = WidgetbookComponent(
  name: 'AnLightStrip',
  useCases: [
    WidgetbookUseCase(
      name: 'Modes',
      builder: (context) {
        final brand = AnBrandTheme.of(context);
        return _stage(
          context,
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AnSpace.s5,
            children: [
              Text('ambient', style: TextStyle(color: brand.text4)),
              const AnLightStrip(),
              Text('guide · right', style: TextStyle(color: brand.text4)),
              const AnLightStrip(mode: AnLightStripMode.guide),
              Text('guide · left', style: TextStyle(color: brand.text4)),
              const AnLightStrip(
                mode: AnLightStripMode.guide,
                direction: AnLightStripDirection.left,
              ),
              Text('alert · 0.6', style: TextStyle(color: brand.text4)),
              const AnLightStrip(mode: AnLightStripMode.alert),
              Text('alert · 1.0', style: TextStyle(color: brand.text4)),
              const AnLightStrip(mode: AnLightStripMode.alert, intensity: 1),
            ],
          ),
        );
      },
    ),
    WidgetbookUseCase(
      name: 'Playground',
      builder: (context) => _stage(
        context,
        AnLightStrip(
          mode: context.knobs.object.segmented(
            label: 'mode',
            options: AnLightStripMode.values,
            labelBuilder: (m) => m.name,
          ),
          direction: context.knobs.object.segmented(
            label: 'direction',
            options: AnLightStripDirection.values,
            labelBuilder: (d) => d.name,
          ),
          intensity: context.knobs.double.slider(
            label: 'intensity',
            initialValue: 0.6,
            max: 1,
            divisions: 20,
            precision: 2,
          ),
          leds: context.knobs.int.slider(
            label: 'leds',
            initialValue: 28,
            min: 8,
            max: 60,
          ),
          height: context.knobs.double.slider(
            label: 'height',
            initialValue: 16,
            min: 6,
            max: 40,
          ),
        ),
      ),
    ),
  ],
);

// ── Demo backdrop for the glass atoms ───────────────────────────────────────
//
// Blurring a flat color is invisible, so these use cases need something with
// real detail behind the glass to prove the effect — a stand-in for the map
// or scrolling list a real screen would show through it.

Widget _glassDemoBackdrop(BuildContext context) {
  final brand = AnBrandTheme.of(context);
  return DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AnColors.cyanDeep, AnColors.violet, AnColors.magentaDeep],
      ),
    ),
    child: GridView.builder(
      padding: const EdgeInsets.all(AnSpace.s4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AnSpace.s3,
        crossAxisSpacing: AnSpace.s3,
        childAspectRatio: 1.6,
      ),
      itemCount: 18,
      itemBuilder: (context, i) => DecoratedBox(
        decoration: BoxDecoration(
          color: brand.text.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AnRadius.sm),
        ),
      ),
    ),
  );
}

// ── AnGlassBar ───────────────────────────────────────────────────────────────

final _anGlassBar = WidgetbookComponent(
  name: 'AnGlassBar',
  useCases: [
    WidgetbookUseCase(
      name: 'Over content',
      builder: (context) => SizedBox(
        height: 320,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _glassDemoBackdrop(context),
            const Align(
              alignment: Alignment.topCenter,
              child: SizedBox(height: 64, child: AnGlassBar()),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: 64,
                child: AnGlassBar(
                  border: Border(
                    top: BorderSide(color: AnBrandTheme.of(context).line),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    WidgetbookUseCase(
      name: 'Playground',
      builder: (context) => SizedBox(
        height: 320,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _glassDemoBackdrop(context),
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: 64,
                child: AnGlassBar(
                  blurSigma: context.knobs.double.slider(
                    label: 'blurSigma',
                    initialValue: 14,
                    max: 40,
                  ),
                  tintOpacity: context.knobs.double.slider(
                    label: 'tintOpacity',
                    initialValue: 0.78,
                    max: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ],
);

// ── AnAppBar ─────────────────────────────────────────────────────────────────

final _anAppBar = WidgetbookComponent(
  name: 'AnAppBar',
  useCases: [
    WidgetbookUseCase(
      name: 'Over content',
      builder: (context) => SizedBox(
        height: 400,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _glassDemoBackdrop(context),
            Align(
              alignment: Alignment.topCenter,
              child: AnAppBar(title: const Text('Navigate')),
            ),
          ],
        ),
      ),
    ),
  ],
);
