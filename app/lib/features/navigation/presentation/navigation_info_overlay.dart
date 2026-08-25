import 'package:flutter/material.dart';

/// Positions the navigation info stack on the left in landscape and keeps it
/// from spanning the full screen width.
class NavigationInfoOverlay extends StatelessWidget {
  const NavigationInfoOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final landscape =
            MediaQuery.orientationOf(context) == Orientation.landscape;
        final width = landscape
            ? (constraints.maxWidth * 0.42).clamp(0.0, 420.0)
            : constraints.maxWidth;
        return Align(
          alignment: landscape ? Alignment.topLeft : Alignment.topCenter,
          child: SizedBox(
            key: const Key('navigationInfoOverlayFrame'),
            width: width,
            child: child,
          ),
        );
      },
    );
  }
}
