import 'dart:math';

import 'package:flutter/material.dart';

/// Brain-themed explosion effect for form analysis completion.
///
/// Brain stays centered and emits particles in random directions as explosion intensifies.
class BrainExplosionEffect extends StatelessWidget {
  const BrainExplosionEffect({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Radial gradient bursts (cyan colors)
        Positioned.fill(
          child: CustomPaint(
            painter: _RadialBurstPainter(
              progress: progress,
              color1: const Color(0xFF4DD0E1),
              color2: const Color(0xFF7FE9F5),
            ),
          ),
        ),

        // Particle bursts emanating from brain
        Positioned.fill(
          child: CustomPaint(
            painter: _BrainParticleBurstPainter(
              progress: progress,
              particleColor: const Color(0xFF4DD0E1),
            ),
          ),
        ),

        // Brain in center with pulsing glow (no rotation)
        Center(
          child: Transform.scale(
            scale: 1.0 + (sin(progress * 2 * pi * 6) * 0.15 * progress),
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4DD0E1).withValues(
                      alpha: 0.6 * progress,
                    ),
                    blurRadius: 40 + (progress * 20),
                    spreadRadius: 10 + (progress * 10),
                  ),
                  BoxShadow(
                    color: const Color(0xFF7FE9F5).withValues(
                      alpha: 0.4 * progress,
                    ),
                    blurRadius: 60 + (progress * 30),
                    spreadRadius: 20 + (progress * 15),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/emojis/brain_emoji.png',
                width: 78,
                height: 78,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Painter for radial gradient bursts expanding outward
class _RadialBurstPainter extends CustomPainter {
  _RadialBurstPainter({
    required this.progress,
    required this.color1,
    required this.color2,
  });

  final double progress;
  final Color color1;
  final Color color2;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double intensity = progress;

    // Primary burst
    final double burst1Progress = (progress * 1.5) % 1.0;
    final Paint burst1 = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.5 + (burst1Progress * 1.0),
        colors: [
          color1.withValues(alpha: 0.6 * intensity * (1 - burst1Progress)),
          color2.withValues(alpha: 0.4 * intensity * (1 - burst1Progress)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width));

    canvas.drawCircle(center, size.width, burst1);

    // Secondary burst with offset timing
    final double burst2Progress = ((progress + 0.5) * 1.5) % 1.0;
    final Paint burst2 = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.6 + (burst2Progress * 1.2),
        colors: [
          color2.withValues(alpha: 0.5 * intensity * (1 - burst2Progress)),
          color1.withValues(alpha: 0.3 * intensity * (1 - burst2Progress)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width));

    canvas.drawCircle(center, size.width, burst2);
  }

  @override
  bool shouldRepaint(_RadialBurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Painter for particles emanating from brain center
class _BrainParticleBurstPainter extends CustomPainter {
  _BrainParticleBurstPainter({
    required this.progress,
    required this.particleColor,
  });

  final double progress;
  final Color particleColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Random random = Random(42); // Fixed seed for consistency

    // Number of particles increases with progress
    final int particleCount = (progress * 80).toInt();

    for (int i = 0; i < particleCount; i++) {
      // Random angle for this particle
      final double angle = random.nextDouble() * 2 * pi;

      // Random speed variation
      final double speedVariation = 0.7 + random.nextDouble() * 0.6;

      // Distance from center increases with progress
      final double maxDistance = 600.0;
      final double distance = maxDistance * progress * speedVariation;

      // Calculate position
      final double x = center.dx + distance * cos(angle);
      final double y = center.dy + distance * sin(angle);

      // Skip if off screen
      if (x < -20 || x > size.width + 20 || y < -20 || y > size.height + 20) {
        continue;
      }

      // Particle size: starts at 4, shrinks to 2
      final double particleSize = 4.0 - (progress * 2.0);

      // Opacity fades in quickly then gradually fades out
      final double opacity = progress < 0.3
          ? progress / 0.3
          : 1.0 - ((progress - 0.3) / 0.7);

      // Draw particle as simple circle
      final Paint paint = Paint()
        ..color = particleColor.withValues(alpha: opacity * 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particleSize, paint);

      // Add slight glow
      if (particleSize > 2.5 && opacity > 0.3) {
        final Paint glowPaint = Paint()
          ..color = particleColor.withValues(alpha: opacity * 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), particleSize + 2, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_BrainParticleBurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
