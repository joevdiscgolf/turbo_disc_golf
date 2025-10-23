import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/services/round_analysis/putting_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_analysis/score_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_statistics_service.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/components/round_review_stat_card.dart';

/// Tab 2: Performance Overview with key statistics
class RoundStatsTab extends StatelessWidget {
  final DGRound round;

  const RoundStatsTab({super.key, required this.round});

  @override
  Widget build(BuildContext context) {
    final statsService = RoundStatisticsService(round);
    final scoringStats = locator.get<ScoreAnalysisService>().getScoringStats(
      round,
    );
    final puttingStats = locator
        .get<PuttingAnalysisService>()
        .getPuttingStatsByDistance(round);
    final teeComparison = statsService.compareBackhandVsForehandTeeShots();
    final scrambleStats = statsService.getScrambleStats();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        // Scoring Summary Card
        RoundReviewStatCard(
          title: 'Scoring Summary',
          icon: Icons.emoji_events,
          accentColor: Theme.of(context).colorScheme.primary,
          children: [
            PercentageBar(
              label: 'Birdies',
              percentage: scoringStats.birdieRate,
              color: const Color(0xFF137e66),
              subtitle:
                  '${scoringStats.birdies} of ${scoringStats.totalHoles} holes',
            ),
            PercentageBar(
              label: 'Pars',
              percentage: scoringStats.parRate,
              color: const Color(0xFFF5F5F5),
              subtitle:
                  '${scoringStats.pars} of ${scoringStats.totalHoles} holes',
            ),
            PercentageBar(
              label: 'Bogeys',
              percentage: scoringStats.bogeyRate,
              color: const Color(0xFFFF7A7A),
              subtitle:
                  '${scoringStats.bogeys} of ${scoringStats.totalHoles} holes',
            ),
            if (scoringStats.doubleBogeyPlus > 0)
              PercentageBar(
                label: 'Double Bogey+',
                percentage: scoringStats.doubleBogeyPlusRate,
                color: const Color(0xFFFF4444),
                subtitle:
                    '${scoringStats.doubleBogeyPlus} of ${scoringStats.totalHoles} holes',
              ),
          ],
        ),

        // Tee Shot Performance
        RoundReviewStatCard(
          title: 'Tee Shot Performance',
          icon: Icons.sports_golf,
          accentColor: Theme.of(context).colorScheme.secondary,
          children: [
            if (teeComparison.technique1Count > 0 ||
                teeComparison.technique2Count > 0) ...[
              ComparisonWidget(
                label1: teeComparison.technique1,
                label2: teeComparison.technique2,
                value1: teeComparison.technique1BirdieRate,
                value2: teeComparison.technique2BirdieRate,
                subtitle1: '${teeComparison.technique1Count} drives',
                subtitle2: '${teeComparison.technique2Count} drives',
              ),
              const SizedBox(height: 8),
              Text(
                _getTeeShotInsight(teeComparison),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ] else ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Not enough tee shot data yet',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          ],
        ),

        // Putting Performance
        RoundReviewStatCard(
          title: 'Putting Performance',
          icon: Icons.flag,
          accentColor: const Color(0xFF9D7FFF),
          children: [
            ...puttingStats.entries.map((entry) {
              final stats = entry.value;
              if (stats.attempted == 0) {
                return const SizedBox.shrink();
              }

              Color color;
              if (entry.key.contains('0-15')) {
                color = stats.makePercentage >= 90
                    ? const Color(0xFF137e66)
                    : const Color(0xFFFF7A7A);
              } else if (entry.key.contains('15-33')) {
                color = stats.makePercentage >= 60
                    ? const Color(0xFF137e66)
                    : const Color(0xFFFF7A7A);
              } else {
                color = stats.makePercentage >= 30
                    ? const Color(0xFF137e66)
                    : const Color(0xFFFF7A7A);
              }

              return PercentageBar(
                label: stats.distanceRange,
                percentage: stats.makePercentage,
                color: color,
                subtitle: '${stats.made} of ${stats.attempted} made',
              );
            }),
            if (puttingStats.values.every((s) => s.attempted == 0))
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No putting data available',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
          ],
        ),

        // Fairway & Scramble Performance
        RoundReviewStatCard(
          title: 'Course Management',
          icon: Icons.terrain,
          accentColor: const Color(0xFF10E5FF),
          children: [
            if (scrambleStats.scrambleOpportunities > 0) ...[
              MetricTile(
                icon: Icons.refresh,
                label: 'Scramble Success',
                value: '${scrambleStats.scrambleRate.toStringAsFixed(0)}%',
                iconColor: scrambleStats.scrambleRate >= 50
                    ? const Color(0xFF137e66)
                    : const Color(0xFFFF7A7A),
                valueColor: scrambleStats.scrambleRate >= 50
                    ? const Color(0xFF137e66)
                    : const Color(0xFFFF7A7A),
              ),
              const SizedBox(height: 8),
              StatRow(
                label: 'Scramble opportunities',
                value: '${scrambleStats.scrambleOpportunities}',
              ),
              StatRow(
                label: 'Par saves',
                value: '${scrambleStats.scrambleSaves}',
                valueColor: const Color(0xFF137e66),
                bold: true,
              ),
            ] else ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: const Color(0xFF137e66),
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Clean round - no scrambles needed!',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF137e66),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  String _getTeeShotInsight(result) {
    if (result.technique1Count == 0 && result.technique2Count == 0) {
      return 'No tee shot data available yet.';
    }

    if (result.technique1Count == 0) {
      return 'Try mixing in some ${result.technique1.toLowerCase()} tee shots!';
    }

    if (result.technique2Count == 0) {
      return 'Try mixing in some ${result.technique2.toLowerCase()} tee shots!';
    }

    final winner = result.winner;
    if (winner == 'tie') {
      return 'Both techniques are performing equally well!';
    }

    final diff = result.difference;
    if (diff < 5) {
      return 'Both techniques are performing similarly.';
    } else if (diff < 15) {
      return '$winner is performing slightly better for birdie opportunities.';
    } else {
      return '$winner is significantly more effective for birdie opportunities!';
    }
  }
}
