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
          // Fades with the brain so everything disappears together
          if (showBackground)
            ValueListenableBuilder<double>(
              valueListenable: brainOpacityNotifier,
              builder: (context, opacity, child) {
                return Opacity(opacity: opacity, child: child);
              },
              child: AnimatedParticleBackground(isProcessing: isProcessing),
            ),
          // Loader content centered on top (shooting particles now inside loader)
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
                  particleEmissionNotifier: particleEmissionNotifier,
                ),
              ),
              const SizedBox(height: 24),
              AnalysisProgressBar(
                progressNotifier: progressNotifier,
                opacityNotifier: progressBarOpacityNotifier,
              ),
              const SizedBox(height: 12),
              // Animated percentage label
              ValueListenableBuilder<double>(
                valueListenable: brainOpacityNotifier,
                builder: (context, brainOpacity, _) {
                  return ValueListenableBuilder<double>(
                    valueListenable: progressBarOpacityNotifier,
                    builder: (context, progressBarOpacity, _) {
                      return ValueListenableBuilder<double>(
                        valueListenable: progressNotifier,
                        builder: (context, progress, _) {
                          final double effectiveOpacity = showStatusMessage
                              ? (brainOpacity * progressBarOpacity)
                              : 0.0;
                          return Opacity(
                            opacity: effectiveOpacity,
                            child: _AnimatedPercentageLabel(progress: progress),
                          );
                        },
                      );
                    },
                  );
                },
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
}

/// Animated percentage label that smoothly transitions between values.
/// Matches the 600ms easeInOut animation of the progress bar.
class _AnimatedPercentageLabel extends ImplicitlyAnimatedWidget {
  const _AnimatedPercentageLabel({
    required this.progress,
  }) : super(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );

  /// Progress value from 0.0 to 1.0
  final double progress;

  @override
  ImplicitlyAnimatedWidgetState<_AnimatedPercentageLabel> createState() =>
      _AnimatedPercentageLabelState();
}

class _AnimatedPercentageLabelState
    extends AnimatedWidgetBaseState<_AnimatedPercentageLabel> {
  Tween<double>? _progressTween;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _progressTween = visitor(
      _progressTween,
      widget.progress,
      (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    final double animatedProgress = _progressTween?.evaluate(animation) ?? 0.0;
    final int percentage = (animatedProgress * 100).round().clamp(0, 100);

    return Text(
      '$percentage%',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.7),
        letterSpacing: 0.5,
      ),
    );
  }
}
