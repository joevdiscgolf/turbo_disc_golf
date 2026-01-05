import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/bar_stat_renderer.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/circular_stat_renderer.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/stat_render_mode.dart';
import 'package:turbo_disc_golf/services/round_analysis/psych_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_analysis_generator.dart';

/// Single-stat widget showing Hot Streak Energy
///
/// Displays the percentage of times a birdie was followed by another birdie
/// (birdie-after-birdie rate) in either circular indicator or horizontal bar format.
/// Used by AI story to highlight scoring momentum and streak performance.
class HotStreakStoryCard extends StatelessWidget {
  const HotStreakStoryCard({
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

    // Hot streak energy: birdie-after-birdie percentage
    final double percentage =
        psychStats.transitionMatrix['Birdie']?.toBirdiePercent ?? 0.0;

    // Calculate opportunities (total birdies that could be followed by another hole)
    final scoringStats = analysis.scoringStats;
    final int totalBirdies = scoringStats.birdies;
    final int opportunities = totalBirdies > 0 ? totalBirdies : 1;
    final int count = ((percentage / 100) * opportunities).round();

    if (renderMode == StatRenderMode.circle) {
      return CircularStatRenderer(
        percentage: percentage,
        label: 'Hot Streak',
        color: const Color(0xFFFF6F00),
        icon: Icons.local_fire_department,
        count: count,
        total: opportunities,
        roundId: round.id,
      );
    } else {
      return BarStatRenderer(
        percentage: percentage,
        label: 'Hot Streak',
        color: const Color(0xFFFF6F00),
        icon: Icons.local_fire_department,
        count: count,
        total: opportunities,
      );
    }
  }
}
