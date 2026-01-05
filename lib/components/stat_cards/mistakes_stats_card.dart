import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/services/round_analysis/mistakes_analysis_service.dart';

/// Compact mistakes stats card showing mistakes breakdown
///
/// Displays mistakes breakdown with:
/// - Total mistakes count
/// - Top 3 mistake types as horizontal bar charts
class MistakesStatsCard extends StatefulWidget {
  final DGRound round;
  final VoidCallback? onTap;

  const MistakesStatsCard({
    super.key,
    required this.round,
    this.onTap,
  });

  @override
  State<MistakesStatsCard> createState() => _MistakesStatsCardState();
}

class _MistakesStatsCardState extends State<MistakesStatsCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

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
    super.build(context);
    final MistakesAnalysisService mistakesService = locator
        .get<MistakesAnalysisService>();
    final int totalMistakes = mistakesService.getTotalMistakesCount(widget.round);
    final List<dynamic> mistakeTypes = mistakesService.getMistakeTypes(widget.round);

    // Filter out mistakes with count > 0 and take top 3
    final List<dynamic> topMistakes = mistakeTypes
        .where((mistake) => mistake.count > 0)
        .take(3)
        .toList();

    return InkWell(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (totalMistakes == 0)
              const Text(
                'No mistakes detected - perfect round!',
                style: TextStyle(color: Colors.grey),
              )
            else ...[
              Row(
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
              ),
              if (topMistakes.isNotEmpty) ...[
                const SizedBox(height: 16),
                ...topMistakes.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final dynamic mistake = entry.value;
                  final int maxCount = topMistakes.first.count;

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < topMistakes.length - 1 ? 12 : 0,
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
        ),
      ),
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
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$count',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            // Background bar
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            // Foreground bar (actual value)
            FractionallySizedBox(
              widthFactor: barWidth,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
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
