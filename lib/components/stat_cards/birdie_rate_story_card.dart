import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/bar_stat_renderer.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/circular_stat_renderer.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/stat_render_mode.dart';
import 'package:turbo_disc_golf/services/round_analysis_generator.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Single-stat widget showing Birdie Rate
///
/// Displays percentage of holes with birdies in either
/// circular indicator or horizontal bar format.
/// Used by AI story to highlight scoring aggression and success.
class BirdieRateStoryCard extends StatelessWidget {
  const BirdieRateStoryCard({
    super.key,
    required this.round,
    required this.renderMode,
  });

  final DGRound round;
  final StatRenderMode renderMode;

  @override
  Widget build(BuildContext context) {
    final analysis = RoundAnalysisGenerator.generateAnalysis(round);
    final scoringStats = analysis.scoringStats;
    final double percentage = scoringStats.birdieRate;
    final int count = scoringStats.birdies;
    final int total = scoringStats.totalHoles;

    final Color color = getSemanticColor(percentage);

    if (renderMode == StatRenderMode.circle) {
      return CircularStatRenderer(
        percentage: percentage,
        label: 'Birdie Rate',
        color: color,
        icon: Icons.trending_up,
        count: count,
        total: total,
        roundId: round.id,
      );
    } else {
      return BarStatRenderer(
        percentage: percentage,
        label: 'Birdie Rate',
        color: color,
        icon: Icons.trending_up,
        count: count,
        total: total,
      );
    }
  }
}
