import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/bar_stat_renderer.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/circular_stat_renderer.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/stat_render_mode.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';
import 'package:turbo_disc_golf/services/round_analysis_generator.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Single-stat widget showing C2 Putting percentage
///
/// Displays Circle 2 (33-66 ft) putting success rate in either
/// circular indicator or horizontal bar format.
/// Used by AI story to highlight long-range putting performance.
class C2PuttingStoryCard extends StatelessWidget {
  const C2PuttingStoryCard({
    super.key,
    required this.round,
    required this.renderMode,
  });

  final DGRound round;
  final StatRenderMode renderMode;

  @override
  Widget build(BuildContext context) {
    final analysis = RoundAnalysisGenerator.generateAnalysis(round);
    final PuttStats stats = analysis.puttingStats;
    final double percentage = stats.c2Percentage;
    final int count = stats.c2Makes;
    final int total = stats.c2Attempts;

    final Color color = getSemanticColor(percentage);

    if (renderMode == StatRenderMode.circle) {
      return CircularStatRenderer(
        percentage: percentage,
        label: 'C2 Putting',
        color: color,
        icon: Icons.adjust,
        count: count,
        total: total,
        roundId: round.id,
      );
    } else {
      return BarStatRenderer(
        percentage: percentage,
        label: 'C2 Putting',
        color: color,
        icon: Icons.adjust,
        count: count,
        total: total,
      );
    }
  }
}
