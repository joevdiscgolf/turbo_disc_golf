import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/deep_analysis/components/core_stats_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/deep_analysis/components/disc_performance_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/deep_analysis/components/mistake_reason_breakdown_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/deep_analysis/components/putting_distance_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/deep_analysis/components/putting_summary_cards.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/deep_analysis/components/shot_type_birdie_rates_card.dart';
import 'package:turbo_disc_golf/services/round_statistics_service.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

/// Tab 4: Deep analysis with advanced statistics
class DeepAnalysisTab extends StatelessWidget {
  final DGRound round;

  const DeepAnalysisTab({super.key, required this.round});

  @override
  Widget build(BuildContext context) {
    final RoundStatisticsService statsService = RoundStatisticsService(round);

    final Map<String, BirdieRateStats> teeShotBirdieRateStats = statsService
        .getTeeShotBirdieRateStats();
    final Map<String, List<MapEntry<DGHole, DiscThrow>>> teeShotBirdieDetails =
        statsService.getTeeShotBirdieDetails();
    final PuttStats puttingSummary = statsService.getPuttingSummary();
    final double avgBirdiePuttDist = statsService
        .getAverageBirdiePuttDistance();
    final CoreStats coreStats = statsService.getCoreStats();
    final List<DiscPerformanceSummary> discPerformances = statsService
        .getDiscPerformanceSummaries();
    final List<MistakeTypeSummary> mistakeTypes = statsService
        .getMistakeTypes();

    return ListView(
      padding: const EdgeInsets.only(top: 24, bottom: 80),
      children: addRunSpacing(
        [
          // Tee Shot Birdie Rates
          if (teeShotBirdieRateStats.isNotEmpty)
            ShotTypeBirdieRatesCard(
              teeShotBirdieRateStats: teeShotBirdieRateStats,
              teeShotBirdieDetails: teeShotBirdieDetails,
            ),

          // Putting Summary
          if (puttingSummary.totalAttempts > 0)
            PuttingSummaryCards(puttingSummary: puttingSummary),

          // Putting Distance Stats
          if (puttingSummary.totalAttempts > 0)
            PuttingDistanceCard(
              avgMakeDistance: puttingSummary.avgMakeDistance,
              avgAttemptDistance: puttingSummary.avgAttemptDistance,
              avgBirdiePuttDistance: avgBirdiePuttDist,
              totalMadeDistance: puttingSummary.totalMadeDistance,
            ),

          // Core Stats
          CoreStatsCard(coreStats: coreStats),

          // Mistakes Breakdown
          if (mistakeTypes.isNotEmpty)
            MistakeReasonBreakdownCard(mistakeTypes: mistakeTypes),

          // Disc Performance
          if (discPerformances.isNotEmpty)
            DiscPerformanceCard(discPerformances: discPerformances),
        ],
        runSpacing: 12,
        axis: Axis.vertical,
      ),
    );
  }
}
