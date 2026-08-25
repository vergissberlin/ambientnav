import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'nav_controller.dart';

/// The small brand header shown in the navigation app bar.
///
/// Portrait keeps the mark left of the label to stay compact. Landscape stacks
/// the mark above the label so the header reads more like a title block.
class NavigationAppBarTitle extends StatelessWidget {
  const NavigationAppBarTitle({
    super.key,
    required this.label,
    required this.phase,
    required this.speedMps,
  });

  final String label;
  final NavPhase phase;
  final double speedMps;

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1,
        );
    final logo = _DrivingLogoMark(
      key: const Key('navigationHeaderLogo'),
      phase: phase,
      speedMps: speedMps,
      size: isLandscape ? 24 : 26,
    );

    return DefaultTextStyle.merge(
      style: titleStyle,
      child: isLandscape
          ? Column(
              key: const Key('navigationHeaderLandscape'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                logo,
                const SizedBox(height: 4),
                Text(
                  label,
                  key: const Key('navigationHeaderLabel'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )
          : Row(
              key: const Key('navigationHeaderPortrait'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                logo,
                const SizedBox(width: 10),
                Text(
                  label,
                  key: const Key('navigationHeaderLabel'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
    );
  }
}

/// Returns the logo cycle duration for the current speed, or `null` if the
/// logo should stay static.
Duration? navigationLogoCycleDurationFor({
  required NavPhase phase,
  required double speedMps,
}) {
  if (phase != NavPhase.navigating) return null;
  const movingThreshold = 0.8;
  if (speedMps < movingThreshold) return null;

  final normalized = ((speedMps - movingThreshold) / 24).clamp(0.0, 1.0);
  final eased = Curves.easeOut.transform(normalized);
  final milliseconds = lerpDouble(2400, 700, eased)!.round();
  return Duration(milliseconds: milliseconds);
}

class _DrivingLogoMark extends StatefulWidget {
  const _DrivingLogoMark({
    super.key,
    required this.phase,
    required this.speedMps,
    required this.size,
  });

  final NavPhase phase;
  final double speedMps;
  final double size;

  @override
  State<_DrivingLogoMark> createState() => _DrivingLogoMarkState();
}

class _DrivingLogoMarkState extends State<_DrivingLogoMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  @override
  void initState() {
    super.initState();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _DrivingLogoMark oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase != widget.phase ||
        oldWidget.speedMps != widget.speedMps ||
        oldWidget.size != widget.size) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    final duration = navigationLogoCycleDurationFor(
      phase: widget.phase,
      speedMps: widget.speedMps,
    );
    if (duration == null) {
      _controller.stop(canceled: false);
      _controller.value = 0;
      return;
    }

    final durationChanged = _controller.duration != duration;
    _controller.duration = duration;
    if (durationChanged || !_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = navigationLogoCycleDurationFor(
      phase: widget.phase,
      speedMps: widget.speedMps,
    );
    final moving = duration != null;
    final normalized = moving
        ? ((widget.speedMps - 0.8) / 24).clamp(0.0, 1.0)
        : 0.0;

    return AnimatedBuilder(
      animation: _controller,
      child: ExcludeSemantics(
        child: SvgPicture.string(
          _logoSvg,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
        ),
      ),
      builder: (context, child) {
        final phase = moving
            ? math.sin(_controller.value * math.pi * 2)
            : 0.0;
        final scale = 1 + phase * lerpDouble(0.015, 0.03, normalized)!;
        final dy = phase * lerpDouble(0.3, 1.2, normalized)!;
        final opacity = moving ? 0.9 + ((phase + 1) * 0.05) : 1.0;

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
    );
  }
}

const String _logoSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <defs>
    <linearGradient id="ambGrad" x1="0%" y1="100%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#19E3FF"></stop>
      <stop offset="50%" stop-color="#7C5CFF"></stop>
      <stop offset="100%" stop-color="#FF2D9C"></stop>
    </linearGradient>
  </defs>
  <g fill="none" stroke="rgba(255,255,255,0.06)" stroke-width="8.5"
     stroke-linecap="round" stroke-dasharray="0.1 11.5">
    <path d="M23 83 L50 17 L77 83"></path>
    <path d="M35 59 L65 59"></path>
  </g>
  <g fill="none" stroke="url(#ambGrad)" stroke-width="8.5"
     stroke-linecap="round" stroke-dasharray="0.1 11.5"
     style="filter:drop-shadow(0 0 6px rgba(124,92,255,.6))">
    <path d="M23 83 L50 17 L77 83"></path>
    <path d="M35 59 L65 59"></path>
  </g>
</svg>
''';
