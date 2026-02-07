import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/bar_stat_renderer.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/circular_stat_renderer.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/round_story_v2_content.dart';
import 'package:turbo_disc_golf/models/stat_render_mode.dart';
import 'package:turbo_disc_golf/services/round_analysis_generator.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Single-stat widget showing Birdie Rate
///
/// Displays percentage of holes with birdies in either
/// circular indicator or horizontal bar format.
/// Used by AI story to highlight scoring aggression and success.
///
/// When [scopedStats] is provided, displays those values instead of
/// whole-round stats, useful for showing stats for a specific hole range.
class BirdieRateStoryCard extends StatelessWidget {
  const BirdieRateStoryCard({
    super.key,
    required this.round,
    required this.renderMode,
    this.showIcon = true,
    this.scopedStats,
  });

  final DGRound round;
  final StatRenderMode renderMode;
  final bool showIcon;
  final ScopedStats? scopedStats;

  @override
  Widget build(BuildContext context) {
    // Use scoped stats if provided, otherwise compute from full round
    final double percentage;
    final int count;
    final int total;
    final String? scopeLabel;

    if (scopedStats != null && scopedStats!.percentage != null) {
      percentage = scopedStats!.percentage!;
      count = scopedStats!.made ?? 0;
      total = scopedStats!.attempts ?? 0;
      scopeLabel = scopedStats!.holeRange?.displayString;
    } else {
      final analysis = RoundAnalysisGenerator.generateAnalysis(round);
      final scoringStats = analysis.scoringStats;
      percentage = scoringStats.birdieRate;
      count = scoringStats.birdies;
      total = scoringStats.totalHoles;
      scopeLabel = null;
    }

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
        showIcon: showIcon,
        subtitle: scopeLabel,
      );
    } else {
      return BarStatRenderer(
        percentage: percentage,
        label: 'Birdie Rate',
        color: color,
        icon: Icons.trending_up,
        count: count,
        total: total,
        showIcon: showIcon,
        showContainer: false,
        subtitle: scopeLabel,
      );
    }
  }
}
