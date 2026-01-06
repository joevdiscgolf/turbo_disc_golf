import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/bar_stat_renderer.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/circular_stat_renderer.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/stat_render_mode.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';
import 'package:turbo_disc_golf/services/round_statistics_service.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Single-stat widget showing Parked percentage
///
/// Displays rate of landing tee shots within 10 feet (parked) in either
/// circular indicator or horizontal bar format.
/// Used by AI story to highlight elite accuracy and scoring opportunities.
class ParkedStoryCard extends StatelessWidget {
  const ParkedStoryCard({
    super.key,
    required this.round,
    required this.renderMode,
  });

  final DGRound round;
  final StatRenderMode renderMode;

  @override
  Widget build(BuildContext context) {
    final CoreStats stats = RoundStatisticsService(round).getCoreStats();
    final double percentage = stats.parkedPct;
    final int count = ((stats.parkedPct / 100) * stats.totalHoles).round();
    final int total = stats.totalHoles;

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
      );
    } else {
      return BarStatRenderer(
        percentage: percentage,
        label: 'Parked',
        color: color,
        icon: Icons.star_rounded,
        count: count,
        total: total,
      );
    }
  }
}
