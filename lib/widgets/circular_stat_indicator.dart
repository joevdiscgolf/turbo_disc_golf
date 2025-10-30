import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/utils/testing_constants.dart';

class CircularStatIndicator extends StatefulWidget {
  final String label;
  final double percentage;
  final Color color;
  final String? internalLabel;
  final double size;
  final double strokeWidth;
  final double? percentageFontSize;
  final double? internalLabelFontSize;
  final bool shouldAnimate;

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
    this.shouldAnimate = false,
  });

  @override
  State<CircularStatIndicator> createState() => _CircularStatIndicatorState();
}

class _CircularStatIndicatorState extends State<CircularStatIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

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

    if (widget.shouldAnimate && shouldAnimateProgressIndicators) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Scale font sizes based on circle size (default size is 120)
    final double scaledPercentageFontSize =
        widget.percentageFontSize ?? (widget.size / 120) * 28;
    final double scaledInternalLabelFontSize =
        widget.internalLabelFontSize ?? (widget.size / 120) * 15;

    // Calculate stroke width as 10% of diameter
    final double calculatedStrokeWidth = widget.size * 0.06;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final double displayPercentage = widget.shouldAnimate
            ? _animation.value
            : widget.percentage;

        return Column(
          children: [
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: CircularProgressIndicator(
                      value: displayPercentage / 100,
                      strokeWidth: calculatedStrokeWidth,
                      backgroundColor: widget.color.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(widget.color),
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
            if (widget.label.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                widget.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
