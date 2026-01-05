import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/bar_stat_renderer.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/circular_stat_renderer.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/stat_render_mode.dart';
import 'package:turbo_disc_golf/services/round_analysis/psych_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_analysis_generator.dart';

/// Single-stat widget showing Bounce Back Rate
///
/// Displays the percentage of times the player made par-or-better
/// after a bogey or worse, in either circular indicator or horizontal bar format.
/// Used by AI story to highlight mental resilience and recovery ability.
class BounceBackStoryCard extends StatelessWidget {
  const BounceBackStoryCard({
    super.key,
    required this.round,
    required this.renderMode,
  });

  final DGRound round;
  final StatRenderMode renderMode;

  @override
  Widget build(BuildContext context) {
    final psychStats = locator.get<PsychAnalysisService>().getPsychStats(round);
    final analysis = RoundAnalysisGenerator.generateAnalysis(round);

    final double percentage = psychStats.bounceBackRate;

    // Calculate bounce back opportunities (bogeys and worse)
    final scoringStats = analysis.scoringStats;
    final int opportunities = scoringStats.bogeys + scoringStats.doubleBogeyPlus;
    final int count = ((percentage / 100) * opportunities).round();

    if (renderMode == StatRenderMode.circle) {
      return CircularStatRenderer(
        percentage: percentage,
        label: 'Bounce Back',
        color: const Color(0xFF4CAF50),
        icon: Icons.restore,
        count: count,
        total: opportunities,
        roundId: round.id,
      );
    } else {
      return BarStatRenderer(
        percentage: percentage,
        label: 'Bounce Back',
        color: const Color(0xFF4CAF50),
        icon: Icons.restore,
        count: count,
        total: opportunities,
      );
    }
  }
}
