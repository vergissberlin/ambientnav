import 'package:flutter/material.dart';

import '../theme/an_brand_theme.dart';
import '../tokens/an_tokens.dart';

/// Tone of an [AnBadge]. Maps to the signal palette, so pick by meaning:
/// [cyan] for guidance state, [magenta] for proximity or warning, [violet] for
/// brand or mode, [neutral] for everything else.
enum AnBadgeTone { neutral, cyan, violet, magenta }

/// Port of `design-system/components/core/Badge.jsx`.
///
/// A small uppercase mono label for status, modes and hardware tags. Set
/// [glow] for live states — a badge that glows should mean something is
/// currently happening.
class AnBadge extends StatelessWidget {
  const AnBadge({
    super.key,
    required this.label,
    this.tone = AnBadgeTone.neutral,
    this.glow = false,
    this.icon,
  });

  final String label;
  final AnBadgeTone tone;
  final bool glow;
  final Widget? icon;

  Color? _accent() => switch (tone) {
    AnBadgeTone.neutral => null,
    AnBadgeTone.cyan => AnColors.cyan,
    AnBadgeTone.violet => AnColors.violetSoft,
    AnBadgeTone.magenta => AnColors.magentaSoft,
  };

  /// The glow uses the base accent, not the soft variant the text uses.
  List<BoxShadow> _glow() => switch (tone) {
    AnBadgeTone.neutral => const [],
    AnBadgeTone.cyan => AnShadows.glowCyan,
    AnBadgeTone.violet => AnShadows.glowViolet,
    AnBadgeTone.magenta => AnShadows.glowMagenta,
  };

  @override
  Widget build(BuildContext context) {
    final brand = AnBrandTheme.of(context);
    final accent = _accent();

    // The web spec uses a 40% accent border over an 8% accent fill.
    final foreground = accent ?? brand.text3;
    final border = accent?.withValues(alpha: 0.4) ?? brand.lineStrong;
    final fill = accent?.withValues(alpha: 0.08) ?? Colors.transparent;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(AnRadius.xs),
        boxShadow: glow ? _glow() : const [],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            ?icon,
            Text(
              // Flutter has no CSS `text-transform`, so uppercase eagerly.
              label.toUpperCase(),
              style: AnTypography.badgeLabel().copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}
