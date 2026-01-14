import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Loading animation with atomic nucleus visualization.
///
/// Displays a brain emoji as the nucleus with orbiting particles on two tilted axes,
/// creating a 3D sphere effect. Particles have comet tails and fade when behind the brain.
class AtomicNucleusLoader extends StatelessWidget {
  const AtomicNucleusLoader({
    super.key,
    this.size = 240.0,
    this.particleCount = 3, // particles per orbit
  });

  final double size;
  final int particleCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Morphing background blobs
          _MorphingBackground(size: size),

          // Orbit 1: -30° tilt (slower)
          _AtomicOrbit(
            size: size,
            radius: size * 0.395, // 95px for 240px
            particleCount: particleCount,
            orbitDuration: const Duration(milliseconds: 8000),
            tiltAngle: -30, // -30° tilt
            particleColor: const Color(0xFF4DD0E1),
          ),

          // Orbit 2: +30° tilt (faster)
          _AtomicOrbit(
            size: size,
            radius: size * 0.395, // 95px for 240px
            particleCount: particleCount,
            orbitDuration: const Duration(milliseconds: 6000),
            tiltAngle: 30, // +30° tilt
            particleColor: const Color(0xFF4DD0E1),
          ),

          // Center brain emoji with pink glow (nucleus)
          _buildNucleus(),
        ],
      ),
    );
  }

  Widget _buildNucleus() {
    return Container(
      width: 100,
      height: 100,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        // No circular container - just glow
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4DA6).withValues(alpha: 0.4), // Pink glow
            blurRadius: 28,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Text(
        '🧠',
        style: TextStyle(fontSize: 72),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          duration: 2500.ms,
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.15, 1.15), // Stronger pulse
          curve: Curves.easeInOut,
        )
        .then()
        .shimmer(
          duration: 2000.ms,
          color: const Color(0xFFFF4DA6).withValues(alpha: 0.3),
        );
  }
}

class _MorphingBackground extends StatelessWidget {
  const _MorphingBackground({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          _buildBlob(
            colors: const [Color(0xFF0C5349), Color(0xFF137e66)],
            duration: 5000.ms,
            scaleBegin: 1.0,
            scaleEnd: 1.25,
          ),
          _buildBlob(
            colors: const [Color(0xFF137e66), Color(0xFF26B39D)],
            duration: 4200.ms,
            scaleBegin: 0.95,
            scaleEnd: 1.15,
          ),
        ],
      ),
    );
  }

  Widget _buildBlob({
    required List<Color> colors,
    required Duration duration,
    required double scaleBegin,
    required double scaleEnd,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: colors,
          stops: const [0.0, 1.0],
        ),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          duration: duration,
          begin: Offset(scaleBegin, scaleBegin),
          end: Offset(scaleEnd, scaleEnd),
          curve: Curves.easeInOut,
        );
  }
}

class _AtomicOrbit extends StatefulWidget {
  const _AtomicOrbit({
    required this.size,
    required this.radius,
    required this.particleCount,
    required this.orbitDuration,
    required this.tiltAngle, // Tilt in degrees (e.g., +20 or -20)
    required this.particleColor,
  });

  final double size;
  final double radius;
  final int particleCount;
  final Duration orbitDuration;
  final double tiltAngle; // Orbital plane tilt in degrees
  final Color particleColor;

  @override
  State<_AtomicOrbit> createState() => _AtomicOrbitState();
}

class _AtomicOrbitState extends State<_AtomicOrbit>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.orbitDuration,
    )..repeat();
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
          size: Size(widget.size, widget.size),
          painter: _AtomicOrbitPainter(
            progress: _controller.value,
            radius: widget.radius,
            particleCount: widget.particleCount,
            tiltAngle: widget.tiltAngle,
            particleColor: widget.particleColor,
          ),
        );
      },
    );
  }
}

class _AtomicOrbitPainter extends CustomPainter {
  _AtomicOrbitPainter({
    required this.progress,
    required this.radius,
    required this.particleCount,
    required this.tiltAngle,
    required this.particleColor,
  });

