import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/bar_stat_renderer.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/circular_stat_renderer.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/stat_render_mode.dart';
import 'package:turbo_disc_golf/services/round_analysis_generator.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Single-stat widget showing Bogey Rate
///
/// Displays percentage of holes with bogeys in either
/// circular indicator or horizontal bar format.
/// Used by AI story to highlight error frequency and consistency issues.
class BogeyRateStoryCard extends StatelessWidget {
  const BogeyRateStoryCard({
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
    final double percentage = scoringStats.bogeyRate;
    final int count = scoringStats.bogeys;
    final int total = scoringStats.totalHoles;

    // Inverted: lower bogey rate = green (good), higher bogey rate = red (bad)
    final Color color = getSemanticColor(100 - percentage);

    if (renderMode == StatRenderMode.circle) {
      return CircularStatRenderer(
        percentage: percentage,
        label: 'Bogey Rate',
        color: color,
        icon: Icons.trending_down,
        count: count,
        total: total,
        roundId: round.id,
      );
    } else {
      return BarStatRenderer(
        percentage: percentage,
        label: 'Bogey Rate',
        color: color,
        icon: Icons.trending_down,
        count: count,
        total: total,
      );
    }
  }
}
