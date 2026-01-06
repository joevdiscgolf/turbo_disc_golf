import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/bar_stat_renderer.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/circular_stat_renderer.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/stat_render_mode.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';
import 'package:turbo_disc_golf/services/round_analysis_generator.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Single-stat widget showing C1X Putting percentage
///
/// Displays Circle 1 Extended (11-33 ft) putting success rate in either
/// circular indicator or horizontal bar format.
/// Used by AI story to highlight key putting metric excluding gimme putts.
class C1XPuttingStoryCard extends StatelessWidget {
  const C1XPuttingStoryCard({
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
    final double percentage = stats.c1xPercentage;
    final int count = stats.c1xMakes;
    final int total = stats.c1xAttempts;

    final Color color = getSemanticColor(percentage);

    if (renderMode == StatRenderMode.circle) {
      return CircularStatRenderer(
        percentage: percentage,
        label: 'C1X Putting',
        color: color,
        icon: Icons.my_location,
        count: count,
        total: total,
        roundId: round.id,
      );
    } else {
      return BarStatRenderer(
        percentage: percentage,
        label: 'C1X Putting',
        color: color,
        icon: Icons.my_location,
        count: count,
        total: total,
      );
    }
  }
}
