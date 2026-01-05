import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/stat_render_mode.dart';
import 'package:turbo_disc_golf/services/round_analysis/mistakes_analysis_service.dart';

/// Mistakes breakdown widget showing total count and bar chart by type
///
/// Displays the complete mistakes breakdown with:
/// - Total mistakes count prominently displayed
/// - Bar chart showing each mistake type with proportional progress bars
/// - Different colors for each mistake category
///
/// Used by AI story to highlight error patterns and areas for improvement.
/// Design matches the original _MistakesCard from round_overview_body.dart.
class MistakesStoryCard extends StatelessWidget {
  const MistakesStoryCard({
    super.key,
    required this.round,
    required this.renderMode,
  });

  final DGRound round;
  final StatRenderMode renderMode;

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
    final List<dynamic> activeMistakes =
        mistakeTypes.where((mistake) => mistake.count > 0).toList();

    // If no mistakes, show perfect round message
    if (totalMistakes == 0) {
      return _buildPerfectRoundCard(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total mistakes count - prominent display
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
              totalMistakes == 1 ? 'mistake' : 'mistakes',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),

        // Bar breakdown for each mistake type
        if (activeMistakes.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...activeMistakes.asMap().entries.map((entry) {
            final int index = entry.key;
            final dynamic mistake = entry.value;
            final int maxCount = activeMistakes.first.count;

            return Padding(
              padding: EdgeInsets.only(
                bottom: index < activeMistakes.length - 1 ? 12 : 0,
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
    );
  }

  Widget _buildPerfectRoundCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Color(0xFF4CAF50),
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perfect Round!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4CAF50),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No mistakes detected',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ],
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
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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
