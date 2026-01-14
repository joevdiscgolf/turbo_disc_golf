import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated gradient background with floating particles for form analysis screen.
/// Similar to WalkthroughBackground but with a single, form-analysis themed gradient.
class FormAnalysisBackground extends StatefulWidget {
  const FormAnalysisBackground({super.key});

  @override
  State<FormAnalysisBackground> createState() => _FormAnalysisBackgroundState();
}

class _FormAnalysisBackgroundState extends State<FormAnalysisBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _particleController;

  // Form analysis gradient: deep teal/green theme
  static const List<Color> _gradient = [
    Color(0xFF0f3460), // Deep blue
    Color(0xFF16213e), // Midnight blue
    Color(0xFF1a535c), // Dark teal
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
              colors: _gradient,
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

        // Subtle radial glow
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  _gradient[1].withValues(alpha: 0.3),
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
