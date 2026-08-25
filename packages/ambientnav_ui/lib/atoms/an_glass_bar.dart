import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/an_brand_theme.dart';

/// The frosted-glass surface behind sticky bars — `backdrop-filter: blur(14px)`
/// over `rgba(6,8,14,.78)` in the web spec (`design-system/readme.md`,
/// "Transparency & blur"). Ports the same treatment to Flutter: whatever sits
/// behind an [AnGlassBar] (a map, a scrolling list) shows through, blurred and
/// tinted toward [AnBrandTheme.cockpit], rather than being hidden by a flat
/// surface fill.
///
/// Wrap this around bar *content* (an [AppBar]'s `flexibleSpace`, a
/// [NavigationBar]) rather than using it as a card background — it needs a
/// transparent bar behind it and non-transparent content behind *that* to
/// have anything to blur. See [AnAppBar] for the header case.
class AnGlassBar extends StatelessWidget {
  const AnGlassBar({
    super.key,
    this.child,
    this.blurSigma = 14,
    this.tintOpacity = 0.78,
    this.border,
  });

  /// Optional content laid over the glass (e.g. a [NavigationBar]).
  final Widget? child;

  /// Matches the web spec's `blur(14px)`.
  final double blurSigma;

  /// Matches the web spec's `rgba(6,8,14,.78)` — 78% of [AnBrandTheme.cockpit].
  final double tintOpacity;

  /// A hairline edge (e.g. [AnBrandTheme.line] on the side facing the
  /// content) — optional since a bottom bar and a top bar want it on
  /// opposite sides.
  final Border? border;

  @override
  Widget build(BuildContext context) {
    final brand = AnBrandTheme.of(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: brand.cockpit.withValues(alpha: tintOpacity),
            border: border,
          ),
          child: child,
        ),
      ),
    );
  }
}
