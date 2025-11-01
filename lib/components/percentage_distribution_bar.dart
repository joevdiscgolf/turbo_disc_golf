import 'package:flutter/material.dart';

/// Represents a single segment in the distribution bar
class DistributionSegment {
  const DistributionSegment({
    required this.value,
    required this.color,
  });

  final num value;
  final Color color;
}

/// A generic distribution bar that displays segments with percentages
/// based on a list of segments.
class PercentageDistributionBar extends StatelessWidget {
  const PercentageDistributionBar({
    super.key,
    required this.segments,
    this.height = 40,
    this.borderRadius = 8,
    this.segmentSpacing = 2,
    this.minSegmentWidth = 45,
    this.fontSize = 10,
  });

  /// List of segments to display. Each segment has a value and color.
  final List<DistributionSegment> segments;

  /// Height of the distribution bar
  final double height;

  /// Border radius for the bar
  final double borderRadius;

  /// Spacing between segments
  final double segmentSpacing;

  /// Minimum width for each segment
  final double minSegmentWidth;

  /// Font size for percentage labels
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    // Calculate total of ALL segments (including those we'll filter out)
    final num totalValue = segments.fold<num>(
      0,
      (sum, segment) => sum + segment.value,
    );

    // Filter out segments with zero or very small values for display
    // Use a small threshold to handle floating point comparison issues
    final List<DistributionSegment> nonZeroSegments = segments
        .where((segment) => segment.value > 0.5)
        .toList();

    if (nonZeroSegments.isEmpty) {
      return SizedBox(height: height);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: height,
        child: Row(children: _buildSegments(nonZeroSegments, totalValue)),
      ),
    );
  }

  List<Widget> _buildSegments(
    List<DistributionSegment> nonZeroSegments,
    num totalValue,
  ) {
    final List<Widget> widgets = [];

    // Calculate the sum of segments we're actually showing
    final num shownTotal = nonZeroSegments.fold<num>(
      0,
      (sum, segment) => sum + segment.value,
    );

    // Calculate how much value is hidden (filtered out)
    final num hiddenValue = totalValue - shownTotal;

    for (int i = 0; i < nonZeroSegments.length; i++) {
      final DistributionSegment segment = nonZeroSegments[i];

      // For the last segment, add the hidden value to make the bar fill 100%
      final bool isLast = i == nonZeroSegments.length - 1;
      final num adjustedValue = isLast
          ? segment.value + hiddenValue
          : segment.value;

      widgets.add(_buildBarSegment(segment.value, adjustedValue, segment.color));

      // Add spacing between segments (but not after the last one)
      if (i < nonZeroSegments.length - 1) {
        widgets.add(SizedBox(width: segmentSpacing));
      }
    }

    return widgets;
  }

  Widget _buildBarSegment(
    num displayPercentage,
    num flexPercentage,
    Color color,
  ) {
    // displayPercentage is what we show in the label
    // flexPercentage is what we use for the flex value (may include hidden segments)
    final int percentage = displayPercentage.round();

    return Expanded(
      // Use the flexPercentage for sizing so the bar fills 100% width
      flex: flexPercentage.round(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate what label to show based on available width
          // With font size 10px, estimate: each character needs ~6-7 pixels
          // Add 4px total for horizontal padding (2px on each side)
          const double horizontalPadding = 4.0;
          final String fullLabel = '$percentage%';
          final String numberOnly = '$percentage';

          final double fullLabelWidth = fullLabel.length * 7 + 6 + horizontalPadding;
          final double numberOnlyWidth = numberOnly.length * 7 + 6 + horizontalPadding;

          // Determine which label to show (if any)
          String? label;
          if (constraints.maxWidth >= fullLabelWidth) {
            // Enough space for "20%"
            label = fullLabel;
          } else if (constraints.maxWidth >= numberOnlyWidth) {
            // Only enough space for "20"
            label = numberOnly;
          }
          // Otherwise label stays null and we show nothing

          return Container(
            constraints: BoxConstraints(minWidth: minSegmentWidth),
            color: color,
            child: Center(
              child: label != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: fontSize,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
