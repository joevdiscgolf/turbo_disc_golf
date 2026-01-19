import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';

class DiscPerformanceCard extends StatelessWidget {
  final List<DiscPerformanceSummary> discPerformances;

  const DiscPerformanceCard({super.key, required this.discPerformances});

  @override
  Widget build(BuildContext context) {
    if (discPerformances.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Disc Performance',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildLegend(context),
          const SizedBox(height: 16),
          ...discPerformances.map((disc) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () {
                  // todo: Navigate to disc detail screen
                  // This will show detailed statistics for this disc
                },
                child: _buildDiscRow(context, disc),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDiscRow(BuildContext context, DiscPerformanceSummary disc) {
    const goodColor = Color(0xFF4CAF50);
    const okayColor = Color(0xFFFFA726);
    const badColor = Color(0xFFFF7A7A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              disc.discName,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              '${disc.totalShots} throws',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Row(
            children: [
              if (disc.goodShots > 0)
                _buildProgressSegment(
                  context,
                  disc.goodShots,
                  disc.totalShots,
                  disc.goodPercentage,
                  goodColor,
                ),
              if (disc.okayShots > 0)
                _buildProgressSegment(
                  context,
                  disc.okayShots,
                  disc.totalShots,
                  disc.okayPercentage,
                  okayColor,
                ),
              if (disc.badShots > 0)
                _buildProgressSegment(
                  context,
                  disc.badShots,
                  disc.totalShots,
                  disc.badPercentage,
                  badColor,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSegment(
    BuildContext context,
    int shots,
    int totalShots,
    double percentage,
    Color color,
  ) {
    // Calculate the flex value, but ensure minimum width for visibility
    final flex = shots;

    return Expanded(
      flex: flex,
      child: Container(
        height: 32,
        constraints: percentage > 0 ? const BoxConstraints(minWidth: 50) : null,
        decoration: BoxDecoration(color: color),
        child: Center(
          child: Text(
            '${percentage.toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    const goodColor = Color(0xFF4CAF50);
    const okayColor = Color(0xFFFFA726);
    const badColor = Color(0xFFFF7A7A);

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildLegendItem(context, 'Good', goodColor),
        const SizedBox(width: 16),
        _buildLegendItem(context, 'Okay', okayColor),
        const SizedBox(width: 16),
        _buildLegendItem(context, 'Bad', badColor),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
