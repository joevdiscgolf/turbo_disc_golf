import 'package:flutter/material.dart';

/// A horizontal progress bar for displaying analysis progress.
///
/// Accepts [ValueNotifier]s for both progress and opacity to enable
/// smooth animations controlled by the parent widget.
class AnalysisProgressBar extends StatelessWidget {
  const AnalysisProgressBar({
    super.key,
    required this.progressNotifier,
    required this.opacityNotifier,
    this.width = 200,
    this.height = 4,
  });

  /// Progress value from 0.0 to 1.0
  final ValueNotifier<double> progressNotifier;

  /// Opacity value from 0.0 to 1.0 for fade out animation
  final ValueNotifier<double> opacityNotifier;

  /// Width of the progress bar
  final double width;

  /// Height of the progress bar
  final double height;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: opacityNotifier,
      builder: (context, opacity, child) {
        return AnimatedOpacity(
          opacity: opacity,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: child,
        );
      },
      child: SizedBox(
        width: width,
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Stack(
            children: [
              // Background track
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
              // Animated fill (600ms for smooth, visible progress)
              ValueListenableBuilder<double>(
                valueListenable: progressNotifier,
                builder: (context, progress, _) {
                  return AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(height / 2),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An animated version of FractionallySizedBox that smoothly transitions
/// between different width factors.
class AnimatedFractionallySizedBox extends ImplicitlyAnimatedWidget {
  const AnimatedFractionallySizedBox({
    super.key,
    required super.duration,
    super.curve,
    this.alignment = Alignment.center,
    this.widthFactor,
    this.heightFactor,
    this.child,
  });

  final AlignmentGeometry alignment;
  final double? widthFactor;
  final double? heightFactor;
  final Widget? child;

  @override
  ImplicitlyAnimatedWidgetState<AnimatedFractionallySizedBox> createState() =>
      _AnimatedFractionallySizedBoxState();
}

class _AnimatedFractionallySizedBoxState
    extends AnimatedWidgetBaseState<AnimatedFractionallySizedBox> {
  Tween<double>? _widthFactor;
  Tween<double>? _heightFactor;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _widthFactor = visitor(
      _widthFactor,
      widget.widthFactor ?? 1.0,
      (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
    _heightFactor = visitor(
      _heightFactor,
      widget.heightFactor ?? 1.0,
      (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: widget.alignment,
      widthFactor: _widthFactor?.evaluate(animation),
      heightFactor: _heightFactor?.evaluate(animation),
      child: widget.child,
    );
  }
}
