import 'package:flutter/material.dart';

import '../theme/an_brand_theme.dart';
import '../tokens/an_tokens.dart';

/// Accent bloom shown when an [AnCard] is hovered.
enum AnCardGlow { none, cyan, violet, magenta }

/// Port of `design-system/components/core/Card.jsx`.
///
/// A flat dark surface with a hairline border and an ambient drop — no grey
/// inner shadow and no coloured left stripe, both of which the brand rules out.
///
/// The hover state is inert on touch devices, which is correct: [glow] is a
/// pointer affordance, not a status indicator. Use [AnBadge] for status.
class AnCard extends StatefulWidget {
  const AnCard({
    super.key,
    required this.child,
    this.glow = AnCardGlow.none,
    this.padding = const EdgeInsets.all(28),
    this.onTap,
  });

  final Widget child;
  final AnCardGlow glow;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  State<AnCard> createState() => _AnCardState();
}

class _AnCardState extends State<AnCard> {
  bool _hovered = false;

  List<BoxShadow> _glowShadows() => switch (widget.glow) {
    AnCardGlow.none => AnShadows.card,
    AnCardGlow.cyan => AnShadows.glowCyan,
    AnCardGlow.violet => AnShadows.glowViolet,
    AnCardGlow.magenta => AnShadows.glowMagenta,
  };

  @override
  Widget build(BuildContext context) {
    final brand = AnBrandTheme.of(context);
    final lifted = _hovered && widget.glow != AnCardGlow.none;

    final card = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AnMotion.base,
        curve: AnMotion.easeGlow,
        decoration: BoxDecoration(
          color: _hovered ? brand.surface3 : brand.surface2,
          border: Border.all(color: brand.line),
          borderRadius: BorderRadius.circular(AnRadius.lg),
          boxShadow: lifted ? _glowShadows() : AnShadows.card,
        ),
        padding: widget.padding,
        child: widget.child,
      ),
    );

    if (widget.onTap == null) return card;
    return GestureDetector(onTap: widget.onTap, child: card);
  }
}
