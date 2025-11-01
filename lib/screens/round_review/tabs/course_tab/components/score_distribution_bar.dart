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

    // Calculate total holes to convert counts to percentages
    final int totalHoles = scoringStats.birdies +
        scoringStats.pars +
        scoringStats.bogeys +
        scoringStats.doubleBogeyPlus;

    // Convert counts to percentages
    final double birdiePercentage = totalHoles > 0 ? (scoringStats.birdies / totalHoles) * 100 : 0;
    final double parPercentage = totalHoles > 0 ? (scoringStats.pars / totalHoles) * 100 : 0;
    final double bogeyPercentage = totalHoles > 0 ? (scoringStats.bogeys / totalHoles) * 100 : 0;
    final double doubleBogeyPlusPercentage = totalHoles > 0 ? (scoringStats.doubleBogeyPlus / totalHoles) * 100 : 0;

    // Create segments list with percentages and their corresponding colors
    // Using a list instead of a map to handle cases where multiple score types
    // have the same percentage (e.g., 20% bogeys and 20% double bogeys)
    final List<DistributionSegment> segments = [
      DistributionSegment(
        value: birdiePercentage,
        color: const Color(0xFF137e66),
      ),
      DistributionSegment(
        value: parPercentage,
        color: Colors.grey,
      ),
      DistributionSegment(
        value: bogeyPercentage,
        color: const Color(0xFFFF7A7A),
      ),
      DistributionSegment(
        value: doubleBogeyPlusPercentage,
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
