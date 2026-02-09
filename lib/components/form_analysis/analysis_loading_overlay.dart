import 'dart:math';

import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/components/backgrounds/animated_particle_background.dart';
import 'package:turbo_disc_golf/components/loaders/analysis_progress_bar.dart';
import 'package:turbo_disc_golf/components/loaders/atomic_nuclear_loader.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Overlay displayed during form analysis showing loader, progress bar, and status message.
///
/// Shows the current analysis step message from SSE events, defaulting to
/// "Uploading..." when no message is available yet.
class AnalysisLoadingOverlay extends StatelessWidget {
  const AnalysisLoadingOverlay({
    super.key,
    required this.isProcessing,
    required this.loaderSpeedNotifier,
    required this.brainOpacityNotifier,
    required this.progressNotifier,
    required this.progressBarOpacityNotifier,
    this.particleEmissionNotifier,
    this.statusMessage,
    this.showStatusMessage = true,
    this.showBackground = true,
  });

  /// Controls particle background animation state.
  final bool isProcessing;

  /// Whether to show the particle background. Set to false during finalization
  /// so emitted particles from AnalysisCompletionTransition can show through.
  final bool showBackground;

  /// Controls the speed of the loader animation.
  final ValueNotifier<double> loaderSpeedNotifier;

  /// Controls the opacity of the loader (for fade out during transition).
  final ValueNotifier<double> brainOpacityNotifier;

  /// Progress value from 0.0 to 1.0 for the progress bar.
  final ValueNotifier<double> progressNotifier;

  /// Controls the opacity of the progress bar.
  final ValueNotifier<double> progressBarOpacityNotifier;

  /// Controls the emission of shooting particles during finalization.
  /// Values > 0.0 trigger particle rendering.
  final ValueNotifier<double>? particleEmissionNotifier;

  /// Status message from SSE events. Defaults to "Uploading..." if null.
  final String? statusMessage;

  /// Whether to show the status message text.
  final bool showStatusMessage;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Particle background (the animated dark background)
          if (showBackground)
            AnimatedParticleBackground(isProcessing: isProcessing),
          // Shooting particles layer (renders on top of background)
          if (particleEmissionNotifier != null)
            _buildShootingParticles(),
          // Loader content centered on top
          Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ValueListenableBuilder<double>(
                valueListenable: brainOpacityNotifier,
                builder: (context, opacity, child) {
                  return Opacity(opacity: opacity, child: child);
                },
                child: AtomicNucleusLoader(
                  key: const ValueKey('persistent-analysis-loader'),
                  speedMultiplierNotifier: loaderSpeedNotifier,
                ),
              ),
              const SizedBox(height: 24),
              AnalysisProgressBar(
                progressNotifier: progressNotifier,
                opacityNotifier: progressBarOpacityNotifier,
              ),
              const SizedBox(height: 24),
              // Always render the status message to maintain layout height,
              // but fade opacity in sync with progress bar
              ValueListenableBuilder<double>(
                valueListenable: brainOpacityNotifier,
                builder: (context, brainOpacity, _) {
                  return ValueListenableBuilder<double>(
                    valueListenable: progressBarOpacityNotifier,
                    builder: (context, progressBarOpacity, _) {
                      // Fade with progress bar, or to 0 when showStatusMessage is false
                      final double effectiveOpacity = showStatusMessage
                          ? (brainOpacity * progressBarOpacity)
                          : 0.0;
                      return Opacity(
                        opacity: effectiveOpacity,
                        child: _buildStatusMessage(),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildStatusMessage() {
    final String message = statusMessage ?? 'Uploading...';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: Text(
          message,
          key: ValueKey<String>(message),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: SenseiColors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildShootingParticles() {
    return ValueListenableBuilder<double>(
      valueListenable: particleEmissionNotifier!,
      builder: (context, emissionProgress, _) {
        // Don't render if no emission yet
        if (emissionProgress <= 0) {
          return const SizedBox.shrink();
        }

        return ValueListenableBuilder<double>(
          valueListenable: brainOpacityNotifier,
          builder: (context, brainOpacity, _) {
            return ValueListenableBuilder<double>(
              valueListenable: loaderSpeedNotifier,
              builder: (context, speedMultiplier, _) {
                return Opacity(
                  opacity: brainOpacity,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _ShootingParticlesPainter(
                      emissionProgress: emissionProgress.clamp(0.0, 1.0),
                      animationProgress: emissionProgress,
                      particleColor: const Color(0xFF4DD0E1),
                      speedMultiplier: speedMultiplier,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Painter for particles shooting outward from center during finalization.
class _ShootingParticlesPainter extends CustomPainter {
  _ShootingParticlesPainter({
    required this.emissionProgress,
    required this.animationProgress,
    required this.particleColor,
    required this.speedMultiplier,
  });

  /// Clamped 0.0-1.0 to control how many particles are spawned.
  final double emissionProgress;

  /// Unclamped to control particle movement (can exceed 1.0).
  final double animationProgress;

  final Color particleColor;
  final double speedMultiplier;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);

    // Scale particle count with speed for more intensity at higher speeds
    const int baseParticles = 40;
    const int maxParticles = 150;
    final double speedFactor = ((speedMultiplier - 1.0) / 6.875).clamp(0.0, 1.0);
    final int totalParticles =
        (baseParticles + (speedFactor * (maxParticles - baseParticles))).round();

    // Use emissionProgress to control how many particles are visible
    final int particlesToShow = (emissionProgress * totalParticles).toInt();

    for (int i = 0; i < particlesToShow; i++) {
      // Each particle has a unique seed for consistent behavior
      final int seed = 42 + i;
      final Random random = Random(seed);

      // Random angle for this particle
      final double angle = random.nextDouble() * 2 * pi;

      // Particle spawn time (staggered)
      final double spawnTime = i / totalParticles;
      // Use animationProgress (unclamped) for movement calculation
      final double particleLifetime = animationProgress - spawnTime;

      if (particleLifetime <= 0) continue;

      // Distance increases over particle lifetime, scaled by speed multiplier
      const double maxDistance = 800.0;
      final double distance = maxDistance * particleLifetime * 1.5 * speedMultiplier;

      // Calculate position
      final double x = center.dx + distance * cos(angle);
      final double y = center.dy + distance * sin(angle);

      // Skip if off screen
      if (x < -50 || x > size.width + 50 || y < -50 || y > size.height + 50) {
        continue;
      }

      // Particle size decreases over lifetime
      final double particleSize = 4.0 - (particleLifetime * 2.0).clamp(0, 2);

      // Constant opacity - brain opacity controls overall fade
      const double opacity = 0.8;

      if (particleSize > 0) {
        final Paint paint = Paint()
          ..color = particleColor.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(x, y), particleSize, paint);

        // Glow effect
        final Paint glowPaint = Paint()
          ..color = particleColor.withValues(alpha: opacity * 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), particleSize + 2, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_ShootingParticlesPainter oldDelegate) {
    return oldDelegate.emissionProgress != emissionProgress ||
        oldDelegate.animationProgress != animationProgress ||
        oldDelegate.speedMultiplier != speedMultiplier;
  }
}
