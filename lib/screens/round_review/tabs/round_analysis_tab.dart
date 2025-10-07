import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';
import 'package:turbo_disc_golf/services/gpt_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_statistics_service.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/components/round_review_stat_card.dart';

/// Tab 3: Detailed analysis with disc performance and technique breakdowns
class RoundAnalysisTab extends StatelessWidget {
  final DGRound round;

  const RoundAnalysisTab({super.key, required this.round});

  @override
  Widget build(BuildContext context) {
    final RoundStatisticsService statsService = RoundStatisticsService(round);

    final List<DiscInsight> topDiscs = statsService.getTopPerformingDiscs(
      limit: 5,
    );
    final approachComparison = statsService
        .compareBackhandVsForehandApproaches();
    final Map<String, TechniqueStats> teeStats = statsService.getTechniqueStats(
      ThrowPurpose.teeDrive,
    );
    final Map<String, TechniqueStats> approachStats = statsService
        .getTechniqueStats(ThrowPurpose.approach);
    final List<String> problemAreas = statsService.getProblemAreas();

    // new analysis
    final Map<String, double> teeShotBirdieRates = statsService
        .getTeeShotBirdieRates();
    final PuttStats puttingSummary = statsService.getPuttingSummary();
    final double avgBirdiePuttDist = statsService
        .getAverageBirdiePuttDistance();
    final CoreStats coreStats = statsService.getCoreStats();
    final Map<LossReason, int> missSummary = statsService
        .getMissReasonSummary();
    final List<DiscMistake> discMistakes = statsService
        .getMajorMistakesByDisc();
    final List<MistakeTypeSummary> mistakeTypes = statsService
        .getMistakeTypes();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        // Top Performing Discs
        if (topDiscs.isNotEmpty)
          RoundReviewStatCard(
            title: 'Top Performing Discs',
            icon: Icons.disc_full,
            accentColor: const Color(0xFF00F5D4),
            children: [
              ...topDiscs.map((disc) {
                Color categoryColor;
                IconData categoryIcon;

                switch (disc.category) {
                  case 'excellent':
                    categoryColor = const Color(0xFF00F5D4);
                    categoryIcon = Icons.star;
                    break;
                  case 'good':
                    categoryColor = const Color(0xFF10E5FF);
                    categoryIcon = Icons.thumb_up;
                    break;
                  default:
                    categoryColor = const Color(0xFFFF7A7A);
                    categoryIcon = Icons.trending_down;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: categoryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(categoryIcon, color: categoryColor, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                disc.discName,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Used ${disc.timesUsed} times',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${disc.birdieRate.toStringAsFixed(0)}%',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: categoryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'birdie rate',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),

        // Driving Analysis
        RoundReviewStatCard(
          title: 'Driving Breakdown',
          icon: Icons.sports_golf,
          accentColor: const Color(0xFF9D7FFF),
          children: [
            ...teeStats.entries.map((entry) {
              final stats = entry.value;
              if (stats.attempts == 0) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${stats.techniqueName.toUpperCase()} TEE SHOTS',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _StatBox(
                            label: 'Attempts',
                            value: '${stats.attempts}',
                            color: const Color(0xFF10E5FF),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatBox(
                            label: 'Birdies',
                            value: '${stats.birdies}',
                            color: const Color(0xFF00F5D4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatBox(
                            label: 'Success',
                            value: '${stats.successRate.toStringAsFixed(0)}%',
                            color: stats.successRate >= 50
                                ? const Color(0xFF00F5D4)
                                : const Color(0xFFFF7A7A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: stats.birdieRate / 100,
                      minHeight: 6,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        stats.birdieRate >= 40
                            ? const Color(0xFF00F5D4)
                            : const Color(0xFFFF7A7A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${stats.birdieRate.toStringAsFixed(0)}% birdie rate',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),

        // Approach Analysis
        RoundReviewStatCard(
          title: 'Approach Breakdown',
          icon: Icons.call_made,
          accentColor: const Color(0xFF10E5FF),
          children: [
            if (approachComparison.technique1Count > 0 ||
                approachComparison.technique2Count > 0) ...[
              ComparisonWidget(
                label1: approachComparison.technique1,
                label2: approachComparison.technique2,
                value1: approachComparison.technique1SuccessRate,
                value2: approachComparison.technique2SuccessRate,
                subtitle1: '${approachComparison.technique1Count} approaches',
                subtitle2: '${approachComparison.technique2Count} approaches',
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              ...approachStats.entries.map((entry) {
                final stats = entry.value;
                if (stats.attempts == 0) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: StatRow(
                    label: '${stats.techniqueName.capitalize()} approaches',
                    value: '${stats.successful}/${stats.attempts} successful',
                    valueColor: stats.successRate >= 50
                        ? const Color(0xFF00F5D4)
                        : const Color(0xFFFF7A7A),
                    bold: true,
                  ),
                );
              }),
            ] else ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Not enough approach shot data yet',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          ],
        ),

        // Problem Areas
        if (problemAreas.isNotEmpty)
          RoundReviewStatCard(
            title: 'Areas to Improve',
            icon: Icons.priority_high,
            accentColor: const Color(0xFFFF7A7A),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7A7A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFF7A7A).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: const Color(0xFFFF7A7A),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Focus on these skills to improve your score:',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...problemAreas.map((problem) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontSize: 16)),
                            Expanded(
                              child: Text(
                                problem,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          )
        else
          RoundReviewStatCard(
            title: 'Areas to Improve',
            icon: Icons.check_circle,
            accentColor: const Color(0xFF00F5D4),
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: const Color(0xFF00F5D4),
                        size: 64,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Great round!',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: const Color(0xFF00F5D4),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No significant weaknesses detected. Keep playing!',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
