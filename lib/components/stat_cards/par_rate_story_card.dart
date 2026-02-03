import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/bar_stat_renderer.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/circular_stat_renderer.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/stat_render_mode.dart';
import 'package:turbo_disc_golf/services/round_analysis_generator.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Single-stat widget showing Par Rate
///
/// Displays percentage of holes with pars in either
/// circular indicator or horizontal bar format.
/// Used by AI story to highlight consistency and solid performance.
class ParRateStoryCard extends StatelessWidget {
  const ParRateStoryCard({
    super.key,
    required this.round,
    required this.renderMode,
    this.showIcon = true,
  });

  final DGRound round;
  final StatRenderMode renderMode;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final analysis = RoundAnalysisGenerator.generateAnalysis(round);
    final scoringStats = analysis.scoringStats;
    final double percentage = scoringStats.parRate;
    final int count = scoringStats.pars;
    final int total = scoringStats.totalHoles;

    final Color color = getSemanticColor(percentage);

    if (renderMode == StatRenderMode.circle) {
      return CircularStatRenderer(
        percentage: percentage,
        label: 'Par Rate',
        color: color,
        icon: Icons.remove,
        count: count,
        total: total,
        roundId: round.id,
        showIcon: showIcon,
      );
    } else {
      return BarStatRenderer(
        percentage: percentage,
        label: 'Par Rate',
        color: color,
        icon: Icons.remove,
        count: count,
        total: total,
        showIcon: showIcon,
        showContainer: false,
      );
    }
  }
}
