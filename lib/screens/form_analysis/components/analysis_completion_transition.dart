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
/// - 4300-5000ms: Brain and background fade out together (700ms)
class AnalysisCompletionTransition extends StatefulWidget {
  const AnalysisCompletionTransition({
    super.key,
    required this.speedMultiplierNotifier,
    required this.brainOpacityNotifier,
    required this.particleEmissionNotifier,
    required this.onComplete,
    required this.child,
  });

  final ValueNotifier<double> speedMultiplierNotifier;
  final ValueNotifier<double> brainOpacityNotifier;
  final ValueNotifier<double> particleEmissionNotifier;
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
  static const double bgTransitionStart = 0.860; // Same as brainFadeStart (700ms duration)

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

    // Update particle emission (starts at 15% progress, can exceed 1.0 for movement)
    const double particleStartProgress = 0.15;
    if (progress < particleStartProgress) {
      widget.particleEmissionNotifier.value = 0.0;
    } else {
      // Calculate emission progress - unclamped to allow continued movement
      widget.particleEmissionNotifier.value =
          (progress - particleStartProgress) / (maxSpeedEnd - particleStartProgress);
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
            // Only render transition background when actually transitioning (after 4300ms)
            // Before this, FormAnalysisBackground shows through with animated particles
            if (progress >= bgTransitionStart)
              _buildBackgroundTransition(progress),

            // Results reveal layer (fades in behind brain)
            _buildContentLayer(progress),
          ],
        );
      },
    );
  }

  Widget _buildBackgroundTransition(double progress) {
    // Background transitions in sync with brain fade (700ms)
    final double colorProgress;
    if (progress < bgTransitionStart) {
      colorProgress = 0.0; // Stay dark
    } else {
      // Transition from bgTransitionStart to 1.0 (same timing as brain fade)
      final double transitionProgress =
          (progress - bgTransitionStart) / (1.0 - bgTransitionStart);
      colorProgress = Curves.easeOut.transform(transitionProgress);
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
