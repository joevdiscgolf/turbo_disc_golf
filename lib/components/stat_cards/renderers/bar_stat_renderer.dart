import 'package:flutter/material.dart';

/// Reusable component for rendering stats as horizontal progress bars
///
/// Displays a stat with:
/// - Header row with icon, label, and large percentage value
/// - Horizontal progress bar (8px height)
/// - Context row showing count/total
///
/// More compact than CircularStatRenderer, saves vertical space.
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
  });

  final double percentage;
  final String label;
  final Color color;
  final IconData icon;
  final int count;
  final int total;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 12),
          _buildProgressBar(),
          const SizedBox(height: 8),
          _buildContext(context),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            _buildSubtitle(context),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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

  Widget _buildContext(BuildContext context) {
    return Center(
      child: Text(
        '$count / $total',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    return Text(
      subtitle!,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
      textAlign: TextAlign.center,
    );
  }
}
