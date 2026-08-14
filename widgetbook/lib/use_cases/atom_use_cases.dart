import 'package:ambientnav_ui/ambientnav_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// The brand primitives from `packages/ambientnav_ui/lib/atoms/`, ported from
/// `design-system/components/`.
List<WidgetbookNode> brandAtoms() => [
  _anButton,
  _anBadge,
  _anCard,
  _anLightStrip,
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
