import 'package:flutter/material.dart';

import 'package:turbo_disc_golf/components/percentage_distribution_bar.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/services/round_analysis/score_analysis_service.dart';
import 'package:turbo_disc_golf/utils/hole_score_colors.dart';

class ScoreDistributionBar extends StatelessWidget {
  const ScoreDistributionBar({
    super.key,
    required this.round,
    required this.height,
  });

  final DGRound round;
  final double height;

  @override
  Widget build(BuildContext context) {
    final analysis = round.analysis;

    final scoringStats =
        analysis?.scoringStats ??
        locator.get<ScoreAnalysisService>().getScoringStats(round);

    // Calculate total holes to convert counts to percentages
    final int totalHoles =
        scoringStats.birdies +
        scoringStats.pars +
        scoringStats.bogeys +
        scoringStats.doubleBogeyPlus;

    // Convert counts to percentages
    final double birdiePercentage = totalHoles > 0
        ? (scoringStats.birdies / totalHoles) * 100
        : 0;
    final double parPercentage = totalHoles > 0
        ? (scoringStats.pars / totalHoles) * 100
        : 0;
    final double bogeyPercentage = totalHoles > 0
        ? (scoringStats.bogeys / totalHoles) * 100
        : 0;
    final double doubleBogeyPlusPercentage = totalHoles > 0
        ? (scoringStats.doubleBogeyPlus / totalHoles) * 100
        : 0;

    // Create segments list with percentages and their corresponding colors
    // Using a list instead of a map to handle cases where multiple score types
    // have the same percentage (e.g., 20% bogeys and 20% double bogeys)
    final List<DistributionSegment> segments = [
      DistributionSegment(
        value: birdiePercentage,
        color: HoleScoreColors.birdie,
      ),
      DistributionSegment(
        value: parPercentage,
        color: HoleScoreColors.par,
      ),
      DistributionSegment(
        value: bogeyPercentage,
        color: HoleScoreColors.bogey,
      ),
      DistributionSegment(
        value: doubleBogeyPlusPercentage,
        color: HoleScoreColors.doubleBogeyPlus,
      ),
    ];

    return PercentageDistributionBar(
      segments: segments,
      height: height,
      borderRadius: 8,
      segmentSpacing: 2,
    );
  }
}
