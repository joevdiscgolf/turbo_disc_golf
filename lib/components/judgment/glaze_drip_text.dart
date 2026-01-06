import 'dart:math';

import 'package:flutter/material.dart';

/// A text widget with animated honey/glaze drips falling from the bottom.
///
/// Use [animated] = true for the celebration phase (drips fall continuously),
/// or [animated] = false for static display (drips frozen in place).
class GlazeDripText extends StatefulWidget {
  const GlazeDripText({
    super.key,
    required this.text,
    required this.style,
    this.animated = true,
    this.dripColor,
  });

  final String text;
  final TextStyle style;
  final bool animated;

  /// Color of the drips. Defaults to gold gradient.
  final Color? dripColor;

  @override
  State<GlazeDripText> createState() => _GlazeDripTextState();
}

class _GlazeDripTextState extends State<GlazeDripText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Drip> _drips;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Generate random drip positions
    _drips = _generateDrips();

    if (widget.animated) {
      _controller.repeat();
    } else {
      // Set to a fixed value for static display
      _controller.value = 0.6;
    }
  }

  List<_Drip> _generateDrips() {
    final Random random = Random(widget.text.hashCode);
    final List<_Drip> drips = [];

    // Generate 4-6 drips at random horizontal positions
    final int dripCount = 4 + random.nextInt(3);
    for (int i = 0; i < dripCount; i++) {
      drips.add(_Drip(
        // Spread drips across the text width (0.1 to 0.9)
        xPosition: 0.1 + random.nextDouble() * 0.8,
        // Stagger start times for natural look
        startPhase: random.nextDouble(),
        // Vary drip length
        maxLength: 15 + random.nextDouble() * 20,
        // Vary drip width
        width: 4 + random.nextDouble() * 4,
        // Vary fall speed
        speed: 0.7 + random.nextDouble() * 0.6,
      ));
    }

    return drips;
  }

  @override
  void didUpdateWidget(GlazeDripText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animated != oldWidget.animated) {
      if (widget.animated) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.value = 0.6;
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
    final Color baseColor = widget.dripColor ?? const Color(0xFF137e66);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _GlazeDripPainter(
            drips: _drips,
            animationValue: _controller.value,
            baseColor: baseColor,
            animated: widget.animated,
          ),
          child: child,
        );
      },
      child: Text(widget.text, style: widget.style),
    );
  }
}

class _Drip {
  const _Drip({
    required this.xPosition,
    required this.startPhase,
    required this.maxLength,
    required this.width,
    required this.speed,
  });

  /// Horizontal position as fraction of text width (0.0 - 1.0)
  final double xPosition;

  /// Start phase offset for staggered animation (0.0 - 1.0)
  final double startPhase;

  /// Maximum drip length in logical pixels
  final double maxLength;

  /// Drip width in logical pixels
  final double width;

  /// Speed multiplier
  final double speed;
}

class _GlazeDripPainter extends CustomPainter {
  _GlazeDripPainter({
    required this.drips,
    required this.animationValue,
    required this.baseColor,
    required this.animated,
  });

  final List<_Drip> drips;
  final double animationValue;
  final Color baseColor;
  final bool animated;

  @override
  void paint(Canvas canvas, Size size) {
    for (final drip in drips) {
      _paintDrip(canvas, size, drip);
    }
  }

  void _paintDrip(Canvas canvas, Size size, _Drip drip) {
    // Calculate drip progress with phase offset
    double progress;
    if (animated) {
      // Looping animation with staggered starts
      progress = ((animationValue * drip.speed) + drip.startPhase) % 1.0;
      // Ease-in-out for more natural dripping motion
      progress = _smoothStep(progress);
    } else {
      // Static: show drips at varying lengths based on their phase
      progress = 0.5 + drip.startPhase * 0.4;
    }

    final double x = drip.xPosition * size.width;
    final double topY = size.height - 2; // Start just below text
    final double currentLength = drip.maxLength * progress;
    final double bottomY = topY + currentLength;

    // Create gradient for honey/glaze effect
    final Paint paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          baseColor,
          baseColor.withValues(alpha: 0.9),
          _darken(baseColor, 0.15),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(x - drip.width / 2, topY, drip.width, currentLength));

    // Draw the drip as a rounded path
    final Path path = Path();

    // Top rounded part (connects to text)
    path.moveTo(x - drip.width / 2, topY);
    path.lineTo(x + drip.width / 2, topY);

    // Right side going down
    path.lineTo(x + drip.width / 2, bottomY - drip.width / 2);

    // Bottom rounded tip
    path.quadraticBezierTo(
      x + drip.width / 2,
      bottomY,
      x,
      bottomY + drip.width / 3,
    );
    path.quadraticBezierTo(
      x - drip.width / 2,
      bottomY,
      x - drip.width / 2,
      bottomY - drip.width / 2,
    );

    // Left side going up
    path.lineTo(x - drip.width / 2, topY);
    path.close();

    canvas.drawPath(path, paint);

    // Add shine highlight
    final Paint shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final Path shinePath = Path();
    shinePath.moveTo(x - drip.width / 4, topY + 3);
    shinePath.lineTo(x - drip.width / 4, topY + currentLength * 0.4);

    canvas.drawPath(shinePath, shinePaint);
  }

  double _smoothStep(double t) {
    return t * t * (3 - 2 * t);
  }

  Color _darken(Color color, double amount) {
    final HSLColor hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  @override
  bool shouldRepaint(_GlazeDripPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
