import 'package:flutter/material.dart';

/// Keeps the front LED strip preview narrower in landscape so the map remains
/// more visible on the right.
class NavigationInfoStripFrame extends StatelessWidget {
  const NavigationInfoStripFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final landscape =
            MediaQuery.orientationOf(context) == Orientation.landscape;
        final width = landscape
            ? (constraints.maxWidth * 0.78).clamp(0.0, 320.0)
            : constraints.maxWidth;
        return Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            key: const Key('navigationInfoStripFrame'),
            width: width,
            child: child,
          ),
        );
      },
    );
  }
}
