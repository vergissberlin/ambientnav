import 'package:flutter/material.dart';

import 'an_glass_bar.dart';

/// A frosted-glass header — same [AppBar] behaviour (title, actions, a
/// bottom [TabBar], theme-driven text/icon color), but transparent with an
/// [AnGlassBar] behind it instead of a flat surface fill. Requires the
/// [Scaffold] it sits in to set `extendBodyBehindAppBar: true` and its body's
/// top content to be padded by [preferredSize] — otherwise there's nothing
/// but the scaffold's background color behind the glass to blur.
class AnAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AnAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.centerTitle,
    this.bottom,
  });

  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool? centerTitle;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      centerTitle: centerTitle,
      bottom: bottom,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: const AnGlassBar(),
    );
  }
}
