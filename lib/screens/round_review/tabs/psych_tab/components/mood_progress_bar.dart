import 'package:flutter/material.dart';

/// A 10-segment progress bar used for mood ring visualization
class MoodProgressBar extends StatelessWidget {
  final double percentage;
  final List<Color> gradientColors;

  const MoodProgressBar({
    super.key,
    required this.percentage,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    // Clamp percentage between 0 and 100
    final double clampedPercentage = percentage.clamp(0.0, 100.0);

    // Calculate how many segments to fill (out of 10)
    final int filledSegments = (clampedPercentage / 10).round();

    return Row(
      children: List.generate(10, (index) {
        final bool isFilled = index < filledSegments;

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: isFilled
                  ? LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isFilled
                  ? null
                  : Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.3),
            ),
          ),
        );
      }),
    );
  }
}
