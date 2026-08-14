import 'package:ambientnav_ui/ambientnav_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// Foundation specimens, ported from `design-system/guidelines/*.html`.
///
/// Every page is built **from the token classes**, never from literals, so a
/// specimen doubles as visual verification that the Dart mirror is intact.
/// `tokens_match_css_test.dart` catches numeric drift; these catch the rest.
List<WidgetbookNode> foundationsFolder() => [
  WidgetbookFolder(
    name: 'Foundations',
    children: [
      WidgetbookComponent(name: 'Colors', useCases: [_colors]),
      WidgetbookComponent(name: 'Typography', useCases: [_typography]),
      WidgetbookComponent(name: 'Spacing', useCases: [_spacing]),
      WidgetbookComponent(name: 'Radius', useCases: [_radius]),
      WidgetbookComponent(name: 'Motion', useCases: [_motion]),
    ],
  ),
];

/// Shared page frame: cockpit ground, scrollable, generous padding.
Widget _page(BuildContext context, List<Widget> children) {
  final brand = AnBrandTheme.of(context);
  return ColoredBox(
    color: brand.cockpit,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AnSpace.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AnSpace.s5,
        children: children,
      ),
    ),
  );
}

Widget _sectionTitle(BuildContext context, String text) {
  final brand = AnBrandTheme.of(context);
  return Text(
    text.toUpperCase(),
    style: AnTypography.badgeLabel(fontSize: 12).copyWith(color: brand.text4),
  );
}

// ── Colors ───────────────────────────────────────────────────────────────────

final _colors = WidgetbookUseCase(
  name: 'Palette',
  builder: (context) {
    final brand = AnBrandTheme.of(context);
    return _page(context, [
      _sectionTitle(context, 'Signal accents'),
      Text(
        'Cyan means direction. Magenta means proximity. Never decorative.',
        style: TextStyle(color: brand.text3),
      ),
      Wrap(
        spacing: AnSpace.s3,
        runSpacing: AnSpace.s3,
        children: const [
          _Swatch('cyan', AnColors.cyan, '#19E3FF', 'direction & flow'),
          _Swatch('cyan-soft', AnColors.cyanSoft, '#5CEFFF', ''),
          _Swatch('cyan-deep', AnColors.cyanDeep, '#05323A', 'on-cyan text'),
          _Swatch('violet', AnColors.violet, '#7C5CFF', 'transition / brand'),
          _Swatch('violet-soft', AnColors.violetSoft, '#A38CFF', ''),
          _Swatch(
            'magenta',
            AnColors.magenta,
            '#FF2D9C',
            'proximity & warning',
          ),
          _Swatch('magenta-soft', AnColors.magentaSoft, '#FF6FC2', ''),
          _Swatch('magenta-deep', AnColors.magentaDeep, '#3A0A24', ''),
        ],
      ),
      _sectionTitle(context, 'Gradient'),
      Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: AnColors.gradientH,
          borderRadius: BorderRadius.circular(AnRadius.md),
        ),
      ),
      _sectionTitle(context, 'Cockpit surfaces'),
      Row(
        spacing: AnSpace.s3,
        children: const [
          Expanded(child: _SurfaceTile('cockpit', AnColors.cockpit)),
          Expanded(child: _SurfaceTile('surface', AnColors.surface)),
          Expanded(child: _SurfaceTile('surface-2', AnColors.surface2)),
          Expanded(child: _SurfaceTile('surface-3', AnColors.surface3)),
        ],
      ),
      _sectionTitle(context, 'Text levels'),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AnSpace.s2,
        children: [
          Text('text — primary', style: TextStyle(color: brand.text)),
          Text('text-2 — secondary', style: TextStyle(color: brand.text2)),
          Text(
            'text-3 — tertiary / muted',
            style: TextStyle(color: brand.text3),
          ),
          Text(
            'text-4 — faint / captions',
            style: TextStyle(color: brand.text4),
          ),
        ],
      ),
      _sectionTitle(context, 'Glow, not grey drop'),
      Row(
        spacing: AnSpace.s5,
        children: const [
          _GlowDot(AnColors.cyan, AnShadows.glowCyan),
          _GlowDot(AnColors.violet, AnShadows.glowViolet),
          _GlowDot(AnColors.magenta, AnShadows.glowMagenta),
        ],
      ),
    ]);
  },
);

class _Swatch extends StatelessWidget {
  const _Swatch(this.name, this.color, this.hex, this.role);

  final String name;
  final Color color;
  final String hex;
  final String role;

  @override
  Widget build(BuildContext context) {
    final brand = AnBrandTheme.of(context);
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AnRadius.sm),
            ),
          ),
          const SizedBox(height: AnSpace.s2),
          Text(name, style: TextStyle(color: brand.text, fontSize: 13)),
          Text(hex, style: TextStyle(color: brand.text4, fontSize: 11)),
          if (role.isNotEmpty)
            Text(role, style: TextStyle(color: brand.text3, fontSize: 11)),
        ],
      ),
    );
  }
}

class _SurfaceTile extends StatelessWidget {
  const _SurfaceTile(this.name, this.color);

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final brand = AnBrandTheme.of(context);
    return Container(
      height: 72,
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.all(AnSpace.s2),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: brand.line),
        borderRadius: BorderRadius.circular(AnRadius.sm),
      ),
      child: Text(name, style: TextStyle(color: brand.text3, fontSize: 11)),
    );
  }
}

class _GlowDot extends StatelessWidget {
  const _GlowDot(this.color, this.shadows);

  final Color color;
  final List<BoxShadow> shadows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: shadows,
      ),
    );
  }
}

// ── Typography ───────────────────────────────────────────────────────────────

