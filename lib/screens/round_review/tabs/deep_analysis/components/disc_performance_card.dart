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
        Row(
          children: [
            if (disc.goodShots > 0)
              Expanded(
                flex: disc.goodShots,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: goodColor,
                    borderRadius: BorderRadius.horizontal(
                      left: const Radius.circular(4),
                      right: disc.okayShots == 0 && disc.badShots == 0
                          ? const Radius.circular(4)
                          : Radius.zero,
                    ),
                  ),
                ),
              ),
            if (disc.okayShots > 0)
              Expanded(
                flex: disc.okayShots,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: okayColor,
                    borderRadius: BorderRadius.horizontal(
                      left: disc.goodShots == 0
                          ? const Radius.circular(4)
                          : Radius.zero,
                      right: disc.badShots == 0
                          ? const Radius.circular(4)
                          : Radius.zero,
                    ),
                  ),
                ),
              ),
            if (disc.badShots > 0)
              Expanded(
                flex: disc.badShots,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: badColor,
                    borderRadius: BorderRadius.horizontal(
                      left: disc.goodShots == 0 && disc.okayShots == 0
                          ? const Radius.circular(4)
                          : Radius.zero,
                      right: const Radius.circular(4),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatLabel(context, 'Good', disc.goodPercentage, goodColor),
            _buildStatLabel(context, 'Okay', disc.okayPercentage, okayColor),
            _buildStatLabel(context, 'Bad', disc.badPercentage, badColor),
          ],
        ),
      ],
    );
  }

  Widget _buildStatLabel(
    BuildContext context,
    String label,
    double percentage,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ${percentage.toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
