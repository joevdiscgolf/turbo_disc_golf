import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/bar_stat_renderer.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/circular_stat_renderer.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/stat_render_mode.dart';
import 'package:turbo_disc_golf/services/round_analysis/psych_analysis_service.dart';

/// Single-stat widget showing Flow State percentage
///
/// Displays the percentage of the round spent in peak performance flow state
/// in either circular indicator or horizontal bar format.
/// Used by AI story to highlight periods of excellence and optimal performance.
class FlowStateStoryCard extends StatelessWidget {
  const FlowStateStoryCard({
    super.key,
    required this.round,
    required this.renderMode,
  });

  final DGRound round;
  final StatRenderMode renderMode;

  @override
  Widget build(BuildContext context) {
    final psychStats = locator.get<PsychAnalysisService>().getPsychStats(round);

    final flowAnalysis = psychStats.flowStateAnalysis;
    final double percentage = flowAnalysis?.flowPercentage ?? 0.0;
    final int count = flowAnalysis?.totalFlowHoles ?? 0;
    final int total = round.holes.length;

    if (renderMode == StatRenderMode.circle) {
      return CircularStatRenderer(
        percentage: percentage,
        label: 'Flow State',
        color: const Color(0xFF9C27B0),
        icon: Icons.psychology,
        count: count,
        total: total,
        roundId: round.id,
      );
    } else {
      return BarStatRenderer(
        percentage: percentage,
        label: 'Flow State',
        color: const Color(0xFF9C27B0),
        icon: Icons.psychology,
        count: count,
        total: total,
      );
    }
  }
}
