import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';

class ConditioningCard extends StatelessWidget {
  final MomentumStats stats;

  const ConditioningCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    // Only show card if we have section data
    if (stats.front9Performance == null && stats.last6Performance == null) {
      return const SizedBox.shrink();
    }

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
          Row(
            children: [
              const Icon(
                Icons.fitness_center,
                color: Color(0xFF4CAF50),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Conditioning & Focus',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Conditioning score gauge
          _buildConditioningScore(context),

          // Score progression throughout round
          if (stats.scoreTrend != null) ...[
            const SizedBox(height: 20),
            _buildScoreProgression(context, stats.scoreTrend!),
          ],

          // Front 9 vs Back 9 comparison
          if (stats.front9Performance != null &&
              stats.back9Performance != null) ...[
            const SizedBox(height: 20),
            _buildSectionComparison(
              context,
              stats.front9Performance!,
              stats.back9Performance!,
            ),
          ],

          // Last 6 holes analysis
          if (stats.last6Performance != null) ...[
            const SizedBox(height: 16),
            _buildLast6Analysis(context, stats.last6Performance!),
          ],
        ],
      ),
    );
  }

  Widget _buildConditioningScore(BuildContext context) {
    final score = stats.conditioningScore;
    final Color scoreColor;
    final String label;

    if (score >= 80) {
      scoreColor = const Color(0xFF4CAF50);
      label = 'Excellent';
    } else if (score >= 60) {
      scoreColor = const Color(0xFF9D4EDD);
      label = 'Good';
    } else if (score >= 40) {
      scoreColor = const Color(0xFFFFB800);
      label = 'Fair';
    } else {
      scoreColor = const Color(0xFFFF7A7A);
      label = 'Needs Work';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scoreColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conditioning Score',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scoreColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${score.toStringAsFixed(0)}/100',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreProgression(BuildContext context, ScoreTrend trend) {
    // Determine trend color and icon
    final Color trendColor;
    final IconData trendIcon;
    final String trendText;

    switch (trend.trendDirection) {
      case 'improving':
        trendColor = const Color(0xFF4CAF50);
        trendIcon = Icons.trending_up;
        trendText = 'Improving';
        break;
      case 'worsening':
        trendColor = const Color(0xFFFF7A7A);
        trendIcon = Icons.trending_down;
        trendText = 'Worsening';
        break;
      default:
        trendColor = const Color(0xFF2196F3);
        trendIcon = Icons.trending_flat;
        trendText = 'Stable';
    }

    // Find the max absolute score for scaling bars
    final maxAbsScore = trend.segments
        .map((s) => s.avgScore.abs())
        .reduce((a, b) => a > b ? a : b);
    final scaleFactor = maxAbsScore > 0 ? 1.0 / maxAbsScore : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(trendIcon, color: trendColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Score Throughout',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Bar chart
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Bars
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: trend.segments.map((segment) {
                  final isPositive = segment.avgScore >= 0;
                  final barColor = isPositive
                      ? const Color(0xFFFF7A7A)
                      : const Color(0xFF4CAF50);

                  // Height: minimum 20px, max 60px, scaled by score
                  final normalizedHeight =
                      (segment.avgScore.abs() * scaleFactor * 40).clamp(
                        4.0,
                        60.0,
                      );

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Score label above bar
                          Text(
                            segment.avgScore >= 0
                                ? '+${segment.avgScore.toStringAsFixed(1)}'
                                : segment.avgScore.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                          ),
                          const SizedBox(height: 4),
                          // Bar
                          Container(
                            height: normalizedHeight,
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Segment label below bar
                          Text(
                            segment.label,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontSize: 10,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              // Trend summary
              Row(
                children: [
                  Icon(trendIcon, color: trendColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getTrendSummaryText(trend, trendText),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getTrendSummaryText(ScoreTrend trend, String trendText) {
    final strengthAbs = trend.trendStrength.abs();

    if (trend.trendDirection == 'stable') {
      return '$trendText - Your scores stayed consistent throughout the round';
    } else if (trend.trendDirection == 'improving') {
      return '$trendText - Your scores improved by ${strengthAbs.toStringAsFixed(1)} strokes from start to finish';
    } else {
      return '$trendText - Your scores dropped by ${strengthAbs.toStringAsFixed(1)} strokes from start to finish';
    }
  }

  Widget _buildSectionComparison(
    BuildContext context,
    SectionPerformance front9,
    SectionPerformance back9,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Front 9 vs Back 9',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSectionCard(
                context,
                front9,
                const Color(0xFF2196F3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSectionCard(context, back9, const Color(0xFF9D4EDD)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionCard(
    BuildContext context,
    SectionPerformance section,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.sectionName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          _buildStatRow(
            context,
            'Avg Score',
            section.avgScore >= 0
                ? '+${section.avgScore.toStringAsFixed(1)}'
                : section.avgScore.toStringAsFixed(1),
          ),
          _buildStatRow(
            context,
            'Shot Quality',
            '${section.shotQualityRate.toStringAsFixed(0)}%',
          ),
          _buildStatRow(
            context,
            'Birdie Rate',
            '${section.birdieRate.toStringAsFixed(0)}%',
          ),
          _buildStatRow(context, 'Mistakes', section.mistakeCount.toString()),
        ],
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildLast6Analysis(BuildContext context, SectionPerformance last6) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB800).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFB800).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, color: Color(0xFFFFB800), size: 18),
              const SizedBox(width: 8),
              Text(
                'Final 6 Holes',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFFB800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickStat(
                context,
                'Avg Score',
                last6.avgScore >= 0
                    ? '+${last6.avgScore.toStringAsFixed(1)}'
                    : last6.avgScore.toStringAsFixed(1),
              ),
              _buildQuickStat(
                context,
                'Shot Quality',
                '${last6.shotQualityRate.toStringAsFixed(0)}%',
              ),
              _buildQuickStat(
                context,
                'Mistakes',
                last6.mistakeCount.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
