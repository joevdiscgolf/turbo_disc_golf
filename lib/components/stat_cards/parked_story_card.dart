import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/bar_stat_renderer.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/circular_stat_renderer.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/round_story_v2_content.dart';
import 'package:turbo_disc_golf/models/stat_render_mode.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';
import 'package:turbo_disc_golf/services/round_statistics_service.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Single-stat widget showing Parked percentage
///
/// Displays rate of landing tee shots within 10 feet (parked) in either
/// circular indicator or horizontal bar format.
/// Used by AI story to highlight elite accuracy and scoring opportunities.
///
/// When [scopedStats] is provided, displays those values instead of
/// whole-round stats, useful for showing stats for a specific hole range.
class ParkedStoryCard extends StatelessWidget {
  const ParkedStoryCard({
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
      percentage = stats.parkedPct;
      count = ((stats.parkedPct / 100) * stats.totalHoles).round();
      total = stats.totalHoles;
      scopeLabel = null;
    }

    final Color color = getSemanticColor(percentage);

    if (renderMode == StatRenderMode.circle) {
      return CircularStatRenderer(
        percentage: percentage,
        label: 'Parked',
        color: color,
        icon: Icons.star_rounded,
        count: count,
        total: total,
        roundId: round.id,
        showIcon: showIcon,
        subtitle: scopeLabel,
      );
    } else {
      return BarStatRenderer(
        percentage: percentage,
        label: 'Parked',
        color: color,
        icon: Icons.star_rounded,
        count: count,
        total: total,
        showIcon: showIcon,
        showContainer: false,
        subtitle: scopeLabel,
      );
    }
  }
}
