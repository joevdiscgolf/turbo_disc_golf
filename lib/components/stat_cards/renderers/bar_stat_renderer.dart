import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Reusable component for rendering stats as horizontal progress bars
///
/// Displays a stat with:
/// - Header row with icon, label, percentage, and count/total in brackets
/// - Horizontal progress bar (8px height)
///
/// Compact design for story cards.
/// Used by all single-stat story cards in bar rendering mode.
class BarStatRenderer extends StatelessWidget {
  const BarStatRenderer({
    super.key,
    required this.percentage,
    required this.label,
    required this.color,
    required this.icon,
    required this.count,
    required this.total,
    this.subtitle,
    this.useColorForHeading = false,
    this.showIcon = true,
    this.showContainer = true,
  });

  final double percentage;
  final String label;
  final Color color;
  final IconData icon;
  final int count;
  final int total;
  final String? subtitle;
  final bool useColorForHeading;
  final bool showIcon;

  /// Whether to show the container decoration (background, border, padding).
  /// Set to false when wrapping with BaseStoryCard.
  final bool showContainer;

  @override
  Widget build(BuildContext context) {
    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 10),
        _buildProgressBar(),
        // Subtitle (scope label) is now shown as badge in header
      ],
    );

    if (!showContainer) {
      return content;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SenseiColors.gray[100]!),
      ),
      child: content,
    );
  }

  Widget _buildHeader(BuildContext context) {
    final Color headingColor = useColorForHeading
        ? color
        : SenseiColors.gray[500]!;
    return Row(
      children: [
        if (showIcon) ...[
          Icon(icon, size: 20, color: headingColor),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Row(
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: headingColor,
                ),
              ),
              // Show scope badge if subtitle (scope label) is present
              if (subtitle != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Text(
          '${percentage.toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 20,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '($count/$total)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: SenseiColors.gray[400],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: percentage / 100,
        minHeight: 8,
        backgroundColor: color.withValues(alpha: 0.2),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

}
