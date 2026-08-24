import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/an_brand_theme.dart';
import '../tokens/an_tokens.dart';
import 'an_card.dart';

/// Animated accent behaviour for an [AnPanel].
///
/// `static` is a reserved word in Dart, so the no-animation member is named
/// [staticAccent] rather than `static`.
enum AnPanelAccent {
  /// No animation. Corner brackets and glow render at rest. The default.
  staticAccent,

  /// The glow shadow breathes between a dim and a full state on a loop.
  pulse,

  /// A thin gradient band sweeps top-to-bottom across the panel on a loop.
  scanline,
}

/// A "cybernetic frame" container: HUD-style corner brackets around a flat
/// dark surface, in the same accent/glow language as [AnCard].
///
/// Where [AnCard] uses a plain hairline border, [AnPanel] paints four
/// L-shaped bracket strokes at the corners — a sci-fi HUD framing motif — and
/// adds two optional idle-animation accents ([AnPanelAccent.pulse] and
/// [AnPanelAccent.scanline]) for panels that should read as "live" without
/// needing a hover interaction. [glow] reuses [AnCardGlow] rather than a
/// parallel enum, so panels and cards share one accent-colour vocabulary and
/// the same [AnShadows] glow shadows.
///
/// There is no `design-system/components/` JS counterpart yet — this atom
/// was introduced directly in Flutter as part of the cybernetic-frame
/// direction, not ported from the web design system.
///
/// [interactive] gates hover feedback (the `surface2`/`surface3` swap and the
/// glow lift), independently of [onTap] — a panel can be tappable without
/// swapping surfaces on hover, or vice versa. This mirrors [AnCard]'s hover
/// mechanism but makes it optional, since not every panel is a pointer
/// affordance.
class AnPanel extends StatefulWidget {
  const AnPanel({
    super.key,
    required this.child,
    this.glow = AnCardGlow.none,
    this.accent = AnPanelAccent.staticAccent,
    this.padding = const EdgeInsets.all(28),
    this.bracketLength = 20,
    this.bracketThickness = 2,
    this.interactive = false,
    this.onTap,
  });

  final Widget child;
  final AnCardGlow glow;
  final AnPanelAccent accent;
  final EdgeInsetsGeometry padding;

  /// Length in logical pixels of each corner bracket's two arms.
  final double bracketLength;

  /// Stroke width of the corner brackets.
  final double bracketThickness;

  /// Whether hover swaps `brand.surface2` for `brand.surface3` and lifts the
  /// glow shadow, matching [AnCard]'s hover treatment.
  final bool interactive;
  final VoidCallback? onTap;

  @override
  State<AnPanel> createState() => _AnPanelState();
}

class _AnPanelState extends State<AnPanel> with SingleTickerProviderStateMixin {
  bool _hovered = false;
  AnimationController? _controller;
  bool _startedAnimation = false;

  @override
  void initState() {
    super.initState();
    _controller = _createController();
  }

  AnimationController? _createController() {
    if (widget.accent == AnPanelAccent.staticAccent) return null;
    return AnimationController(
      vsync: this,
      duration: _durationFor(widget.accent),
    );
  }

