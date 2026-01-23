import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/services/round_analysis/mistakes_analysis_service.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

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
    final MistakesAnalysisService mistakesService = locator
        .get<MistakesAnalysisService>();
    final int totalMistakes = mistakesService.getTotalMistakesCount(round);
    final List<dynamic> mistakeTypes = mistakesService.getMistakeTypes(round);

    // Filter out mistakes with count > 0
    final List<dynamic> topMistakes = mistakeTypes
        .where((mistake) => mistake.count > 0)
        .toList();

    final Widget content = _buildContent(
      context,
      totalMistakes: totalMistakes,
      topMistakes: topMistakes,
    );

    if (!showCard) {
      return content;
    }

    return Card(
      margin: EdgeInsets.zero,
      elevation: defaultCardElevation,
      shadowColor: defaultCardShadowColor,
      shape: defaultCardShape(),
      child: InkWell(
        onTap: onTap != null
            ? () {
                HapticFeedback.lightImpact();
                onTap!();
              }
            : null,
        child: Padding(padding: const EdgeInsets.all(16), child: content),
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
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$totalMistakes ',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFF7A7A),
                      ),
                    ),
                    TextSpan(
                      text: totalMistakes == 1 ? 'mistake' : 'mistakes',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.black, size: 20),
            ],
          ),
          const SizedBox(height: 16),
        ],
        // if (totalMistakes == 0)
        // Text(
        //   showHeader
        //       ? 'No mistakes detected - perfect round!'
        //       : 'Perfect round - no mistakes!',
        //   style: const TextStyle(color: Colors.grey),
        // )
        // else
        ...[
          // _buildTotalCount(context, totalMistakes),
          if (topMistakes.isNotEmpty) ...[
            // SizedBox(height: compact ? 10 : 16),
            ...addRunSpacing(
              topMistakes.asMap().entries.map((entry) {
                final int index = entry.key;
                final dynamic mistake = entry.value;
                final int maxCount = topMistakes.first.count;

                return _buildBarItem(
                  context,
                  label: mistake.label,
                  count: mistake.count,
                  maxCount: maxCount,
                  color: _getColorForIndex(index),
                );
              }).toList(),
              axis: Axis.vertical,
              runSpacing: compact ? 8 : 12,
            ),
          ],
        ],
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
