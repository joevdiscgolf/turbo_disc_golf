import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/bar_stat_renderer.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/circular_stat_renderer.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/round_story_v2_content.dart';
import 'package:turbo_disc_golf/models/stat_render_mode.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';
import 'package:turbo_disc_golf/services/round_statistics_service.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Single-stat widget showing Fairway Hit percentage
///
/// Displays fairway hit rate in either circular indicator or horizontal bar format.
/// Used by AI story to highlight tee shot accuracy and avoiding trouble.
///
/// When [scopedStats] is provided, displays those values instead of
/// whole-round stats, useful for showing stats for a specific hole range.
class FairwayHitStoryCard extends StatelessWidget {
  const FairwayHitStoryCard({
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
      final CoreStats stats = RoundStatisticsService(round).getCoreStats();
      percentage = stats.fairwayHitPct;
      count = ((stats.fairwayHitPct / 100) * stats.totalHoles).round();
      total = stats.totalHoles;
      scopeLabel = null;
    }

    final Color color = getSemanticColor(percentage);

    if (renderMode == StatRenderMode.circle) {
      return CircularStatRenderer(
        percentage: percentage,
        label: 'Fairway Hit',
        color: color,
        icon: Icons.gps_fixed,
        count: count,
        total: total,
        roundId: round.id,
        showIcon: showIcon,
        subtitle: scopeLabel,
      );
    } else {
      return BarStatRenderer(
        percentage: percentage,
        label: 'Fairway Hit',
        color: color,
        icon: Icons.gps_fixed,
        count: count,
        total: total,
        showIcon: showIcon,
        showContainer: false,
        subtitle: scopeLabel,
      );
    }
  }
}
