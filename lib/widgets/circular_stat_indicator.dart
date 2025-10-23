import 'package:flutter/material.dart';

class CircularStatIndicator extends StatelessWidget {
  final String label;
  final double percentage;
  final Color color;
  final String? internalLabel;
  final double size;
  final double strokeWidth;
  final double? percentageFontSize;
  final double? internalLabelFontSize;

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
  });

  @override
  Widget build(BuildContext context) {
    // Scale font sizes based on circle size (default size is 120)
    final double scaledPercentageFontSize = percentageFontSize ?? (size / 120) * 28;
    final double scaledInternalLabelFontSize = internalLabelFontSize ?? (size / 120) * 12;

    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: strokeWidth,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: scaledPercentageFontSize,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  if (internalLabel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      internalLabel!,
                      style: TextStyle(
                        fontSize: scaledInternalLabelFontSize,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class SmallCircularStatIndicator extends StatelessWidget {
  final String label;
  final double percentage;
  final Color color;
  final String? internalLabel;

  const SmallCircularStatIndicator({
    super.key,
    required this.label,
    required this.percentage,
    required this.color,
    this.internalLabel,
  });

  @override
  Widget build(BuildContext context) {
    return CircularStatIndicator(
      label: label,
      percentage: percentage,
      color: color,
      internalLabel: internalLabel,
      size: 60,
      strokeWidth: 7,
    );
  }
}
