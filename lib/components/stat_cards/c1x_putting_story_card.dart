import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/bar_stat_renderer.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/circular_stat_renderer.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/round_story_v2_content.dart';
import 'package:turbo_disc_golf/models/stat_render_mode.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';
import 'package:turbo_disc_golf/services/round_analysis_generator.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Single-stat widget showing C1X Putting percentage
///
/// Displays Circle 1 Extended (11-33 ft) putting success rate in either
/// circular indicator or horizontal bar format.
/// Used by AI story to highlight key putting metric excluding gimme putts.
///
/// When [scopedStats] is provided, displays those values instead of
/// whole-round stats, useful for showing stats for a specific hole range.
class C1XPuttingStoryCard extends StatelessWidget {
  const C1XPuttingStoryCard({
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
      scopeLabel = scopedStats!.label;
    } else {
      final analysis = RoundAnalysisGenerator.generateAnalysis(round);
      final PuttStats stats = analysis.puttingStats;
      percentage = stats.c1xPercentage;
      count = stats.c1xMakes;
      total = stats.c1xAttempts;
      scopeLabel = null;
    }

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
        showIcon: showIcon,
        subtitle: scopeLabel,
      );
    } else {
      return BarStatRenderer(
        percentage: percentage,
        label: 'C1X Putting',
        color: color,
        icon: Icons.my_location,
        count: count,
        total: total,
        showIcon: showIcon,
        showContainer: false,
        subtitle: scopeLabel,
      );
    }
  }
}
