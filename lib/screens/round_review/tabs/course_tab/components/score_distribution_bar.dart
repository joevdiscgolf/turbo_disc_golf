import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/percentage_distribution_bar.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/services/round_analysis/score_analysis_service.dart';

class ScoreDistributionBar extends StatelessWidget {
  const ScoreDistributionBar({super.key, required this.round});

  final DGRound round;

  @override
  Widget build(BuildContext context) {
    final analysis = round.analysis;

    final scoringStats =
        analysis?.scoringStats ??
        locator.get<ScoreAnalysisService>().getScoringStats(round);

    // Create segments list with score counts and their corresponding colors
    // Using a list instead of a map to handle cases where multiple score types
    // have the same count (e.g., 20% bogeys and 20% double bogeys)
    final List<DistributionSegment> segments = [
      DistributionSegment(
        value: scoringStats.birdies,
        color: const Color(0xFF137e66),
      ),
      DistributionSegment(
        value: scoringStats.pars,
        color: Colors.grey,
      ),
      DistributionSegment(
        value: scoringStats.bogeys,
        color: const Color(0xFFFF7A7A),
      ),
      DistributionSegment(
        value: scoringStats.doubleBogeyPlus,
        color: const Color(0xFFD32F2F),
      ),
    ];

    return PercentageDistributionBar(
      segments: segments,
      height: 40,
      borderRadius: 8,
      segmentSpacing: 2,
    );
  }
}