  Duration _durationFor(AnPanelAccent accent) => switch (accent) {
    AnPanelAccent.pulse => AnMotion.slow,
    AnPanelAccent.scanline => AnMotion.scan,
    AnPanelAccent.staticAccent => Duration.zero,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_startedAnimation || _controller == null) return;
    _startedAnimation = true;
    if (!MediaQuery.disableAnimationsOf(context)) {
      _controller!.repeat(reverse: widget.accent == AnPanelAccent.pulse);
    }
  }

  @override
  void didUpdateWidget(covariant AnPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accent == widget.accent) return;

    _controller?.dispose();
    _controller = _createController();
    _startedAnimation = false;
    if (_controller != null && !MediaQuery.disableAnimationsOf(context)) {
      _startedAnimation = true;
      _controller!.repeat(reverse: widget.accent == AnPanelAccent.pulse);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  List<BoxShadow> _glowShadows() => switch (widget.glow) {
    AnCardGlow.none => AnShadows.card,
    AnCardGlow.cyan => AnShadows.glowCyan,
    AnCardGlow.violet => AnShadows.glowViolet,
    AnCardGlow.magenta => AnShadows.glowMagenta,
  };

  /// Interpolated shadow for [AnPanelAccent.pulse], breathing between a dim
  /// and a full version of the resolved glow. With [AnCardGlow.none] there is
  /// no accent colour to breathe, so the plain card shadow is used throughout
  /// — the controller still runs, it just has nothing visible to animate.
  List<BoxShadow> _pulseShadows(double t) {
    if (widget.glow == AnCardGlow.none) return AnShadows.card;
    final maxShadows = _glowShadows();
    final minShadows = [
      for (final s in maxShadows)
        BoxShadow(
          color: s.color.withValues(alpha: s.color.a * 0.45),
          blurRadius: s.blurRadius * 0.55,
          spreadRadius: s.spreadRadius,
          offset: s.offset,
        ),
    ];
    return BoxShadow.lerpList(minShadows, maxShadows, t) ?? maxShadows;
  }

  Color _bracketColor(AnBrandTheme brand) => switch (widget.glow) {
    AnCardGlow.none => brand.lineStrong,
    AnCardGlow.cyan => AnColors.cyan,
    AnCardGlow.violet => AnColors.violet,
    AnCardGlow.magenta => AnColors.magenta,
  };

  Widget _panelBody(Color bracketColor) {
    return Stack(
      children: [
        if (widget.accent == AnPanelAccent.scanline && _controller != null)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AnRadius.lg),
              child: AnimatedBuilder(
                animation: _controller!,
                builder: (context, _) => CustomPaint(
                  painter: _AnPanelScanlinePainter(
                    progress: _controller!.value,
                    color: bracketColor,
                  ),
                ),
              ),
            ),
          ),
        Padding(padding: widget.padding, child: widget.child),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _AnPanelBracketPainter(
                color: bracketColor,
                length: widget.bracketLength,
                thickness: widget.bracketThickness,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = AnBrandTheme.of(context);
    final bracketColor = _bracketColor(brand);
    final fillColor = widget.interactive && _hovered
        ? brand.surface3
        : brand.surface2;
    final lifted =
        widget.interactive && _hovered && widget.glow != AnCardGlow.none;

    Widget surface;
    if (widget.accent == AnPanelAccent.pulse && _controller != null) {
      surface = AnimatedBuilder(
        animation: _controller!,
        builder: (context, child) {
          final t = AnMotion.easeGlow.transform(_controller!.value);
          return DecoratedBox(
            decoration: BoxDecoration(
              color: fillColor,
              border: Border.all(color: brand.line),
              borderRadius: BorderRadius.circular(AnRadius.lg),
              boxShadow: _pulseShadows(t),
            ),
            child: child,
          );
        },
        child: _panelBody(bracketColor),
      );
    } else {
      surface = AnimatedContainer(
        duration: AnMotion.base,
        curve: AnMotion.easeGlow,
        decoration: BoxDecoration(
          color: fillColor,
          border: Border.all(color: brand.line),
          borderRadius: BorderRadius.circular(AnRadius.lg),
          boxShadow: lifted ? _glowShadows() : AnShadows.card,
        ),
        child: _panelBody(bracketColor),
      );
    }

    Widget content = surface;
    if (widget.interactive) {
      content = MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: content,
      );
    }
    if (widget.onTap == null) return content;
    return GestureDetector(onTap: widget.onTap, child: content);
  }
}

/// Paints four L-shaped corner brackets — the "cybernetic frame" motif.
class _AnPanelBracketPainter extends CustomPainter {
  const _AnPanelBracketPainter({
    required this.color,
    required this.length,
    required this.thickness,
  });

  final Color color;
  final double length;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    final inset = thickness / 2;
    final maxLength = math.max(
      0.0,
      math.min(size.width, size.height) / 2 - inset,
    );
    final l = length.clamp(0, maxLength);

    final path = Path()
      // Top-left.
      ..moveTo(inset, inset + l)
      ..lineTo(inset, inset)
      ..lineTo(inset + l, inset)
      // Top-right.
      ..moveTo(size.width - inset - l, inset)
      ..lineTo(size.width - inset, inset)
      ..lineTo(size.width - inset, inset + l)
      // Bottom-right.
      ..moveTo(size.width - inset, size.height - inset - l)
      ..lineTo(size.width - inset, size.height - inset)
      ..lineTo(size.width - inset - l, size.height - inset)
      // Bottom-left.
      ..moveTo(inset + l, size.height - inset)
      ..lineTo(inset, size.height - inset)
      ..lineTo(inset, size.height - inset - l);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AnPanelBracketPainter oldDelegate) =>
      color != oldDelegate.color ||
      length != oldDelegate.length ||
      thickness != oldDelegate.thickness;
}

/// Paints a soft gradient band at [progress] (0..1 top-to-bottom) for
/// [AnPanelAccent.scanline].
class _AnPanelScanlinePainter extends CustomPainter {
  const _AnPanelScanlinePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final bandHeight = size.height * 0.25;
    final y = (size.height + bandHeight) * progress - bandHeight;
    final rect = Rect.fromLTWH(0, y, size.width, bandHeight);
    if (rect.height <= 0 || size.width <= 0) return;

    final shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withValues(alpha: 0),
        color.withValues(alpha: 0.35),
        color.withValues(alpha: 0),
      ],
    ).createShader(rect);

    canvas.drawRect(rect, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _AnPanelScanlinePainter oldDelegate) =>
      progress != oldDelegate.progress || color != oldDelegate.color;
}
