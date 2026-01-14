import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

/// Improved completion transition with smooth animations and proper staggering.
///
/// This widget controls the transition overlays and speed of a persistent
/// loader that lives at a higher level in the widget tree.
///
/// Timeline (6800ms total):
/// - 0-4800ms: Particles accelerate
/// - 4800-5800ms: Particles at max speed (1000ms hold)
/// - 5800-6700ms: Content fades/blurs in behind brain (900ms)
/// - 6100-6800ms: Brain fades out (700ms, starts 300ms after content)
/// - 6500-6800ms: Background transitions from dark to light (300ms)
class AnalysisCompletionTransition extends StatefulWidget {
  const AnalysisCompletionTransition({
    super.key,
    required this.speedMultiplierNotifier,
    required this.onComplete,
    required this.child,
  });

  final ValueNotifier<double> speedMultiplierNotifier;
  final VoidCallback onComplete;
  final Widget child;

  @override
  State<AnalysisCompletionTransition> createState() =>
      _AnalysisCompletionTransitionState();
}

class _AnalysisCompletionTransitionState
    extends State<AnalysisCompletionTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Animation phase boundaries (normalized to 0.0-1.0)
  static const double speedUpEnd = 0.706; // 4800ms / 6800ms
  static const double maxSpeedEnd = 0.853; // 5800ms / 6800ms
  static const double contentFadeEnd = 0.985; // 6700ms / 6800ms
  static const double brainFadeStart = 0.897; // 6100ms / 6800ms
  static const double bgTransitionStart = 0.956; // 6500ms / 6800ms (300ms duration)

  // Background colors
  static const List<Color> _startGradient = [
    Color(0xFF0f3460), // Deep blue
    Color(0xFF16213e), // Midnight blue
    Color(0xFF1a535c), // Dark teal
  ];

  static const List<Color> _endGradient = [
    Color(0xFFEEE8F5),
    Color(0xFFECECEE),
    Color(0xFFE8F4E8),
    Color(0xFFEAE8F0),
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 6800),
      vsync: this,
    )..forward();

    // Update speed multiplier dynamically as animation progresses
    _controller.addListener(_updateSpeed);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
  }

  void _updateSpeed() {
    final double progress = _controller.value;

    if (progress < speedUpEnd) {
      // Accelerate from 1.0 to 3.5
      final double phaseProgress = progress / speedUpEnd;
      widget.speedMultiplierNotifier.value =
          1.0 + (phaseProgress * phaseProgress * 2.5);
    } else {
      // Hold at max speed - never slow down!
      widget.speedMultiplierNotifier.value = 3.5;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_updateSpeed);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final double progress = _controller.value;

        return Stack(
          children: [
            // Animated background color transition (only over last 300ms)
            _buildBackgroundTransition(progress),

            // Emitted particles (keep moving while brain fades)
            _buildEmittedParticles(progress),

            // Brain fade overlay (darkens the brain)
            _buildBrainFadeOverlay(progress),

            // Results reveal layer (fades in behind brain)
            _buildContentLayer(progress),
          ],
        );
      },
    );
  }

  Widget _buildBackgroundTransition(double progress) {
    // Background only transitions over last 300ms
    final double colorProgress;
    if (progress < bgTransitionStart) {
      colorProgress = 0.0; // Stay dark
    } else {
      // Transition over 300ms: from bgTransitionStart to 1.0
      final double transitionProgress =
          (progress - bgTransitionStart) / (1.0 - bgTransitionStart);
      colorProgress = Curves.easeInOut.transform(transitionProgress);
    }

    final List<Color> currentGradient = List.generate(
      4,
      (index) {
        final Color startColor = _startGradient[index.clamp(0, 2)];
        final Color endColor = _endGradient[index];
        return Color.lerp(startColor, endColor, colorProgress)!;
      },
    );

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: currentGradient,
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildEmittedParticles(double progress) {
    // Particles start emitting after 15%
    if (progress < 0.15) {
      return const SizedBox.shrink();
    }

    // Particles keep full opacity even while brain fades
    // Calculate particle emission progress (from 0.15 to maxSpeedEnd)
    final double particleProgress =
        ((progress - 0.15) / (maxSpeedEnd - 0.15)).clamp(0.0, 1.0);

    return Positioned.fill(
      child: CustomPaint(
        painter: _RandomParticlesPainter(
          progress: particleProgress,
          particleColor: const Color(0xFF4DD0E1),
        ),
      ),
    );
  }

  Widget _buildBrainFadeOverlay(double progress) {
    // Brain starts fading at brainFadeStart (6100ms)
    if (progress < brainFadeStart) {
      return const SizedBox.shrink();
    }

    final double fadeProgress =
        (progress - brainFadeStart) / (1.0 - brainFadeStart);
    final double overlayOpacity = Curves.easeOut.transform(fadeProgress);

    return Positioned.fill(
      child: Center(
        child: Container(
          width: 400,
          height: 400,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _endGradient[0].withValues(alpha: overlayOpacity),
                _endGradient[0].withValues(alpha: overlayOpacity * 0.5),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentLayer(double progress) {
    // Content fades in from maxSpeedEnd (5800ms) to contentFadeEnd (6700ms)
    if (progress < maxSpeedEnd) {
      return const SizedBox.shrink();
    }

    final double contentProgress =
        (progress - maxSpeedEnd) / (contentFadeEnd - maxSpeedEnd);
    final double revealProgress = contentProgress.clamp(0.0, 1.0);

    // Blur-to-clear effect (sigma: 20 → 0)
    final double blurAmount = 20.0 * (1.0 - revealProgress);

    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: blurAmount,
        sigmaY: blurAmount,
        tileMode: TileMode.decal,
      ),
      child: Opacity(
        opacity: revealProgress,
        child: widget.child,
      ),
    );
  }
}

/// Painter for random particles flying off one by one
class _RandomParticlesPainter extends CustomPainter {
  _RandomParticlesPainter({
    required this.progress,
    required this.particleColor,
  });

  final double progress;
  final Color particleColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);

    // Total number of particles to emit
    final int totalParticles = 60;
    final int particlesToShow = (progress * totalParticles).toInt();

    for (int i = 0; i < particlesToShow; i++) {
      // Each particle has a unique seed for consistent behavior
      final int seed = 42 + i;
      final Random random = Random(seed);

      // Random angle
      final double angle = random.nextDouble() * 2 * pi;

      // Particle spawn time (staggered)
      final double spawnTime = i / totalParticles;
      final double particleLifetime = progress - spawnTime;

      if (particleLifetime <= 0) continue;

      // Distance increases over particle lifetime
      final double maxDistance = 800.0;
      final double distance = maxDistance * particleLifetime * 1.5;

      // Calculate position
      final double x = center.dx + distance * cos(angle);
      final double y = center.dy + distance * sin(angle);

      // Skip if off screen
      if (x < -50 || x > size.width + 50 || y < -50 || y > size.height + 50) {
        continue;
      }

      // Particle size
      final double particleSize = 4.0 - (particleLifetime * 2.0).clamp(0, 2);

      // Opacity fades over time
      final double opacity = (1.0 - particleLifetime).clamp(0.0, 1.0);

      if (particleSize > 0 && opacity > 0) {
        final Paint paint = Paint()
          ..color = particleColor.withValues(alpha: opacity * 0.8)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(x, y), particleSize, paint);

        // Glow
        if (opacity > 0.3) {
          final Paint glowPaint = Paint()
            ..color = particleColor.withValues(alpha: opacity * 0.3)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(Offset(x, y), particleSize + 2, glowPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_RandomParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
