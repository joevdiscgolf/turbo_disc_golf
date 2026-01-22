import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';

class MistakesBarChartCard extends StatelessWidget {
  final int totalMistakes;
  final List<dynamic> mistakeTypes;

  const MistakesBarChartCard({
    super.key,
    required this.totalMistakes,
    required this.mistakeTypes,
  });

  Color _getColorForIndex(int index) {
    final List<Color> colors = [
      const Color(0xFFFF7A7A), // Red for top mistake
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF2196F3), // Blue
      const Color(0xFFFFA726), // Orange
      const Color(0xFF66BB6A), // Green
      const Color(0xFFEC407A), // Pink
      const Color(0xFF42A5F5), // Light blue
      const Color(0xFFAB47BC), // Deep purple
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    // Filter out mistakes with count > 0
    final List<dynamic> nonZeroMistakes = mistakeTypes
        .where((mistake) => mistake.count > 0)
        .toList();

    if (nonZeroMistakes.isEmpty) {
      return const SizedBox.shrink();
    }

    final int maxCount = nonZeroMistakes
        .map((m) => m.count as int)
        .reduce((a, b) => a > b ? a : b);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            locator.get<FeatureFlagService>().useHeroAnimationsForRoundReview
                ? Hero(
                    tag: 'mistakes_count',
                    child: Material(
                      color: Colors.transparent,
                      child: _buildHeaderRow(context),
                    ),
                  )
                : _buildHeaderRow(context),
            const SizedBox(height: 24),
            ...nonZeroMistakes.asMap().entries.map((entry) {
              final int index = entry.key;
              final dynamic mistake = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < nonZeroMistakes.length - 1 ? 16 : 0,
                ),
                child: _buildBarItem(
                  context,
                  label: mistake.label,
                  count: mistake.count,
                  maxCount: maxCount,
                  color: _getColorForIndex(index),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$totalMistakes',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFF7A7A),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'mistakes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildBarItem(
    BuildContext context, {
    required String label,
    required int count,
    required int maxCount,
    required Color color,
  }) {
    final double barWidth = maxCount > 0 ? count / maxCount : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              '$count',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            // Background bar
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            // Foreground bar (actual value)
            FractionallySizedBox(
              widthFactor: barWidth,
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: count > 0
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
