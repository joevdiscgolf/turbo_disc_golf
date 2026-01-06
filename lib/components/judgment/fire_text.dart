import 'dart:math';

import 'package:flutter/material.dart';

/// A text widget with animated fire/flames rising above it.
///
/// Use [animated] = true for the celebration phase (flames flicker continuously),
/// or [animated] = false for static display (flames frozen in place).
class FireText extends StatefulWidget {
  const FireText({
    super.key,
    required this.text,
    required this.style,
    this.animated = true,
  });

  final String text;
  final TextStyle style;
  final bool animated;

  @override
  State<FireText> createState() => _FireTextState();
}

class _FireTextState extends State<FireText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Flame> _flames;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Generate random flame positions
    _flames = _generateFlames();

    if (widget.animated) {
      _controller.repeat();
    } else {
      // Set to a fixed value for static display
      _controller.value = 0.5;
    }
  }

  List<_Flame> _generateFlames() {
    final Random random = Random(widget.text.hashCode);
    final List<_Flame> flames = [];

    // Generate 6-8 flames at random horizontal positions
    final int flameCount = 6 + random.nextInt(3);
    for (int i = 0; i < flameCount; i++) {
      flames.add(_Flame(
        // Spread flames across the text width (0.05 to 0.95)
        xPosition: 0.05 + random.nextDouble() * 0.9,
        // Stagger phase for natural look
        phase: random.nextDouble(),
        // Vary flame height
        maxHeight: 20 + random.nextDouble() * 25,
        // Vary flame width
        width: 10 + random.nextDouble() * 12,
        // Vary flicker speed
        flickerSpeed: 0.8 + random.nextDouble() * 0.4,
      ));
    }

    return flames;
  }

  @override
  void didUpdateWidget(FireText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animated != oldWidget.animated) {
      if (widget.animated) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.value = 0.5;
      }
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
        return CustomPaint(
          painter: _FirePainter(
            flames: _flames,
            animationValue: _controller.value,
            animated: widget.animated,
          ),
          child: child,
        );
      },
      child: Text(widget.text, style: widget.style),
    );
  }
}

class _Flame {
  const _Flame({
    required this.xPosition,
    required this.phase,
    required this.maxHeight,
    required this.width,
    required this.flickerSpeed,
  });

  /// Horizontal position as fraction of text width (0.0 - 1.0)
  final double xPosition;

  /// Phase offset for staggered animation (0.0 - 1.0)
  final double phase;

  /// Maximum flame height in logical pixels
  final double maxHeight;

  /// Flame width at base in logical pixels
  final double width;

  /// Flicker speed multiplier
  final double flickerSpeed;
}

class _FirePainter extends CustomPainter {
  _FirePainter({
    required this.flames,
    required this.animationValue,
    required this.animated,
  });

  final List<_Flame> flames;
  final double animationValue;
  final bool animated;

  // Fire color layers (from outside to inside)
  static const Color _outerRed = Color(0xFFFF4500);    // Orange-red
  static const Color _midOrange = Color(0xFFFF8C00);   // Dark orange
  static const Color _innerYellow = Color(0xFFFFD700); // Gold
  static const Color _coreWhite = Color(0xFFFFFF99);   // Light yellow

  @override
  void paint(Canvas canvas, Size size) {
    // Paint flames from back to front (larger first)
    final List<_Flame> sortedFlames = List.from(flames)
      ..sort((a, b) => b.width.compareTo(a.width));

    for (final flame in sortedFlames) {
      _paintFlame(canvas, size, flame);
    }
  }

  void _paintFlame(Canvas canvas, Size size, _Flame flame) {
    // Calculate flicker effect
    double flicker;
    if (animated) {
      // Sinusoidal flicker with phase offset
      final double t = (animationValue * flame.flickerSpeed + flame.phase) % 1.0;
      flicker = 0.7 + 0.3 * sin(t * 2 * pi);
    } else {
      // Static: use phase for variety
      flicker = 0.7 + 0.3 * sin(flame.phase * 2 * pi);
    }

    final double x = flame.xPosition * size.width;
    final double baseY = 4; // Start slightly above text top
    final double currentHeight = flame.maxHeight * flicker;
    final double currentWidth = flame.width * flicker;

    // Draw multiple layers for depth
    _drawFlameLayer(canvas, x, baseY, currentHeight, currentWidth, _outerRed, 1.0);
    _drawFlameLayer(canvas, x, baseY, currentHeight * 0.8, currentWidth * 0.7, _midOrange, 0.95);
    _drawFlameLayer(canvas, x, baseY, currentHeight * 0.6, currentWidth * 0.5, _innerYellow, 0.9);
    _drawFlameLayer(canvas, x, baseY, currentHeight * 0.35, currentWidth * 0.25, _coreWhite, 0.85);
  }

  void _drawFlameLayer(
    Canvas canvas,
    double x,
    double baseY,
    double height,
    double width,
    Color color,
    double opacity,
  ) {
    final Paint paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          color.withValues(alpha: opacity),
          color.withValues(alpha: opacity * 0.6),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(x - width / 2, baseY - height, width, height));

    final Path path = Path();

    // Base of flame
    path.moveTo(x - width / 2, baseY);

    // Left side curve up
    path.quadraticBezierTo(
      x - width / 3,
      baseY - height * 0.4,
      x - width / 6,
      baseY - height * 0.7,
    );

    // Tip of flame
    path.quadraticBezierTo(
      x,
      baseY - height * 1.1,
      x + width / 6,
      baseY - height * 0.7,
    );

    // Right side curve down
    path.quadraticBezierTo(
      x + width / 3,
      baseY - height * 0.4,
      x + width / 2,
      baseY,
    );

    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_FirePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