final _typography = WidgetbookUseCase(
  name: 'Type scale',
  builder: (context) {
    final brand = AnBrandTheme.of(context);
    return _page(context, [
      if (!AnTypography.kBrandFontsAvailable)
        Container(
          padding: const EdgeInsets.all(AnSpace.s3),
          decoration: BoxDecoration(
            color: AnColors.magenta.withValues(alpha: 0.08),
            border: Border.all(color: AnColors.magenta.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(AnRadius.sm),
          ),
          child: Text(
            'Brand fonts are not bundled yet — Space Grotesk, IBM Plex Sans and '
            'IBM Plex Mono fall back to the platform default. Sizes, weights, '
            'tracking and line heights below are still the real tokens.',
            style: TextStyle(color: brand.text2, fontSize: 13),
          ),
        ),
      _sectionTitle(context, 'Scale (raw web values)'),
      for (final (name, size) in AnTypeScale.scale)
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            SizedBox(
              width: 96,
              child: Text(
                '$name · ${size.toInt()}',
                style: TextStyle(color: brand.text4, fontSize: 11),
              ),
            ),
            Expanded(
              child: Text(
                'Follow the light',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AnTypography.display,
                  fontSize: size,
                  fontWeight: AnTypography.semibold,
                  letterSpacing: size * AnTypography.lsHeadingEm,
                  height: AnTypography.lhHeading,
                  color: brand.text,
                ),
              ),
            ),
          ],
        ),
      _sectionTitle(context, 'Eyebrow tracking (0.26em)'),
      Text(
        'AMBIENT NAVIGATION',
        style: AnTypography.badgeLabel(fontSize: AnTypeScale.eyebrow).copyWith(
          color: brand.text3,
          letterSpacing: AnTypeScale.eyebrow * 0.26,
        ),
      ),
    ]);
  },
);

// ── Spacing ──────────────────────────────────────────────────────────────────

final _spacing = WidgetbookUseCase(
  name: 'Scale',
  builder: (context) {
    final brand = AnBrandTheme.of(context);
    return _page(context, [
      _sectionTitle(context, '4px grid'),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: AnSpace.s3,
          children: [
            for (var i = 0; i < AnSpace.scale.length; i++)
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 18,
                    height: AnSpace.scale[i],
                    decoration: BoxDecoration(
                      color: AnColors.violet,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: AnShadows.glowViolet,
                    ),
                  ),
                  const SizedBox(height: AnSpace.s2),
                  Text(
                    '${AnSpace.scale[i].toInt()}',
                    style: TextStyle(fontSize: 10, color: brand.text3),
                  ),
                  Text(
                    'space-${i + 1}',
                    style: TextStyle(fontSize: 9, color: brand.text4),
                  ),
                ],
              ),
          ],
        ),
      ),
    ]);
  },
);

// ── Radius ───────────────────────────────────────────────────────────────────

final _radius = WidgetbookUseCase(
  name: 'Corners',
  builder: (context) {
    final brand = AnBrandTheme.of(context);
    const named = [
      ('xs', AnRadius.xs),
      ('sm', AnRadius.sm),
      ('md', AnRadius.md),
      ('lg', AnRadius.lg),
      ('xl', AnRadius.xl),
      ('strip', AnRadius.strip),
    ];
    return _page(context, [
      _sectionTitle(context, 'Radii'),
      Wrap(
        spacing: AnSpace.s4,
        runSpacing: AnSpace.s4,
        children: [
          for (final (name, value) in named)
            Column(
              children: [
                Container(
                  width: 88,
                  height: 64,
                  decoration: BoxDecoration(
                    color: brand.surface3,
                    border: Border.all(color: brand.lineStrong),
                    borderRadius: BorderRadius.circular(value),
                  ),
                ),
                const SizedBox(height: AnSpace.s2),
                Text(
                  '$name · ${value.toInt()}',
                  style: TextStyle(fontSize: 11, color: brand.text3),
                ),
              ],
            ),
        ],
      ),
    ]);
  },
);

// ── Motion ───────────────────────────────────────────────────────────────────

final _motion = WidgetbookUseCase(
  name: 'Durations',
  builder: (context) => const _MotionSpecimen(),
);

class _MotionSpecimen extends StatefulWidget {
  const _MotionSpecimen();

  @override
  State<_MotionSpecimen> createState() => _MotionSpecimenState();
}

class _MotionSpecimenState extends State<_MotionSpecimen> {
  bool _out = false;

  @override
  Widget build(BuildContext context) {
    final brand = AnBrandTheme.of(context);
    const rows = [
      ('fast · 140ms', AnMotion.fast, AnColors.cyan),
      ('base · 240ms', AnMotion.base, AnColors.violet),
      ('slow · 420ms', AnMotion.slow, AnColors.magenta),
    ];
    return _page(context, [
      _sectionTitle(context, 'ease-glow · cubic-bezier(.4, 0, .2, 1)'),
      Text(
        'Light does not bounce — one easing curve, three durations.',
        style: TextStyle(color: brand.text3),
      ),
      for (final (label, duration, color) in rows) ...[
        Text(label, style: TextStyle(color: brand.text4, fontSize: 11)),
        SizedBox(
          height: 32,
          child: Stack(
            children: [
              AnimatedAlign(
                alignment: _out ? Alignment.centerRight : Alignment.centerLeft,
                duration: duration,
                curve: AnMotion.easeGlow,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AnRadius.sm),
                    boxShadow: AnShadows.glowFor(color),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      AnButton(
        label: _out ? 'Return' : 'Play',
        variant: AnButtonVariant.secondary,
        onPressed: () => setState(() => _out = !_out),
      ),
    ]);
  }
}
