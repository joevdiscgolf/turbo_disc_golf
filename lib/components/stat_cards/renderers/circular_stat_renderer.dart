import 'package:flutter/material.dart';

/// Reusable component for rendering stats as horizontal progress bars
///
/// Displays a stat with:
/// - Header row with icon, label, and count badge
/// - Horizontal progress bar with percentage
/// - Optional subtitle text
///
/// Used by all single-stat story cards in horizontal rendering mode.
class CircularStatRenderer extends StatelessWidget {
  const CircularStatRenderer({
    super.key,
    required this.percentage,
    required this.label,
    required this.color,
    required this.icon,
    required this.count,
    required this.total,
    required this.roundId,
    this.subtitle,
    this.showIcon = true,
  });

  final double percentage;
  final String label;
  final Color color;
  final IconData icon;
  final int count;
  final int total;
  final String roundId;
  final String? subtitle;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 12),
        _buildHorizontalProgressBar(context),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          _buildSubtitle(context),
        ],
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        if (showIcon) ...[
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
        ),
        Text(
          '${percentage.toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$count/$total',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalProgressBar(BuildContext context) {
    return Stack(
      children: [
        // Background bar
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        // Filled bar
        FractionallySizedBox(
          widthFactor: percentage / 100,
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    return Text(
      subtitle!,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
      textAlign: TextAlign.left,
    );
  }
}
