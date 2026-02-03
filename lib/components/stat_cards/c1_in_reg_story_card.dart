import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/bar_stat_renderer.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/circular_stat_renderer.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/stat_render_mode.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';
import 'package:turbo_disc_golf/services/round_statistics_service.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Single-stat widget showing C1 in Regulation percentage
///
/// Displays rate of reaching Circle 1 (0-33 ft) off the tee in either
/// circular indicator or horizontal bar format.
/// Used by AI story to highlight birdie opportunity creation.
class C1InRegStoryCard extends StatelessWidget {
  const C1InRegStoryCard({
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
    final CoreStats stats = RoundStatisticsService(round).getCoreStats();
    final double percentage = stats.c1InRegPct;
    final int count = ((stats.c1InRegPct / 100) * stats.totalHoles).round();
    final int total = stats.totalHoles;

    final Color color = getSemanticColor(percentage);

    if (renderMode == StatRenderMode.circle) {
      return CircularStatRenderer(
        percentage: percentage,
        label: 'C1 in Regulation',
        color: color,
        icon: Icons.track_changes,
        count: count,
        total: total,
        roundId: round.id,
        showIcon: showIcon,
      );
    } else {
      return BarStatRenderer(
        percentage: percentage,
        label: 'C1 in Regulation',
        color: color,
        icon: Icons.track_changes,
        count: count,
        total: total,
        showIcon: showIcon,
        showContainer: false,
      );
    }
  }
}