  final double progress;
  final double radius;
  final int particleCount;
  final double tiltAngle; // Degrees
  final Color particleColor;

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double particleSize = 5.0; // 10px diameter = 5px radius
    final double tiltRad = tiltAngle * math.pi / 180; // Convert to radians

    // Each particle orbits at a different speed for dynamic, independent motion
    final List<double> speedMultipliers = [1.0, 0.7, 1.3];

    // Draw particles with tails
    for (int i = 0; i < particleCount; i++) {
      // Calculate angle for this particle with independent speed
      final double speed = speedMultipliers[i % speedMultipliers.length];
      final double angle = progress * 2 * math.pi * speed;

      // Calculate 3D position on tilted horizontal elliptical orbit
      // x-axis: full range (100%) - left-right motion
      // y-axis: small range (50%) - minimal up-down motion creates "almost horizontal" ellipse
      // z-axis: large depth range (87%) - particles go far behind/in front of brain

      final double xOrbit = radius * math.cos(angle);
      final double yOrbit = radius * math.sin(angle) * math.sin(tiltRad); // Swapped: now small (50%)
      final double zOrbit = radius * math.sin(angle) * math.cos(tiltRad); // Swapped: now large (87%)

      final double x = centerX + xOrbit;
      final double y = centerY + yOrbit;

      // Calculate opacity based on z-depth
      // Positive z = closer to viewer (front), negative z = behind
      final double zNormalized = zOrbit / radius; // -1 to 1
      // Calculate opacity: invisible when behind brain (z<0), visible when in front (z>0)
      final double opacity;
      if (zNormalized < 0) {
        opacity = 0.0; // Behind brain = invisible
      } else {
        opacity = 0.30 + (0.55 * zNormalized); // In front: 30% to 85%
      }

      // Draw comet tail (3 segments behind the particle)
      _drawCometTail(
        canvas,
        x,
        y,
        angle,
        opacity,
        particleSize,
      );

      // Draw particle
      final Paint particlePaint = Paint()
        ..color = particleColor.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      final Paint glowPaint = Paint()
        ..color = particleColor.withValues(alpha: opacity * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
        ..style = PaintingStyle.fill;

      // Draw glow
      canvas.drawCircle(Offset(x, y), particleSize * 2, glowPaint);

      // Draw particle
      canvas.drawCircle(Offset(x, y), particleSize, particlePaint);
    }
  }

  void _drawCometTail(
    Canvas canvas,
    double x,
    double y,
    double angle,
    double particleOpacity,
    double particleSize,
  ) {
    const int tailSegments = 3;
    const double segmentSpacing = 8.0;

    // Calculate tail direction (opposite of velocity)
    final double tailAngle = angle + math.pi; // Opposite direction

    for (int i = 1; i <= tailSegments; i++) {
      // Calculate position of tail segment
      final double distance = segmentSpacing * i;
      final double segmentX = x + distance * math.cos(tailAngle);
      final double segmentY = y + distance * math.sin(tailAngle);

      // Fade tail segments progressively
      // Segment 1 (closest): 70% of particle opacity
      // Segment 2: 50%
      // Segment 3: 30%
      final double segmentOpacityFactor = 0.8 - (i * 0.2);
      final double segmentOpacity = particleOpacity * segmentOpacityFactor;

      // Shrink tail segments progressively
      final double segmentSize = particleSize * (1.0 - (i * 0.15));

      final Paint tailPaint = Paint()
        ..color = particleColor.withValues(alpha: segmentOpacity)
        ..style = PaintingStyle.fill;

      final Paint tailGlowPaint = Paint()
        ..color = particleColor.withValues(alpha: segmentOpacity * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
        ..style = PaintingStyle.fill;

      // Draw tail glow
      canvas.drawCircle(Offset(segmentX, segmentY), segmentSize * 1.5, tailGlowPaint);

      // Draw tail segment
      canvas.drawCircle(Offset(segmentX, segmentY), segmentSize, tailPaint);
    }
  }

  @override
  bool shouldRepaint(_AtomicOrbitPainter oldDelegate) => true;
}
