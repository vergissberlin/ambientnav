import 'package:ambientnav_ui/ambientnav_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:video_player/video_player.dart';

/// A synthetic "driving" visual shown in place of a live camera feed when no
/// real camera is available. The simulator now prefers a looping MP4 so the
/// background clearly reads as video; the older animated road stays as a
/// fallback while the clip initializes or if playback fails.
class SimulatedCameraBackground extends StatefulWidget {
  const SimulatedCameraBackground({super.key, this.speedMps = 0});

  final double speedMps;

  @override
  State<SimulatedCameraBackground> createState() =>
      _SimulatedCameraBackgroundState();
}

class _SimulatedCameraBackgroundState extends State<SimulatedCameraBackground>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  double _phase = 0;

  VideoPlayerController? _videoController;
  bool _videoInitializing = false;

  /// Slow ambient drift so the fallback animation never looks frozen while
  /// parked.
  static const double _idleSpeedMps = 4;

  /// Metres of "travel" per full dash-repeat cycle.
  static const double _metersPerCycle = 8;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _initVideoBackground();
  }

  Future<void> _initVideoBackground() async {
    if (_videoController != null || _videoInitializing) {
      return;
    }
    _videoInitializing = true;
    try {
      final controller = VideoPlayerController.asset(
        'assets/videos/simulated_camera_background.mp4',
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      setState(() => _videoController = controller);
    } catch (_) {
      // Leave the animated fallback in place.
    } finally {
      _videoInitializing = false;
    }
  }

  void _onTick(Duration elapsed) {
    final dtSeconds =
        (elapsed - _lastElapsed).inMicroseconds /
        Duration.microsecondsPerSecond;
    _lastElapsed = elapsed;
    final speed = widget.speedMps > _idleSpeedMps
        ? widget.speedMps
        : _idleSpeedMps;
    // Advance the road pattern toward the viewer so it reads like forward
    // motion instead of reversing away from the horizon.
    setState(() => _phase = (_phase - dtSeconds * speed / _metersPerCycle) % 1);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _videoController;
    if (controller != null && controller.value.isInitialized) {
      return Stack(
        fit: StackFit.expand,
        children: [_buildVideoPreview(controller), const _VideoWash()],
      );
    }

    return CustomPaint(
      painter: _RoadPainter(phase: _phase),
      child: const SizedBox.expand(),
    );
  }

  Widget _buildVideoPreview(VideoPlayerController controller) {
    final size = controller.value.size;
    final player = size.width > 0 && size.height > 0
        ? FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: VideoPlayer(controller),
            ),
          )
        : VideoPlayer(controller);

    return Positioned.fill(child: player);
  }
}

class _VideoWash extends StatelessWidget {
  const _VideoWash();

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x1A000000), Color(0x0D000000), Color(0x1F000000)],
          ),
        ),
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  _RoadPainter({required this.phase});

  final double phase;

  static const int _dashCount = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final horizonY = size.height * 0.42;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, horizonY),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AnColors.cockpit, AnColors.surface2],
        ).createShader(Rect.fromLTWH(0, 0, size.width, horizonY)),
    );

    final roadRect = Rect.fromLTWH(
      0,
      horizonY,
      size.width,
      size.height - horizonY,
    );
    canvas.drawRect(
      roadRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AnColors.surface3, AnColors.cockpit],
        ).createShader(roadRect),
    );

    // Converging road edges toward a centred vanishing point.
    final vanishingPoint = Offset(size.width / 2, horizonY);
    final edgePaint = Paint()
      ..color = AnColors.lineStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(
      vanishingPoint,
      Offset(size.width * 0.06, size.height),
      edgePaint,
    );
    canvas.drawLine(
      vanishingPoint,
      Offset(size.width * 0.94, size.height),
      edgePaint,
    );

    // Centre dash line, eased so dashes bunch up near the horizon and grow
    // faster near the bottom — a cheap perspective illusion.
    final dashPaint = Paint();
    for (var i = 0; i < _dashCount; i++) {
      final t = ((i / _dashCount) + phase) % 1; // 0 at horizon, 1 at bottom
      final eased = t * t;
      final y = horizonY + eased * (size.height - horizonY);
      final dashWidth = 2 + eased * 10;
      final dashHeight = 6 + eased * 30;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width / 2, y),
            width: dashWidth,
            height: dashHeight,
          ),
          const Radius.circular(2),
        ),
        dashPaint..color = AnColors.cyan.withValues(alpha: 0.15 + eased * 0.6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RoadPainter oldDelegate) =>
      oldDelegate.phase != phase;
}
