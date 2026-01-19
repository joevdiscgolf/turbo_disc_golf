import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/services/round_analysis/mistakes_analysis_service.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';

/// Unified Mistakes Card component with configurable sizing
///
/// Used in:
/// - Stats tab (full size with card wrapper and header)
/// - Story tab (compact size, bar chart only)
///
/// Set [compact] to true for smaller text and bar heights.
/// Set [showHeader] to false to hide the title row.
/// Set [showCard] to false to render without Card wrapper.
class MistakesCard extends StatelessWidget {
  final DGRound round;
  final VoidCallback? onTap;
  final bool compact;
  final bool showHeader;
  final bool showCard;

  const MistakesCard({
    super.key,
    required this.round,
    this.onTap,
    this.compact = false,
    this.showHeader = true,
    this.showCard = true,
  });

  Color _getColorForIndex(int index) {
    final List<Color> colors = [
      const Color(0xFFFF7A7A), // Red for top mistake
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF2196F3), // Blue
      const Color(0xFFFFA726), // Orange
      const Color(0xFF66BB6A), // Green
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final MistakesAnalysisService mistakesService =
        locator.get<MistakesAnalysisService>();
    final int totalMistakes = mistakesService.getTotalMistakesCount(round);
    final List<dynamic> mistakeTypes = mistakesService.getMistakeTypes(round);

    // Filter out mistakes with count > 0
    final List<dynamic> topMistakes =
        mistakeTypes.where((mistake) => mistake.count > 0).toList();

    final Widget content = _buildContent(
      context,
      totalMistakes: totalMistakes,
      topMistakes: topMistakes,
    );

    if (!showCard) {
      return content;
    }

    return Card(
      child: InkWell(
        onTap: onTap != null
            ? () {
                HapticFeedback.lightImpact();
                onTap!();
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: content,
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required int totalMistakes,
    required List<dynamic> topMistakes,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '⚠️ Mistakes Breakdown',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Icon(Icons.chevron_right, color: Colors.black, size: 20),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (totalMistakes == 0)
          Text(
            showHeader
                ? 'No mistakes detected - perfect round!'
                : 'Perfect round - no mistakes!',
            style: const TextStyle(color: Colors.grey),
          )
        else ...[
          _buildTotalCount(context, totalMistakes),
          if (topMistakes.isNotEmpty) ...[
            SizedBox(height: compact ? 10 : 16),
            ...topMistakes.asMap().entries.map((entry) {
              final int index = entry.key;
              final dynamic mistake = entry.value;
              final int maxCount = topMistakes.first.count;

              return Padding(
                padding: EdgeInsets.only(
                  bottom:
                      index < topMistakes.length - 1 ? (compact ? 8 : 12) : 0,
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
        ],
      ],
    );
  }

  Widget _buildTotalCount(BuildContext context, int totalMistakes) {
    if (compact) {
      // Compact style for story tab
      return Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '$totalMistakes',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFF7A7A),
                ),
          ),
          const SizedBox(width: 6),
          Text(
            totalMistakes == 1 ? 'mistake' : 'mistakes',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      );
    }

    // Full size style for stats tab
    final Widget totalDisplay = Row(
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
                color: Colors.grey,
              ),
        ),
      ],
    );

    if (locator.get<FeatureFlagService>().useHeroAnimationsForRoundReview) {
      return Hero(
        tag: 'mistakes_count',
        child: Material(color: Colors.transparent, child: totalDisplay),
      );
    }
    return totalDisplay;
  }

  Widget _buildBarItem(
    BuildContext context, {
    required String label,
    required int count,
    required int maxCount,
    required Color color,
  }) {
    final double barWidth = maxCount > 0 ? count / maxCount : 0.0;
    final double barHeight = compact ? 8.0 : 10.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: compact
                    ? Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        )
                    : Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
              ),
            ),
            Text(
              '$count',
              style: compact
                  ? Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      )
                  : Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
            ),
          ],
        ),
        SizedBox(height: compact ? 4 : 6),
        Stack(
          children: [
            // Background bar
            Container(
              height: barHeight,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
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
