import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:turbo_disc_golf/components/story/score_journey_graph.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/structured_story_content.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/share_stat_mapper.dart';
import 'package:turbo_disc_golf/utils/string_helpers.dart';

/// A tall poster-style shareable card for round stories with score journey graph.
///
/// This is a pure card component - returns only the card itself without
/// any layout wrappers or headers.
/// This card shows a visual score progression graph, the story title,
/// overview excerpt, and key stats. Designed for a more dramatic share.
class StoryPosterShareCard extends StatelessWidget {
  const StoryPosterShareCard({
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

  /// Fixed width for the inner card
  static const double cardWidth = 400;

  @override
  Widget build(BuildContext context) {
    // Story poster theme colors - elegant dark blue/purple gradient
    const List<Color> baseColors = [
      Color(0xFF4F46E5), // Indigo 600
      Color(0xFF7C3AED), // Violet 600
    ];

    // Card colors with slight transparency
    final List<Color> cardColors = [
      flattenedOverWhite(baseColors[0], 0.92),
      flattenedOverWhite(baseColors[1], 0.92),
    ];

    // Text colors
    const Color headlineColor = Colors.white;
    const Color bodyColor = Colors.white;
    final Color subtleColor = Colors.white.withValues(alpha: 0.8);
    final Color containerBgAlpha = Colors.white.withValues(alpha: 0.15);

    // Determine if this is an under par round for graph color
    final int totalRelative = round.getRelativeToPar();
    final Color graphLineColor = totalRelative <= 0
        ? const Color(0xFF4ADE80) // Green for under/even par
        : const Color(0xFFFF6B6B); // Red for over par

    return Container(
      width: cardWidth,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: cardColors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCourseAndDate(bodyColor),
            const SizedBox(height: 12),
            _buildTitleSection(headlineColor),
            const SizedBox(height: 16),
            _buildOverviewSection(bodyColor, containerBgAlpha),
            const SizedBox(height: 12),
            _buildStatsGrid(bodyColor, subtleColor, containerBgAlpha),
            const SizedBox(height: 12),
            _buildScoreJourneySection(
              containerBgAlpha,
              graphLineColor,
              subtleColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseAndDate(Color textColor) {
    String dateStr;
    try {
      final DateTime date = round.playedRoundAt.isNotEmpty
          ? DateTime.parse(round.playedRoundAt)
          : DateTime.parse(round.createdAt);
      dateStr = DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      dateStr = round.playedRoundAt.isNotEmpty
          ? round.playedRoundAt
          : round.createdAt;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            round.courseName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          dateStr,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textColor.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreJourneySection(
    Color bgColor,
    Color graphColor,
    Color labelColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SCORE JOURNEY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: labelColor.withValues(alpha: 0.7),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          ScoreJourneyGraph(
            holes: round.holes,
            lineColor: graphColor,
            height: 100,
            showLabels: true,
            labelColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(Color headlineColor) {
    return SizedBox(
      height: 32,
      child: FittedBox(
        child: Text(
          roundTitle.capitalizeFirst(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: headlineColor,
            letterSpacing: -0.3,
          ),
          maxLines: 1,
        ),
      ),
    );
  }

  Widget _buildOverviewSection(Color textColor, Color bgColor) {
    // Use shareableHeadline if available, otherwise fall back to overview
    final String displayText = shareableHeadline ?? overview;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor,
          height: 1.4,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget _buildStatsGrid(Color textColor, Color subtleColor, Color bgColor) {
    final List<ShareStat> stats = ShareStatMapper.getShareStats(
      round,
      analysis,
      shareHighlightStats,
    );

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: stats
            .map((stat) => _buildStatCell(stat, textColor, subtleColor))
            .toList(),
      ),
    );
  }

  Widget _buildStatCell(ShareStat stat, Color textColor, Color subtleColor) {
    return Expanded(
      child: Column(
        children: [
          Text(
            stat.value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            stat.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: subtleColor,
            ),
          ),
        ],
      ),
    );
  }
}
