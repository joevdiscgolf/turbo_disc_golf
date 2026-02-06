import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/share/generic_share_card.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/structured_story_content.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/share_stat_mapper.dart';

/// A compact, Instagram-style shareable card for round stories.
///
/// This is a pure card component - returns only the card itself without
/// any layout wrappers, backgrounds, or headers.
/// Designed to be captured as an image and shared on social media.
class StoryShareCard extends StatelessWidget {
  const StoryShareCard({
    super.key,
    required this.round,
    required this.analysis,
    required this.roundTitle,
    required this.overview,
    this.shareableHeadline,
    this.shareHighlightStats,
  });

  final DGRound round;
  final RoundAnalysis analysis;
  final String roundTitle;
  final String overview;
  final String? shareableHeadline;
  final List<ShareHighlightStat>? shareHighlightStats;

  @override
  Widget build(BuildContext context) {
    // Story theme colors - soft purple/blue gradient
    const List<Color> baseColors = [
      Color(0xFF6366F1), // Indigo
      Color(0xFF8B5CF6), // Purple
    ];

    // Lighter card colors using flattenedOverWhite
    final List<Color> gradientColors = [
      flattenedOverWhite(baseColors[0], 0.9),
      flattenedOverWhite(baseColors[1], 0.9),
    ];

    final Color containerBgAlpha = Colors.white.withValues(alpha: 0.2);

    // Get stats using ShareStatMapper
    final List<ShareStat> shareStats = ShareStatMapper.getShareStats(
      round,
      analysis,
      shareHighlightStats,
    );

    // Convert to ShareCardStat
    final List<ShareCardStat> stats = shareStats
        .map(
          (stat) => ShareCardStat(label: stat.label, value: stat.value),
        )
        .toList();

    // Use shareableHeadline if available, otherwise fall back to overview
    final String displayOverview = shareableHeadline ?? overview;

    return GenericShareCard(
      round: round,
      gradientColors: gradientColors,
      headline: roundTitle,
      overview: displayOverview,
      stats: stats,
      containerBgAlpha: containerBgAlpha,
      overviewFontSize: 18,
    );
  }
}
