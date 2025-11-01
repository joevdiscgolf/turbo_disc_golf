import 'package:flutter/material.dart';

/// A card displaying success metrics for a specific shot shape combination
/// (e.g., "Backhand Hyzer", "Forehand Anhyzer")
class ShotShapeSuccessCard extends StatelessWidget {
  const ShotShapeSuccessCard({
    super.key,
    required this.shapeName,
    required this.c1Percentage,
    required this.c1Count,
    required this.c2Percentage,
    required this.c2Count,
  });

  final String shapeName;
  final double c1Percentage;
  final int c1Count;
  final double c2Percentage;
  final int c2Count;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),
            _buildMetricRow(
              context,
              'C1 in Reg',
              c1Percentage,
              c1Count,
              const Color(0xFF2196F3), // Blue
            ),
            const SizedBox(height: 9),
            _buildMetricRow(
              context,
              'C2 in Reg',
              c2Percentage,
              c2Count,
              const Color(0xFF9575CD), // Purple
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.disc_full,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 18,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            shapeName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: (Theme.of(context).textTheme.titleLarge?.fontSize ?? 22) * 0.75,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(
    BuildContext context,
    String label,
    double percentage,
    int count,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: (Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16) * 0.75,
                  ),
            ),
            Text(
              count > 0
                  ? '${percentage.toStringAsFixed(0)}% ($count)'
                  : 'No data',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: (Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16) * 0.75,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: count > 0 ? percentage / 100 : 0,
            minHeight: 12,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
