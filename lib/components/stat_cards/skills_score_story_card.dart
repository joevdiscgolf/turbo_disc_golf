import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/bar_stat_renderer.dart';
import 'package:turbo_disc_golf/components/stat_cards/renderers/circular_stat_renderer.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/stat_render_mode.dart';
import 'package:turbo_disc_golf/services/round_analysis/skills_analysis_service.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

/// Single-stat widget showing Overall Skills Score
///
/// Displays the comprehensive skills rating (0-100) based on driving,
/// putting, approaching, and mental focus in either circular indicator
/// or horizontal bar format.
/// Used by AI story to highlight overall performance quality.
class SkillsScoreStoryCard extends StatelessWidget {
  const SkillsScoreStoryCard({
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
    final skillsAnalysis = SkillsAnalysisService().getSkillsAnalysis(round);
    final double overallScore = skillsAnalysis.overallScore;

    // Skills score is already 0-100, treat it as a percentage
    final double percentage = overallScore;
    final int scoreValue = overallScore.round();

    final Color color = getSemanticColor(percentage);

    if (renderMode == StatRenderMode.circle) {
      return CircularStatRenderer(
        percentage: percentage,
        label: 'Overall Skills',
        color: color,
        icon: Icons.military_tech,
        count: scoreValue,
        total: 100,
        roundId: round.id,
        subtitle: '$scoreValue/100 overall rating',
        showIcon: showIcon,
      );
    } else {
      return BarStatRenderer(
        percentage: percentage,
        label: 'Overall Skills',
        color: color,
        icon: Icons.military_tech,
        count: scoreValue,
        total: 100,
        subtitle: '$scoreValue/100 overall rating',
        showIcon: showIcon,
        showContainer: false,
      );
    }
  }
}
