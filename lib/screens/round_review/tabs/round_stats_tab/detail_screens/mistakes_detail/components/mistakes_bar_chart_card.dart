import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

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
      elevation: defaultCardElevation,
      shadowColor: defaultCardShadowColor,
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
            const SizedBox(height: 12),
            ...addRunSpacing(
              nonZeroMistakes.asMap().entries.map((entry) {
                final int index = entry.key;
                final dynamic mistake = entry.value;
                return _buildBarItem(
                  context,
                  label: mistake.label,
                  count: mistake.count,
                  maxCount: maxCount,
                  color: _getColorForIndex(index),
                );
              }).toList(),
              axis: Axis.vertical,
              runSpacing: 12,
            ),
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFFF7A7A),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'mistakes',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 24,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
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
    const double barHeight = 5.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF616161),
                ),
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            // Background bar
            Container(
              height: barHeight,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(barHeight / 2),
              ),
            ),
            // Foreground bar (actual value)
            FractionallySizedBox(
              widthFactor: barWidth,
              child: Container(
                height: barHeight,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(barHeight / 2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
