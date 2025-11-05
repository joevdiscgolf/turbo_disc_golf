import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

/// Explosive climax animation shown at the end of processing.
///
/// Features intensifying animations that build to a dramatic reveal:
/// - Disc icon spinning and pulsing faster with acceleration
/// - Radial energy bursts that speed up
/// - Color flashes that intensify
/// - Progressive acceleration that builds to climax
/// - Optional zooming effect into the center disc icon
class ExplosionEffect extends StatefulWidget {
  const ExplosionEffect({
    super.key,
    this.isZooming = false,
    this.hideSquare = false,
  });

  final bool isZooming;
  final bool
  hideSquare; // Allow hiding the triangle when using persistent overlay

  @override
  State<ExplosionEffect> createState() => _ExplosionEffectState();
}

class _ExplosionEffectState extends State<ExplosionEffect>
    with SingleTickerProviderStateMixin {
  // Control flag for energy wave explosions
  static const bool enableEnergyWaves = true;

  late AnimationController _controller;
  late Animation<double> _accelerationCurve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.isZooming
          ? const Duration(
              milliseconds: 3000,
            ) // Extended hyperspace to 3 seconds
          : const Duration(milliseconds: 3000), // Extended to 3 seconds
      vsync: this,
    );

    // Create custom acceleration curve - accelerates over first 2 seconds (80% of duration)
    // then holds at max speed for final 0.5s explosion
    _accelerationCurve = CurvedAnimation(
      parent: _controller,
      curve: widget.isZooming
          ? Curves
                .easeInQuart // Stronger acceleration: starts slow, ends very fast for hyperspace
          : const Interval(
              0.0,
              0.8, // Accelerate over first 80% (2 seconds)
              curve: Curves.easeInExpo,
            ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _accelerationCurve,
      builder: (context, child) {
        final double progress = _accelerationCurve.value;

        // Calculate accelerating speeds - reduced to 25% of previous max speed
        final double burstSpeed =
            1.0 - (progress * 0.225); // Gets faster (smaller duration)
        final double rotationSpeed =
            1.0 - (progress * 0.1875); // Spinning accelerates
        final double pulseSpeed =
            1.0 - (progress * 0.15); // Pulsing accelerates
        final double intensity = progress; // Intensity increases linearly

        // Zoom scale when in zooming mode
        final double zoomScale = widget.isZooming
            ? 1.0 + (progress * 4.0)
            : 1.0;

        return Transform.scale(
          scale: zoomScale,
          child: Stack(
            children: [
              // Background - consistent light color to match rest of screen
              Positioned.fill(
                child: Container(
                  color: const Color(
                    0xFFEEE8F5,
                  ), // Light purple-gray (consistent)
                ),
              ),
              // Hyperspace particles during zoom
              if (widget.isZooming)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _HyperspaceParticlesPainter(
                      progress: _controller.value,
                    ),
                  ),
                ),
              // Accelerating radial gradient bursts - primary
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final double burstProgress =
                        (_controller.value / burstSpeed) % 1.0;
                    return Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.5 + (burstProgress * 1.0),
                          colors: [
                            Color(0xFFB8E986).withValues(
                              alpha: (0.6 * intensity * (1 - burstProgress)),
                            ),
                            Color(0xFF5B7EFF).withValues(
                              alpha: (0.5 * intensity * (1 - burstProgress)),
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Secondary burst with offset timing
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final double burstProgress =
                        ((_controller.value + 0.5) / burstSpeed) % 1.0;
                    return Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.6 + (burstProgress * 1.2),
                          colors: [
                            Color(0xFF5B7EFF).withValues(
                              alpha: (0.5 * intensity * (1 - burstProgress)),
                            ),
                            Color(0xFFB8E986).withValues(
                              alpha: (0.4 * intensity * (1 - burstProgress)),
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Three sequential blue particle bursts
              // Much lighter than energy waves - better performance
              if (enableEnergyWaves && !widget.isZooming) ...[
                // Burst 1 - Blue (6.7% / 200ms after explosion starts)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ParticleBurstPainter(
                      globalProgress: _controller.value,
                      burstStartProgress: 0.067,
                      particleColor: const Color(0xFF5B7EFF),
                      intensity: intensity,
                    ),
                  ),
                ),
                // Burst 2 - Blue (40% / ~1200ms)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ParticleBurstPainter(
                      globalProgress: _controller.value,
                      burstStartProgress: 0.40,
                      particleColor: const Color(0xFF5B7EFF),
                      intensity: intensity,
                    ),
                  ),
                ),
                // Burst 3 - Blue (73% / ~2200ms)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ParticleBurstPainter(
                      globalProgress: _controller.value,
                      burstStartProgress: 0.73,
                      particleColor: const Color(0xFF5B7EFF),
                      intensity: intensity,
                    ),
                  ),
                ),
              ],

              // Center content with accelerating animations
              if (!widget.hideSquare)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // White triangle - spinning faster and faster with increasing pulse
                      // During zooming/hyperspace: 8x zoom out with blur and fade
                      Transform.scale(
                        // Only zoom 8x during hyperspace phase
                        scale: widget.isZooming
                            ? (1.0 + (progress * 7.0))
                            : 1.0,
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(
                            // Only blur during hyperspace
                            sigmaX: widget.isZooming ? 20.0 * progress : 0.0,
                            sigmaY: widget.isZooming ? 20.0 * progress : 0.0,
                            tileMode: TileMode.decal,
                          ),
                          child: Opacity(
                            // Only fade during hyperspace
                            opacity: widget.isZooming
                                ? (1.0 - progress).clamp(0.0, 1.0)
                                : 1.0,
                            child: Transform.rotate(
                              angle:
                                  (_controller.value / rotationSpeed) * 4 * pi,
                              child: Transform.scale(
                                scale:
                                    1.0 +
                                    (sin(
                                          (_controller.value / pulseSpeed) *
                                              2 *
                                              pi *
                                              6,
                                        ) *
                                        0.2 *
                                        intensity),
                                child: const _WhiteTriangle(size: 140),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// /// Painter for sequential particle wave explosions
// class _ParticleWavePainter extends CustomPainter {
//   _ParticleWavePainter({
//     required this.globalProgress,
//     required this.waveStartProgress,
//     this.angleOffset = 0.0,
//     this.intensity = 1.0,
//   });

//   final double globalProgress;
//   final double waveStartProgress;
//   final double angleOffset;
//   final double intensity;

//   @override
//   void paint(Canvas canvas, Size size) {
//     // Only draw if wave has started
//     if (globalProgress < waveStartProgress) return;

//     final Offset center = Offset(size.width / 2, size.height / 2);

//     // Calculate progress within this wave (0.0 to 1.0)
//     final double waveProgress = ((globalProgress - waveStartProgress) / (1.0 - waveStartProgress))
//         .clamp(0.0, 1.0);

//     // Apply "thick fluid" effect: start fast, slow down quickly
//     // Use exponential decay curve for fluid resistance
//     final double fluidProgress = 1.0 - pow(1.0 - waveProgress, 0.4);

//     // Draw radiating particles - increased count for more dramatic effect
//     const int particleCount = 48; // Doubled from 24
//     for (int i = 0; i < particleCount; i++) {
//       final double angle = (i / particleCount) * 2 * pi + angleOffset;
//       final double distance = fluidProgress * 250; // Explode outward with fluid motion
//       final double x = center.dx + distance * cos(angle);
//       final double y = center.dy + distance * sin(angle);

//       // Particle size shrinks slightly as it travels
//       final double particleSize = (12 * (1 - waveProgress * 0.3)).clamp(0.0, 12.0);

//       // Delayed fade: stay at full opacity until 70% of wave, then fade quickly
//       final double fadeStart = 0.7;
//       final double opacity = waveProgress < fadeStart
//           ? 1.0
//           : 1.0 - ((waveProgress - fadeStart) / (1.0 - fadeStart));

//       if (particleSize > 0 && opacity > 0) {
//         // Alternate colors
//         final Paint paint = Paint()
//           ..style = PaintingStyle.fill
//           ..color = (i % 2 == 0 ? const Color(0xFFB8E986) : const Color(0xFF5B7EFF))
//               .withValues(alpha: opacity * 0.9);
//         canvas.drawCircle(Offset(x, y), particleSize, paint);
//       }
//     }
//   }

//   @override
//   bool shouldRepaint(_ParticleWavePainter oldDelegate) {
//     return oldDelegate.globalProgress != globalProgress ||
//         oldDelegate.intensity != intensity;
//   }
// }

// /// Painter for color wave rings that expand outward
// class _ColorWavePainter extends CustomPainter {
//   _ColorWavePainter({
//     required this.globalProgress,
//     required this.waveStartProgress,
//     required this.waveColor,
//     this.intensity = 1.0,
//   });

//   final double globalProgress;
//   final double waveStartProgress;
//   final Color waveColor;
//   final double intensity;

//   @override
//   void paint(Canvas canvas, Size size) {
//     // Only draw if wave has started
//     if (globalProgress < waveStartProgress) return;

//     final Offset center = Offset(size.width / 2, size.height / 2);

//     // Calculate progress within this wave (0.0 to 1.0+)
//     // Allow wave to continue past 1.0 to ensure smooth fade-out
//     final double waveProgress =
//         (globalProgress - waveStartProgress) / (1.0 - waveStartProgress);

//     // Apply "thick fluid" effect: start fast, slow down quickly
//     final double fluidProgress = 1.0 - pow(1.0 - waveProgress.clamp(0.0, 1.0), 0.4);

//     // Expanding radius
//     final double maxRadius = 300.0;
//     final double currentRadius = fluidProgress * maxRadius;

//     // Ring thickness (starts thick, gets thinner as it expands) - increased from 40.0 to 60.0
//     final double ringThickness = 60.0 * (1.0 - waveProgress.clamp(0.0, 1.0) * 0.7);

//     // Smoother fade: start fading at 50% of wave, gentle fade until end
//     // Continue fading even past wave completion to prevent abrupt disappearance
//     final double fadeStart = 0.5;
//     double opacity;
//     if (waveProgress < fadeStart) {
//       opacity = 1.0;
//     } else {
//       // Gentle exponential fade from 50% onwards
//       final double fadeProgress = (waveProgress - fadeStart) / (1.5 - fadeStart);
//       opacity = pow(1.0 - fadeProgress.clamp(0.0, 1.0), 1.5).toDouble();
//     }

//     if (opacity > 0.01 && currentRadius > 0) {
//       // Draw multiple concentric rings to create distinct wave crest
//       // Main wave ring (brightest, thickest)
//       final Paint mainPaint = Paint()
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = ringThickness
//         ..maskFilter =
//             const MaskFilter.blur(
//               BlurStyle.normal,
//               15.0,
//             ) // Strong blur for gradient effect
//         ..shader = RadialGradient(
//           colors: [
//             waveColor.withValues(alpha: opacity * 0.7),
//             waveColor.withValues(alpha: opacity * 0.4),
//             waveColor.withValues(alpha: 0.0),
//           ],
//           stops: const [0.0, 0.6, 1.0],
//         ).createShader(Rect.fromCircle(center: center, radius: currentRadius));

//       canvas.drawCircle(center, currentRadius, mainPaint);

//       // Leading edge (brighter, thinner ring slightly ahead)
//       if (currentRadius > 10) {
//         final double leadRadius = currentRadius + ringThickness * 0.3;
//         final Paint leadPaint = Paint()
//           ..style = PaintingStyle.stroke
//           ..strokeWidth = ringThickness * 0.4
//           ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0)
//           ..color = waveColor.withValues(alpha: opacity * 0.9);

//         canvas.drawCircle(center, leadRadius, leadPaint);
//       }

//       // Trailing edge (dimmer, thinner ring slightly behind)
//       if (currentRadius > 15) {
//         final double trailRadius = currentRadius - ringThickness * 0.3;
//         final Paint trailPaint = Paint()
//           ..style = PaintingStyle.stroke
//           ..strokeWidth = ringThickness * 0.3
//           ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0)
//           ..color = waveColor.withValues(alpha: opacity * 0.3);

//         canvas.drawCircle(center, trailRadius, trailPaint);
//       }
//     }
//   }

//   @override
//   bool shouldRepaint(_ColorWavePainter oldDelegate) {
//     return oldDelegate.globalProgress != globalProgress ||
//         oldDelegate.intensity != intensity;
//   }
// }

/// Painter for particle bursts that shoot outward
/// Much more performant than color waves - no heavy blur effects
class _ParticleBurstPainter extends CustomPainter {
  _ParticleBurstPainter({
    required this.globalProgress,
    required this.burstStartProgress,
    required this.particleColor,
    this.intensity = 1.0,
  });

  final double globalProgress;
  final double burstStartProgress;
  final Color particleColor;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    // Only draw if burst has started
    if (globalProgress < burstStartProgress) return;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final Random random = Random(
      burstStartProgress.hashCode,
    ); // Fixed seed per burst

    // Calculate progress within this burst (0.0 to 1.0)
    final double burstProgress =
        ((globalProgress - burstStartProgress) / (1.0 - burstStartProgress))
            .clamp(0.0, 1.0);

    // Fade out in last 30% of burst
    final double fadeStart = 0.7;
    final double opacity = burstProgress < fadeStart
        ? 1.0
        : 1.0 - ((burstProgress - fadeStart) / (1.0 - fadeStart));

    if (opacity < 0.01) return;

    // Draw 60 particles radiating outward
    const int particleCount = 60;
    for (int i = 0; i < particleCount; i++) {
      // Calculate angle for this particle
      final double angle = (i / particleCount) * 2 * pi;

      // Vary speed per particle for organic feel (randomized around 3x faster)
      final double speedVariation =
          0.8 + (random.nextDouble() * 0.4); // 0.8 to 1.2

      // Distance from center - much faster with linear easing for instant burst
      final double maxDistance = 1200.0; // 3x faster (was 400.0)
      // Use linear easing (just burstProgress) for instant fast explosion
      // No "thick fluid" effect - particles shoot out at constant speed
      final double distance = maxDistance * burstProgress * speedVariation;

      // Calculate position
      final double x = center.dx + distance * cos(angle);
      final double y = center.dy + distance * sin(angle);

      // Skip if off screen
      if (x < -20 || x > size.width + 20 || y < -20 || y > size.height + 20) {
        continue;
      }

      // Particle size: starts at 4, shrinks to 2
      final double particleSize = 4.0 - (burstProgress * 2.0);

      // Draw particle as simple circle (no blur - much faster!)
      final Paint paint = Paint()
        ..color = particleColor.withValues(alpha: opacity * 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particleSize, paint);

      // Optional: Add slight glow with one small circle
      if (particleSize > 2.5) {
        final Paint glowPaint = Paint()
          ..color = particleColor.withValues(alpha: opacity * 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), particleSize + 2, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_ParticleBurstPainter oldDelegate) {
    return oldDelegate.globalProgress != globalProgress ||
        oldDelegate.intensity != intensity;
  }
}

/// White triangle widget for center spinner
class _WhiteTriangle extends StatelessWidget {
  final double size;

  const _WhiteTriangle({this.size = 140});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF5B7EFF).withValues(alpha: 0.8), // Solid blue
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B7EFF).withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: 10,
          ),
          BoxShadow(
            color: const Color(0xFF5B7EFF).withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: CustomPaint(painter: _TrianglePainter()),
    );
  }
}

/// Painter for white triangle outline
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
    final double triangleSize = size.width * 0.35;

    // Create equilateral triangle pointing up
    final Path path = Path();
    path.moveTo(centerX, centerY - triangleSize / 2); // Top point
    path.lineTo(
      centerX - triangleSize / 2,
      centerY + triangleSize / 3,
    ); // Bottom left
    path.lineTo(
      centerX + triangleSize / 2,
      centerY + triangleSize / 3,
    ); // Bottom right
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter oldDelegate) => false;
}

