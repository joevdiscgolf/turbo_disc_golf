import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

/// Persistent triangle that changes animation behavior based on mode
enum SquareMode {
  pulsing, // Simple pulsing during loading
  exploding, // Spinning and accelerating during explosion
  zooming, // Fading out during zoom
}

class PersistentSquare extends StatefulWidget {
  final SquareMode mode;
  final double size;

  const PersistentSquare({super.key, required this.mode, this.size = 120});

  @override
  State<PersistentSquare> createState() => _PersistentSquareState();
}

class _PersistentSquareState extends State<PersistentSquare>
    with SingleTickerProviderStateMixin {
  // Control flag for size pulsing animation
  static const bool enablePulsing = false;

  late AnimationController _controller;
  double _totalRotation = 0.0; // Track cumulative rotation
  double _lastProgress = 0.0;
  late SquareMode _currentMode;
  DateTime? _modeChangeTime; // Track when mode changed for zooming fade
  double _zoomProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.mode;
    _modeChangeTime = DateTime.now();
    _controller = AnimationController(
      duration: const Duration(
        seconds: 60,
      ), // Long duration for smooth continuous animation
      vsync: this,
    );
    _controller.repeat();
  }

  @override
  void didUpdateWidget(PersistentSquare oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      _currentMode = widget.mode;
      _modeChangeTime = DateTime.now();
      _zoomProgress = 0.0;
      // Mode changed - keep rotation continuous, no jumping
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double progress = _controller.value;

        // Calculate smooth rotation increment
        double progressDelta = progress - _lastProgress;
        if (progressDelta < 0) progressDelta += 1.0; // Handle wrap-around

        // Add rotation based on current mode
        // For reference: 2 rotations/second = progressDelta * 2 * pi * 120
        double rotationIncrement = 0.0;
        switch (_currentMode) {
          case SquareMode.pulsing:
            // Constant rotation during loading - 0.5 rotations per second (completes rotation every 2 seconds)
            rotationIncrement = progressDelta * 2 * pi * 30; // 0.5 rot/sec
            break;
          case SquareMode.exploding:
            // Gradually accelerating rotation - starts at 0.5 rot/sec, builds to 4.0 rot/sec over 3 seconds
            // Use accumulated time for acceleration
            final double elapsedSeconds = _modeChangeTime != null
                ? DateTime.now().difference(_modeChangeTime!).inMilliseconds /
                      1000.0
                : 0.0;
            final double accelerationFactor = (elapsedSeconds / 3.0).clamp(
              0.0,
              1.0,
            );
            final double rotationsPerSecond =
                0.5 + (accelerationFactor * 3.5); // 0.5 → 4.0
            rotationIncrement =
                progressDelta * 2 * pi * (rotationsPerSecond * 60);
            break;
          case SquareMode.zooming:
            // Continue spinning at max speed (4.0 rotations/second)
            rotationIncrement = progressDelta * 2 * pi * 240; // 4.0 rot/sec
            break;
        }

        _totalRotation += rotationIncrement;
        _lastProgress = progress;

        // Smooth pulsing scale based on mode (can be disabled via enablePulsing flag)
        double scale = 1.0;
        if (enablePulsing) {
          switch (_currentMode) {
            case SquareMode.pulsing:
            case SquareMode.exploding:
              // Consistent gentle breathing pulse throughout loading and explosion
              // 1 cycle per 6 seconds, size difference of 4%
              scale = 1.0 + (sin(progress * 2 * pi * 10) * 0.04);
              break;
            case SquareMode.zooming:
              scale = 1.0; // No pulsing while zooming
              break;
          }
        }

        Widget triangle = Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF5B7EFF).withValues(alpha: 0.9), // Solid blue
            boxShadow: [
              // Stronger, more prominent shadows for visibility
              BoxShadow(
                color: const Color(0xFF5B7EFF).withValues(alpha: 0.5),
                blurRadius: 40,
                spreadRadius: 15,
              ),
              BoxShadow(
                color: const Color(0xFF5B7EFF).withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: 10,
              ),
              // Add dark shadow for contrast against bright backgrounds
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CustomPaint(painter: _TrianglePainter()),
        );

        // Apply rotation around center axis
        triangle = Transform.rotate(
          angle: _totalRotation,
          alignment: Alignment.center,
          child: triangle,
        );

        // Apply scale
        triangle = Transform.scale(scale: scale, child: triangle);

        // Apply 8x zoom + blur + fade during zooming/hyperspace mode
        if (_currentMode == SquareMode.zooming && _modeChangeTime != null) {
          // Calculate progress based on time since mode changed (0 to 1 over 2.5 seconds)
          final double elapsedMs = DateTime.now()
              .difference(_modeChangeTime!)
              .inMilliseconds
              .toDouble();
          _zoomProgress = (elapsedMs / 2500.0).clamp(0.0, 1.0);

          // Apply easing curve for smoother zoom start
          final double easedProgress = Curves.easeInCubic.transform(
            _zoomProgress,
          );

          // Apply 8x zoom transformation with easing
          final double zoomScale = 1.0 + (easedProgress * 7.0); // 1.0 → 8.0

          triangle = Transform.scale(
            scale: zoomScale,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: 20.0 * _zoomProgress,
                sigmaY: 20.0 * _zoomProgress,
                tileMode: TileMode.decal,
              ),
              child: Opacity(
                // Fade out 30% earlier: reaches 0 opacity at 70% zoom progress
                opacity: (1.0 - (_zoomProgress / 0.7)).clamp(0.0, 1.0),
                child: triangle,
              ),
            ),
          );
        }

        return triangle;
      },
    );
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double squareSize = size.width * 0.35;

    // Calculate square centered in circle
    final double halfSize = squareSize / 2;

    final Path path = Path();
    // Top-left corner
    path.moveTo(centerX - halfSize, centerY - halfSize);
    // Top-right corner
    path.lineTo(centerX + halfSize, centerY - halfSize);
    // Bottom-right corner
    path.lineTo(centerX + halfSize, centerY + halfSize);
    // Bottom-left corner
    path.lineTo(centerX - halfSize, centerY + halfSize);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter oldDelegate) => false;
}
