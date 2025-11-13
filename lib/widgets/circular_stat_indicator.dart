import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:turbo_disc_golf/services/animation_state_service.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/constants/testing_constants.dart';

class CircularStatIndicator extends StatefulWidget {
  static const Duration _scalePauseDuration = Duration(milliseconds: 300);
  static const Duration _scaleSlamDuration = Duration(milliseconds: 200);
  static const double _scaleAmount = 0.05; // 5% increase

  final String label;
  final double percentage;
  final Color color;
  final String? internalLabel;
  final double size;
  final double strokeWidth;
  final double? percentageFontSize;
  final double? internalLabelFontSize;
  final double? labelFontSize;
  final double? labelSpacing;
  final bool shouldAnimate;
  final bool shouldGlow;
  final bool shouldScale;
  final Function? onPressed;
  final String? roundId;

  const CircularStatIndicator({
    super.key,
    required this.label,
    required this.percentage,
    required this.color,
    this.internalLabel,
    this.size = 120,
    this.strokeWidth = 12,
    this.percentageFontSize,
    this.internalLabelFontSize,
    this.labelFontSize,
    this.labelSpacing,
    this.shouldAnimate = false,
    this.shouldGlow = false,
    this.shouldScale = false,
    this.onPressed,
    this.roundId,
  });

  @override
  State<CircularStatIndicator> createState() => _CircularStatIndicatorState();
}

