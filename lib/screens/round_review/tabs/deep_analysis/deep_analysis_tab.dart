import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/deep_analysis/components/shot_type_birdie_rates_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/deep_analysis/components/putting_summary_cards.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/deep_analysis/components/putting_distance_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/deep_analysis/components/core_stats_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/deep_analysis/components/miss_summary_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/deep_analysis/components/disc_mistakes_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/deep_analysis/components/mistake_types_card.dart';
import 'package:turbo_disc_golf/services/gpt_analysis_service.dart';
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
    final Map<LossReason, int> missSummary = statsService
        .getMissReasonSummary();
    final List<DiscMistake> discMistakes = statsService
        .getMajorMistakesByDisc();
    final List<MistakeTypeSummary> mistakeTypes = statsService
        .getMistakeTypes();

    return ListView(
      padding: const EdgeInsets.only(top: 24, bottom: 64),
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

          // Miss Summary
          if (missSummary.isNotEmpty)
            MissSummaryCard(missSummary: missSummary),

          // Disc Mistakes
          if (discMistakes.isNotEmpty)
            DiscMistakesCard(discMistakes: discMistakes),

          // Mistake Types
          if (mistakeTypes.isNotEmpty)
            MistakeTypesCard(mistakeTypes: mistakeTypes),
        ],
        runSpacing: 12,
        axis: Axis.vertical,
      ),
    );
  }
}
