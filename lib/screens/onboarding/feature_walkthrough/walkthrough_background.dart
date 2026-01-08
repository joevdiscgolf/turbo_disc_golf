import 'dart:math' as math;

import 'package:flutter/material.dart';

class WalkthroughBackground extends StatefulWidget {
  const WalkthroughBackground({super.key, required this.currentPage});

  final int currentPage;

  @override
  State<WalkthroughBackground> createState() => _WalkthroughBackgroundState();
}

class _WalkthroughBackgroundState extends State<WalkthroughBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _particleController;

  // Gradient colors for each scene
  static const List<List<Color>> _sceneGradients = [
    // Scene 1: Deep purple to midnight blue (recording)
    [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f0f23)],
    // Scene 2: Deeper blue to teal (processing)
    [Color(0xFF0f3460), Color(0xFF16213e), Color(0xFF1a1a2e)],
    // Scene 3: Teal to green undertones (insights)
    [Color(0xFF1a535c), Color(0xFF16213e), Color(0xFF0f3460)],
    // Scene 4: Warm teal to green (complete)
    [Color(0xFF1a535c), Color(0xFF2d6a4f), Color(0xFF1b4332)],
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
    final List<Color> colors = _sceneGradients[widget.currentPage];

    return Stack(
      children: [
        // Main gradient background
        AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
              stops: const [0.0, 0.5, 1.0],
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [colors[1].withValues(alpha: 0.3), Colors.transparent],
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