/// Painter for hyperspace particles (Star Wars light speed effect)
class _HyperspaceParticlesPainter extends CustomPainter {
  _HyperspaceParticlesPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Random random = Random(42); // Fixed seed for consistency

    // Generate 150 particles
    for (int i = 0; i < 150; i++) {
      // Calculate particle properties based on index
      final double angle = random.nextDouble() * 2 * pi;
      final double speed = 0.5 + random.nextDouble() * 1.5; // Varying speeds
      // Spread particle spawning throughout the entire animation
      // This ensures particles continue appearing from center until fade-out
      final double startOffset =
          random.nextDouble() * 0.9; // Stagger start times from 0% to 90%

      // Calculate particle progress (0.0 to 1.0+)
      final double particleProgress = ((progress - startOffset) * speed).clamp(
        0.0,
        1.5,
      );

      if (particleProgress <= 0) continue;

      // Quadratic slow-to-fast acceleration - even faster distance
      // Use quadratic easing (power of 2) for gradual acceleration
      final double acceleration = pow(particleProgress, 2.0).toDouble();
      final double distance =
          acceleration * 1800; // 3x faster (was 600, then 1200)

      // Calculate position
      final double x = center.dx + distance * cos(angle);
      final double y = center.dy + distance * sin(angle);

      // Skip if off screen
      if (x < 0 || x > size.width || y < 0 || y > size.height) continue;

      // Particle size increases as it moves (starts small, gets bigger)
      final double particleSize = 1.5 + (particleProgress * 3.0);

      // Opacity fades in quickly then stays bright
      double opacity = (particleProgress * 4.0).clamp(0.0, 1.0);

      // Apply global fade-out in the last 30% of the animation
      // This keeps particles appearing but fades them all out smoothly
      if (progress > 0.7) {
        final double fadeOutProgress = (progress - 0.7) / 0.3; // 0.0 to 1.0
        opacity *= (1.0 - fadeOutProgress); // Multiply to reduce opacity
      }

      // Streak length based on speed (motion blur effect)
      final double streakLength = particleProgress * 30 * speed;

      // Draw particle as a streak
      final Paint paint = Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..strokeWidth = particleSize
        ..strokeCap = StrokeCap.round;

      // Calculate streak start position (closer to center)
      final double streakStartX = x - (streakLength * cos(angle));
      final double streakStartY = y - (streakLength * sin(angle));

      canvas.drawLine(Offset(streakStartX, streakStartY), Offset(x, y), paint);
    }
  }

  @override
  bool shouldRepaint(_HyperspaceParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
