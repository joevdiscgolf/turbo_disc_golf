import 'dart:math' as math;

import 'package:flutter/material.dart';

class LandingBackground extends StatefulWidget {
  const LandingBackground({super.key});

  @override
  State<LandingBackground> createState() => _LandingBackgroundState();
}

class _LandingBackgroundState extends State<LandingBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _particleController;

  // Deep purple to midnight blue gradient (like walkthrough scene 1)
  static const List<Color> _gradientColors = [
    Color(0xFF1a1a2e),
    Color(0xFF16213e),
    Color(0xFF0f0f23),
  ];

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _gradientColors,
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),

        // Animated particles overlay
        AnimatedBuilder(
          animation: _particleController,
          builder: (context, child) {
            return CustomPaint(
              painter: _ParticlePainter(
                progress: _particleController.value,
                particleColor: Colors.white.withValues(alpha: 0.05),
              ),
              size: Size.infinite,
            );
          },
        ),

        // Subtle radial glow in center
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.3),
                radius: 1.2,
                colors: [
                  const Color(0xFF16213e).withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.progress, required this.particleColor});

  final double progress;
  final Color particleColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = particleColor;

    // Generate deterministic particles based on index
    for (int i = 0; i < 30; i++) {
      final double seed = i * 137.5; // Golden angle for distribution
      final double x = (seed % size.width);
      final double baseY = (seed * 2.3) % size.height;

      // Animate Y position (floating upward)
      final double animatedY =
          (baseY - (progress * size.height * 0.5) + size.height) % size.height;

      // Vary size based on index
      final double radius = 1.0 + (i % 3) * 0.5;

      // Vary opacity based on position
      final double opacity = 0.3 + 0.4 * math.sin(progress * math.pi * 2 + i);
      paint.color = particleColor.withValues(alpha: opacity * 0.3);

      canvas.drawCircle(Offset(x, animatedY), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
