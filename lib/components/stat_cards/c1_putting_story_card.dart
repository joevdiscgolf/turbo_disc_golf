import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/bar_stat_renderer.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/circular_stat_renderer.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/stat_render_mode.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';
import 'package:turbo_disc_golf/services/round_analysis_generator.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Single-stat widget showing C1 Putting percentage
///
/// Displays Circle 1 (0-33 ft) putting success rate in either
/// circular indicator or horizontal bar format.
/// Used by AI story to highlight overall putting performance inside C1.
class C1PuttingStoryCard extends StatelessWidget {
  const C1PuttingStoryCard({
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
    final PuttStats stats = analysis.puttingStats;
    final double percentage = stats.c1Percentage;
    final int count = stats.c1Makes;
    final int total = stats.c1Attempts;

    final Color color = getSemanticColor(percentage);

    if (renderMode == StatRenderMode.circle) {
      return CircularStatRenderer(
        percentage: percentage,
        label: 'C1 Putting',
        color: color,
        icon: Icons.golf_course,
        count: count,
        total: total,
        roundId: round.id,
        showIcon: showIcon,
      );
    } else {
      return BarStatRenderer(
        percentage: percentage,
        label: 'C1 Putting',
        color: color,
        icon: Icons.golf_course,
        count: count,
        total: total,
        showIcon: showIcon,
        showContainer: false,
      );
    }
  }
}
