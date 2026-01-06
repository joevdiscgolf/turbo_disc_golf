import 'dart:math';

import 'package:flutter/material.dart';

/// Explosive reveal effect shown when the judgment verdict locks in.
///
/// Features particle bursts in themed colors (red for roast, gold for glaze).
class JudgmentRevealEffect extends StatefulWidget {
  const JudgmentRevealEffect({
    super.key,
    required this.isGlaze,
    this.onComplete,
  });

  final bool isGlaze;
  final VoidCallback? onComplete;

  @override
  State<JudgmentRevealEffect> createState() => _JudgmentRevealEffectState();
}

class _JudgmentRevealEffectState extends State<JudgmentRevealEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = widget.isGlaze
        ? const Color(0xFFFFD700) // Gold
        : const Color(0xFFFF6B6B); // Red
    final Color secondaryColor = widget.isGlaze
        ? const Color(0xFFFFA500) // Orange-gold
        : const Color(0xFFFF8C42); // Orange

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double progress = _controller.value;

        return Stack(
          children: [
            // Background flash
            Positioned.fill(
              child: Container(
                color: primaryColor.withValues(
                  alpha: 0.3 * (1 - progress),
                ),
              ),
            ),

            // Radial gradient burst - primary
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.3 + (progress * 1.5),
                    colors: [
                      primaryColor.withValues(
                        alpha: 0.6 * (1 - progress),
                      ),
                      secondaryColor.withValues(
                        alpha: 0.4 * (1 - progress),
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Particle burst
            Positioned.fill(
              child: CustomPaint(
                painter: _JudgmentParticlePainter(
                  progress: progress,
                  primaryColor: primaryColor,
                  secondaryColor: secondaryColor,
                ),
              ),
            ),

            // Energy ring
            Center(
              child: Container(
                width: 200 + (progress * 400),
                height: 200 + (progress * 400),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor.withValues(
                      alpha: 0.5 * (1 - progress),
                    ),
                    width: 4 * (1 - progress),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Painter for particle burst effect.
class _JudgmentParticlePainter extends CustomPainter {
  _JudgmentParticlePainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final double progress;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Random random = Random(42); // Fixed seed for consistency

    // Fade out in last 30%
    final double opacity = progress > 0.7
        ? 1.0 - ((progress - 0.7) / 0.3)
        : 1.0;

    if (opacity < 0.01) return;

    // Draw particles radiating outward
    const int particleCount = 48;
    for (int i = 0; i < particleCount; i++) {
      final double angle = (i / particleCount) * 2 * pi;
      final double speedVariation = 0.8 + (random.nextDouble() * 0.4);
      final double maxDistance = 600.0;
      final double distance = maxDistance * progress * speedVariation;

      final double x = center.dx + distance * cos(angle);
      final double y = center.dy + distance * sin(angle);

      // Skip if off screen
      if (x < -20 || x > size.width + 20 || y < -20 || y > size.height + 20) {
        continue;
      }

      // Particle size shrinks as it travels
      final double particleSize = 6.0 - (progress * 4.0);
      if (particleSize <= 0) continue;

      // Alternate colors
      final Color color = i % 2 == 0 ? primaryColor : secondaryColor;

      final Paint paint = Paint()
        ..color = color.withValues(alpha: opacity * 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particleSize, paint);

      // Add glow
      if (particleSize > 3) {
        final Paint glowPaint = Paint()
          ..color = color.withValues(alpha: opacity * 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), particleSize + 3, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_JudgmentParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
