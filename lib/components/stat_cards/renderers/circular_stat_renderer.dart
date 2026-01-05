import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/widgets/circular_stat_indicator.dart';

/// Reusable component for rendering stats as circular indicators
///
/// Displays a stat with:
/// - Header row with icon, label, and count badge
/// - Large 88px circular indicator with animation
/// - Optional subtitle text
///
/// Used by all single-stat story cards in circle rendering mode.
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
  });

  final double percentage;
  final String label;
  final Color color;
  final IconData icon;
  final int count;
  final int total;
  final String roundId;
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          _buildCircularIndicator(),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
        ),
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

  Widget _buildCircularIndicator() {
    return CircularStatIndicator(
      percentage: percentage,
      label: '',
      color: color,
      size: 88,
      labelFontSize: 11,
      shouldAnimate: true,
      shouldGlow: true,
      shouldScale: true,
      roundId: roundId,
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
