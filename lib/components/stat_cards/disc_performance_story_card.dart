import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';
import 'package:turbo_disc_golf/services/round_analysis_generator.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Compact disc performance card for story context
/// Shows birdie rate, average score, and throw count for a specific disc
class DiscPerformanceStoryCard extends StatelessWidget {
  const DiscPerformanceStoryCard({
    super.key,
    required this.discName,
    required this.round,
  });

  final String discName;
  final DGRound round;

  @override
  Widget build(BuildContext context) {
    final RoundAnalysis analysis = RoundAnalysisGenerator.generateAnalysis(
      round,
    );

    // Get stats for this disc
    final double birdieRate = analysis.discBirdieRates[discName] ?? 0.0;
    final double avgScore = analysis.discAverageScores[discName] ?? 0.0;
    final int throwCount = analysis.discThrowCounts[discName] ?? 0;

    // Get performance summary for good/okay/bad shots
    final DiscPerformanceSummary? perfSummary = analysis.discPerformances
        .where((p) => p.discName == discName)
        .firstOrNull;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SenseiColors.gray[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.album, size: 20, color: SenseiColors.gray[500]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  discName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: SenseiColors.gray[500],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: SenseiColors.gray[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$throwCount throws',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: SenseiColors.gray[500],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatColumn(
                  label: 'Birdie Rate',
                  value: '${birdieRate.toStringAsFixed(0)}%',
                  color: const Color(0xFF137e66),
                ),
              ),
              Expanded(
                child: _StatColumn(
                  label: 'Avg Score',
                  value: _formatAvgScore(avgScore),
                  color: const Color(0xFF2196F3),
                ),
              ),
              if (perfSummary != null)
                Expanded(
                  child: _StatColumn(
                    label: 'Good Shots',
                    value: '${perfSummary.goodPercentage.toStringAsFixed(0)}%',
                    color: const Color(0xFF4CAF50),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAvgScore(double avgScore) {
    if (avgScore == 0.0) return 'N/A';
    if (avgScore > 0) return '+${avgScore.toStringAsFixed(2)}';
    return avgScore.toStringAsFixed(2);
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
