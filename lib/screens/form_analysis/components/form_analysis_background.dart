import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Elegant animated gradient background with floating particles for form analysis.
/// Uses the app's light pastel color scheme with subtle teal and purple accents.
class FormAnalysisBackground extends StatefulWidget {
  const FormAnalysisBackground({super.key});

  @override
  State<FormAnalysisBackground> createState() => _FormAnalysisBackgroundState();
}

class _FormAnalysisBackgroundState extends State<FormAnalysisBackground>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _gradientController;

  // Light pastel gradient matching the rest of the app
  static const List<Color> _gradientColors = [
    Color(0xFFEEE8F5), // Soft lavender
    Color(0xFFE8F4F0), // Mint tint
    Color(0xFFECECEE), // Soft gray
    Color(0xFFE8F4E8), // Soft green
  ];

  // Brand accent colors for particles
  static const Color _tealAccent = Color(0xFF137e66);
  static const Color _purpleAccent = Color(0xFF9C7AB8);

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();

    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _particleController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animated gradient background with subtle shift
        AnimatedBuilder(
          animation: _gradientController,
          builder: (context, child) {
            final double t = _gradientController.value;
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft + Alignment(t * 0.3, t * 0.2),
                  end: Alignment.bottomRight + Alignment(-t * 0.2, -t * 0.3),
                  colors: _gradientColors,
                  stops: const [0.0, 0.35, 0.65, 1.0],
                ),
              ),
            );
          },
        ),

        // Soft radial highlight in center (where loader will be)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.8,
                colors: [
                  Colors.white.withValues(alpha: 0.4),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),

        // Floating particles layer
        AnimatedBuilder(
          animation: _particleController,
          builder: (context, child) {
            return CustomPaint(
              painter: _LightParticlePainter(
                progress: _particleController.value,
                tealColor: _tealAccent,
                purpleColor: _purpleAccent,
              ),
              size: Size.infinite,
            );
          },
        ),

        // Subtle bokeh orbs
        AnimatedBuilder(
          animation: _particleController,
          builder: (context, child) {
            return CustomPaint(
              painter: _BokehPainter(
                progress: _particleController.value,
                tealColor: _tealAccent,
                purpleColor: _purpleAccent,
              ),
              size: Size.infinite,
            );
          },
        ),
      ],
    );
  }
}

/// Paints small floating particles in brand colors
class _LightParticlePainter extends CustomPainter {
  _LightParticlePainter({
    required this.progress,
    required this.tealColor,
    required this.purpleColor,
  });

  final double progress;
  final Color tealColor;
  final Color purpleColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint tealPaint = Paint();
    final Paint purplePaint = Paint();

    // Generate deterministic particles
    for (int i = 0; i < 40; i++) {
      final double seed = i * 137.5; // Golden angle
      final double x = (seed % size.width);
      final double baseY = (seed * 2.7) % size.height;

      // Floating upward animation with varying speeds
      final double speedFactor = 0.3 + (i % 5) * 0.15;
      final double animatedY =
          (baseY - (progress * size.height * speedFactor) + size.height) %
          size.height;

      // Horizontal drift
      final double xDrift =
          math.sin(progress * math.pi * 2 + i * 0.5) * 15;

      // Size variation
      final double radius = 1.5 + (i % 4) * 0.8;

      // Opacity pulsing
      final double baseOpacity = 0.15 + 0.15 * math.sin(progress * math.pi * 2 + i);

      // Alternate between teal and purple
      final bool isTeal = i % 3 != 0;
      final Paint paint = isTeal ? tealPaint : purplePaint;
      paint.color = (isTeal ? tealColor : purpleColor).withValues(alpha: baseOpacity);

      canvas.drawCircle(Offset(x + xDrift, animatedY), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_LightParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Paints larger, soft bokeh orbs for depth
class _BokehPainter extends CustomPainter {
  _BokehPainter({
    required this.progress,
    required this.tealColor,
    required this.purpleColor,
  });

  final double progress;
  final Color tealColor;
  final Color purpleColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Create a few large, soft bokeh orbs
    final List<_BokehOrb> orbs = [
      _BokehOrb(
        baseX: 0.15,
        baseY: 0.25,
        radius: 60,
        color: tealColor,
        phaseOffset: 0,
      ),
      _BokehOrb(
        baseX: 0.85,
        baseY: 0.35,
        radius: 45,
        color: purpleColor,
        phaseOffset: 1.5,
      ),
      _BokehOrb(
        baseX: 0.25,
        baseY: 0.75,
        radius: 50,
        color: purpleColor,
        phaseOffset: 3.0,
      ),
      _BokehOrb(
        baseX: 0.75,
        baseY: 0.8,
        radius: 55,
        color: tealColor,
        phaseOffset: 4.5,
      ),
      _BokehOrb(
        baseX: 0.5,
        baseY: 0.15,
        radius: 40,
        color: tealColor,
        phaseOffset: 2.2,
      ),
    ];

    for (final orb in orbs) {
      // Gentle floating motion
      final double floatX = math.sin(progress * math.pi * 2 + orb.phaseOffset) * 20;
      final double floatY = math.cos(progress * math.pi * 2 + orb.phaseOffset) * 15;

      final double x = size.width * orb.baseX + floatX;
      final double y = size.height * orb.baseY + floatY;

      // Pulsing opacity
      final double opacity =
          0.04 + 0.03 * math.sin(progress * math.pi * 2 + orb.phaseOffset);

      final Paint paint = Paint()
        ..color = orb.color.withValues(alpha: opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, orb.radius * 0.6);

      canvas.drawCircle(Offset(x, y), orb.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_BokehPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _BokehOrb {
  const _BokehOrb({
    required this.baseX,
    required this.baseY,
    required this.radius,
    required this.color,
    required this.phaseOffset,
  });

  final double baseX; // 0-1 relative to screen width
  final double baseY; // 0-1 relative to screen height
  final double radius;
  final Color color;
  final double phaseOffset;
}
