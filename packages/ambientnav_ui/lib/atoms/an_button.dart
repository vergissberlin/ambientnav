import 'package:flutter/material.dart';

import '../theme/an_brand_theme.dart';
import '../tokens/an_tokens.dart';

/// Port of `design-system/components/core/Button.jsx`.
///
/// Variants follow the light language rather than a generic emphasis ladder:
/// [primary] is Guide Cyan (direction), [alert] is Alert Magenta (warning),
/// [gradient] is the brand hero CTA, and [secondary]/[ghost] stay quiet.
enum AnButtonVariant { primary, alert, gradient, secondary, ghost }

enum AnButtonSize { sm, md, lg }

/// A signal-aware button.
///
/// Reproduces the web spec's press-scale and glow, which means it uses a
/// [GestureDetector] rather than a Material button and therefore has **no ink
/// ripple, focus ring or keyboard activation**. Use it on brand surfaces; keep
/// Material's buttons for form controls, where those affordances matter.
class AnButton extends StatefulWidget {
  const AnButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AnButtonVariant.primary,
    this.size = AnButtonSize.md,
    this.iconLeft,
    this.iconRight,
  });

  final String label;

  /// A null callback disables the button — the Flutter idiom, replacing the
  /// web API's separate `disabled` flag.
  final VoidCallback? onPressed;

  final AnButtonVariant variant;
  final AnButtonSize size;
  final Widget? iconLeft;
  final Widget? iconRight;

  @override
  State<AnButton> createState() => _AnButtonState();
}

@immutable
class _AnButtonStyle {
  const _AnButtonStyle({
    required this.foreground,
    this.background,
    this.gradient,
    this.border,
    this.shadows = const <BoxShadow>[],
  });

  final Color foreground;
  final Color? background;
  final Gradient? gradient;
  final BoxBorder? border;
  final List<BoxShadow> shadows;
}

class _AnButtonState extends State<AnButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  EdgeInsetsGeometry get _padding => switch (widget.size) {
    AnButtonSize.sm => const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    AnButtonSize.md => const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    AnButtonSize.lg => const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
  };

  double get _fontSize => switch (widget.size) {
    AnButtonSize.sm => 13,
    AnButtonSize.md => 15,
    AnButtonSize.lg => 16,
  };

  _AnButtonStyle _style(AnBrandTheme brand) => switch (widget.variant) {
    AnButtonVariant.primary => const _AnButtonStyle(
      foreground: AnColors.cyanDeep,
      background: AnColors.cyan,
      shadows: AnShadows.glowCyan,
    ),
    AnButtonVariant.alert => const _AnButtonStyle(
      foreground: Color(0xFF2A0719),
      background: AnColors.magenta,
      shadows: AnShadows.glowMagenta,
    ),
    AnButtonVariant.gradient => const _AnButtonStyle(
      foreground: AnColors.cockpit,
      gradient: AnColors.gradientH,
      shadows: AnShadows.glowViolet,
    ),
    AnButtonVariant.secondary => _AnButtonStyle(
      foreground: brand.text,
      background: brand.surface3,
      border: Border.all(color: brand.lineStrong),
    ),
    AnButtonVariant.ghost => _AnButtonStyle(
      foreground: brand.text2,
      background: Colors.transparent,
      border: Border.all(color: brand.line),
    ),
  };

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final style = _style(AnBrandTheme.of(context));

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: MouseRegion(
        cursor: _enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTapDown: _enabled ? (_) => _setPressed(true) : null,
          onTapUp: _enabled ? (_) => _setPressed(false) : null,
          onTapCancel: _enabled ? () => _setPressed(false) : null,
          onTap: widget.onPressed,
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: AnMotion.fast,
            curve: AnMotion.easeGlow,
            child: Opacity(
              opacity: _enabled ? 1.0 : 0.4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: style.background,
                  gradient: style.gradient,
                  border: style.border,
                  borderRadius: BorderRadius.circular(AnRadius.sm),
                  boxShadow: _enabled ? style.shadows : const <BoxShadow>[],
                ),
                child: Padding(
                  padding: _padding,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 9,
                    children: [
                      ?widget.iconLeft,
                      Text(
                        widget.label,
                        style: AnTypography.buttonLabel(
                          _fontSize,
                        ).copyWith(color: style.foreground),
                      ),
                      ?widget.iconRight,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