class _CircularStatIndicatorState extends State<CircularStatIndicator>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late AnimationController _scaleAnimationController;
  late Animation<double> _scaleAnimation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    final CurvedAnimation curvedAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.fastOutSlowIn,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: widget.percentage,
    ).animate(curvedAnimation);

    // Scale animation with three phases: swell, pause, slam
    const int swellDuration = 1200;
    final int pauseDuration =
        CircularStatIndicator._scalePauseDuration.inMilliseconds;
    final int slamDuration =
        CircularStatIndicator._scaleSlamDuration.inMilliseconds;
    final int totalScaleDuration = swellDuration + pauseDuration + slamDuration;

    _scaleAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalScaleDuration),
    );

    _scaleAnimation = TweenSequence<double>([
      // Phase 1: Swell up to 1.05
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.0 + CircularStatIndicator._scaleAmount,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: swellDuration.toDouble(),
      ),
      // Phase 2: Pause at peak
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(1.0 + CircularStatIndicator._scaleAmount),
        weight: pauseDuration.toDouble(),
      ),
      // Phase 3: Slam down to 1.0
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 1.0 + CircularStatIndicator._scaleAmount,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInQuart)),
        weight: slamDuration.toDouble(),
      ),
    ]).animate(_scaleAnimationController);

    // Check if animation should play
    bool shouldPlayAnimation =
        widget.shouldAnimate && shouldAnimateProgressIndicators;

    // If roundId is provided, check animation state service
    if (shouldPlayAnimation && widget.roundId != null) {
      final String widgetKey = 'circular_${widget.label}';
      final bool hasAnimated = AnimationStateService.instance.hasAnimated(
        widget.roundId!,
        widgetKey,
      );

      if (!hasAnimated) {
        // Play animation and mark as animated
        _animationController.forward();
        if (widget.shouldScale) {
          _scaleAnimationController.forward();
        }
        AnimationStateService.instance.markAnimated(widget.roundId!, widgetKey);
      } else {
        // Skip animation, jump to end state
        _animationController.value = 1.0;
        _scaleAnimationController.value = 1.0;
      }
    } else if (shouldPlayAnimation) {
      // No roundId provided, always animate (fallback behavior)
      _animationController.forward();
      if (widget.shouldScale) {
        _scaleAnimationController.forward();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scaleAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    if (widget.onPressed != null) {
      return Bounceable(
        onTap: () {
          widget.onPressed!();
        },
        child: _mainBody(),
      );
    } else {
      return _mainBody();
    }
  }

  Widget _mainBody() {
    // Scale font sizes based on circle size (default size is 120)
    final double scaledPercentageFontSize =
        widget.percentageFontSize ?? (widget.size / 120) * 28;
    final double scaledInternalLabelFontSize =
        widget.internalLabelFontSize ?? (widget.size / 120) * 15;

    // Calculate stroke width as 10% of diameter
    final double calculatedStrokeWidth = widget.size * 0.06;

    return AnimatedBuilder(
      animation: Listenable.merge([_animation, _scaleAnimation]),
      builder: (context, child) {
        final double displayPercentage = widget.shouldAnimate
            ? _animation.value
            : widget.percentage;

        // Calculate glow intensity based on animation
        // Starts at 0, increases to peak at midpoint, then fades back to 0 at completion
        final double normalizedProgress = widget.percentage > 0
            ? (_animation.value / widget.percentage).clamp(0.0, 1.0)
            : 0.0;
        final glowIntensity = widget.shouldGlow && widget.shouldAnimate
            ? sin(normalizedProgress * pi)
            : 0.0;

        // Calculate brighter color for glow effect on the ring
        // Use Color.lerp to smoothly transition between base color and brightened color
        final Color brightenedColor = brighten(widget.color, 0.3);
        final Color ringColor = widget.shouldGlow && widget.shouldAnimate
            ? Color.lerp(widget.color, brightenedColor, glowIntensity)!
            : widget.color;

        // Get scale value from animation when scale is enabled
        final double scale = widget.shouldScale ? _scaleAnimation.value : 1.0;

        return Column(
          children: [
            Transform.scale(
              scale: scale,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Halo/aura glow effect around the ring only
                    if (widget.shouldGlow && glowIntensity > 0)
                      _RingGlow(
                        size: widget.size,
                        strokeWidth: calculatedStrokeWidth,
                        color: ringColor,
                        intensity: glowIntensity,
                        percentage: displayPercentage,
                      ),
                    SizedBox(
                      width: widget.size,
                      height: widget.size,
                      child: CircularProgressIndicator(
                        value: displayPercentage / 100,
                        strokeWidth: calculatedStrokeWidth,
                        backgroundColor: widget.color.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _CenteredPercentage(
                          percentage: displayPercentage,
                          fontSize: scaledPercentageFontSize * 1.15,
                          color: widget.color,
                        ),
                        if (widget.internalLabel != null)
                          Text(
                            widget.internalLabel!,
                            style: TextStyle(
                              fontSize: scaledInternalLabelFontSize,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (widget.label.isNotEmpty) ...[
              SizedBox(height: widget.labelSpacing ?? 12),
              Text(
                widget.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: widget.labelFontSize,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _CenteredPercentage extends StatelessWidget {
  final double percentage;
  final double fontSize;
  final Color color;

  const _CenteredPercentage({
    required this.percentage,
    required this.fontSize,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          percentage.toStringAsFixed(0),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: fontSize / 8),
          child: Text(
            '%',
            style: TextStyle(
              fontSize: fontSize * 0.4,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _RingGlow extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color color;
  final double intensity;
  final double percentage;

  const _RingGlow({
    required this.size,
    required this.strokeWidth,
    required this.color,
    required this.intensity,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _RingGlowPainter(
        strokeWidth: strokeWidth,
        color: color,
        intensity: intensity,
        percentage: percentage,
      ),
    );
  }
}

class _RingGlowPainter extends CustomPainter {
  final double strokeWidth;
  final Color color;
  final double intensity;
  final double percentage;

  _RingGlowPainter({
    required this.strokeWidth,
    required this.color,
    required this.intensity,
    required this.percentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0 || percentage <= 0) return;

    final Offset center = Offset(size.width / 2, size.height / 2);
    // Ring's center position (accounting for stroke width)
    final double radius = (size.width / 2) - (strokeWidth / 2);

    // Calculate sweep angle from percentage
    final double sweepAngle = (percentage / 100) * 2 * pi;

    // Create a single stroke for the glow that appears outside the ring
    // The glow stroke is thicker than the main progress stroke to create a halo effect
    final double glowStrokeWidth = strokeWidth * 1.8;
    final double glowBlurRadius = strokeWidth * 0.6;

    final Paint glowPaint = Paint()
      ..color = color.withValues(alpha: 0.5 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = glowStrokeWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowBlurRadius);

    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    // Draw the glow arc along the filled portion only
    canvas.drawArc(
      rect,
      -pi / 2, // Start at top (-90 degrees)
      sweepAngle,
      false, // Don't use center (for stroke style)
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingGlowPainter oldDelegate) {
    return oldDelegate.intensity != intensity ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.percentage != percentage;
  }
}
