import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

/// Improved completion transition with smooth animations and proper staggering.
///
/// This widget controls the transition overlays and speed of a persistent
/// loader that lives at a higher level in the widget tree.
///
/// Timeline (5000ms total):
/// - 0-3000ms: Particles accelerate
/// - 3000-4000ms: Particles at max speed (1000ms hold)
/// - 4000-4900ms: Content fades/blurs in behind brain (900ms)
/// - 4300-5000ms: Brain fades out (700ms, starts 300ms after content)
/// - 4700-5000ms: Background transitions from dark to light (300ms)
class AnalysisCompletionTransition extends StatefulWidget {
  const AnalysisCompletionTransition({
    super.key,
    required this.speedMultiplierNotifier,
    required this.brainOpacityNotifier,
    required this.onComplete,
    required this.child,
  });

  final ValueNotifier<double> speedMultiplierNotifier;
  final ValueNotifier<double> brainOpacityNotifier;
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
  static const double speedUpEnd = 0.600; // 3000ms / 5000ms
  static const double maxSpeedEnd = 0.800; // 4000ms / 5000ms
  static const double contentFadeEnd = 0.980; // 4900ms / 5000ms
  static const double brainFadeStart = 0.860; // 4300ms / 5000ms
  static const double bgTransitionStart = 0.940; // 4700ms / 5000ms (300ms duration)

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
      duration: const Duration(milliseconds: 5000),
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

    // Update speed multiplier
    if (progress < speedUpEnd) {
      // Accelerate from 1.0 to 7.875 (5.25 × 1.5)
      final double phaseProgress = progress / speedUpEnd;
      widget.speedMultiplierNotifier.value =
          1.0 + (phaseProgress * phaseProgress * 6.875);
    } else {
      // Hold at max speed - never slow down!
      widget.speedMultiplierNotifier.value = 7.875;
    }

    // Update brain opacity (fade out smoothly starting at brainFadeStart)
    if (progress < brainFadeStart) {
      widget.brainOpacityNotifier.value = 1.0;
    } else {
      final double fadeProgress =
          (progress - brainFadeStart) / (1.0 - brainFadeStart);
      widget.brainOpacityNotifier.value =
          1.0 - Curves.easeOut.transform(fadeProgress);
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
            // Only render transition background when actually transitioning (after 4700ms)
            // Before this, FormAnalysisBackground shows through with animated particles
            if (progress >= bgTransitionStart)
              _buildBackgroundTransition(progress),

            // Emitted particles (keep moving while brain fades)
            _buildEmittedParticles(progress),

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

    // Emission progress: clamped to stop spawning at maxSpeedEnd
    final double emissionProgress =
        ((progress - 0.15) / (maxSpeedEnd - 0.15)).clamp(0.0, 1.0);

    // Animation progress: unclamped to keep particles moving
    final double animationProgress = (progress - 0.15) / (maxSpeedEnd - 0.15);

    // Get current speed multiplier for particle velocity
    final double currentSpeed = widget.speedMultiplierNotifier.value;

    return Positioned.fill(
      child: ValueListenableBuilder<double>(
        valueListenable: widget.brainOpacityNotifier,
        builder: (context, brainOpacity, child) {
          return Opacity(
            opacity: brainOpacity,
            child: child!,
          );
        },
        child: CustomPaint(
          painter: _RandomParticlesPainter(
            emissionProgress: emissionProgress,
            animationProgress: animationProgress,
            particleColor: const Color(0xFF4DD0E1),
            speedMultiplier: currentSpeed,
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
    required this.emissionProgress,
    required this.animationProgress,
    required this.particleColor,
    required this.speedMultiplier,
  });

  final double emissionProgress; // Clamped to control spawning
  final double animationProgress; // Unclamped to control movement
  final Color particleColor;
  final double speedMultiplier;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);

    // Total number of particles increases with speed for more intensity
    // Start with 40 particles at speed 1.0, scale up to 150 at max speed (7.875)
    final int baseParticles = 40;
    final int maxParticles = 150;
    final double speedFactor = (speedMultiplier - 1.0) / 6.875; // Normalize to 0.0-1.0
    final int totalParticles =
        (baseParticles + (speedFactor * (maxParticles - baseParticles))).round();
    // Use emissionProgress (clamped) to control particle count
    final int particlesToShow = (emissionProgress * totalParticles).toInt();

    for (int i = 0; i < particlesToShow; i++) {
      // Each particle has a unique seed for consistent behavior
      final int seed = 42 + i;
      final Random random = Random(seed);

      // Random angle
      final double angle = random.nextDouble() * 2 * pi;

      // Particle spawn time (staggered)
      final double spawnTime = i / totalParticles;
      // Use animationProgress (unclamped) for movement calculation
      final double particleLifetime = animationProgress - spawnTime;

      if (particleLifetime <= 0) continue;

      // Distance increases over particle lifetime, scaled by speed multiplier
      final double maxDistance = 800.0;
      final double distance = maxDistance * particleLifetime * 1.5 * speedMultiplier;

      // Calculate position
      final double x = center.dx + distance * cos(angle);
      final double y = center.dy + distance * sin(angle);

      // Skip if off screen
      if (x < -50 || x > size.width + 50 || y < -50 || y > size.height + 50) {
        continue;
      }

      // Particle size
      final double particleSize = 4.0 - (particleLifetime * 2.0).clamp(0, 2);

      // Keep particles at constant opacity - brain opacity controls overall fade
      final double opacity = 0.8;

      if (particleSize > 0) {
        final Paint paint = Paint()
          ..color = particleColor.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(x, y), particleSize, paint);

        // Glow
        final Paint glowPaint = Paint()
          ..color = particleColor.withValues(alpha: opacity * 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), particleSize + 2, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_RandomParticlesPainter oldDelegate) {
    return oldDelegate.emissionProgress != emissionProgress ||
        oldDelegate.animationProgress != animationProgress ||
        oldDelegate.speedMultiplier != speedMultiplier;
  }
}
