import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:turbo_disc_golf/components/compact_scorecard.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/structured_story_content.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/share_stat_mapper.dart';
import 'package:turbo_disc_golf/utils/string_helpers.dart';

/// A compact, Instagram-style shareable card for round stories.
///
/// This is a pure card component - returns only the card itself without
/// any layout wrappers, backgrounds, or headers.
/// Designed to be captured as an image and shared on social media.
class StoryHighlightsShareCard extends StatelessWidget {
  const StoryHighlightsShareCard({
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

  /// Fixed width for the card
  static const double cardWidth = 400;

  @override
  Widget build(BuildContext context) {
    // Story theme colors - soft purple/blue gradient
    const List<Color> baseColors = [
      Color(0xFF6366F1), // Indigo
      Color(0xFF8B5CF6), // Purple
    ];

    // Lighter card colors using flattenedOverWhite
    final List<Color> cardColors = [
      flattenedOverWhite(baseColors[0], 0.9),
      flattenedOverWhite(baseColors[1], 0.9),
    ];

    // Text colors
    const Color headlineColor = Colors.white;
    const Color bodyColor = Colors.white;
    final Color subtleColor = Colors.white.withValues(alpha: 0.8);
    final Color containerBgAlpha = Colors.white.withValues(alpha: 0.2);

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
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
            _buildStatsGrid(
              bodyColor,
              subtleColor,
              containerBgAlpha,
            ),
            const SizedBox(height: 12),
            _buildScorecard(subtleColor, containerBgAlpha),
            const SizedBox(height: 16),
            _buildFooter(bodyColor, subtleColor),
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
    // Get stats using ShareStatMapper
    final List<ShareStat> stats = ShareStatMapper.getShareStats(
      round,
      analysis,
      shareHighlightStats,
    );

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          top: BorderSide(color: subtleColor.withValues(alpha: 0.3), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              fontSize: 18,
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

  Widget _buildScorecard(Color textColor, Color bgColor) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: CompactScorecard(
        holes: round.holes,
        holeNumberColor: Colors.white,
        parScoreColor: Colors.white,
        useWhiteCircleText: true,
      ),
    );
  }

  Widget _buildFooter(Color textColor, Color subtleColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 40),
            height: 1,
            color: subtleColor.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(width: 8),
        ColorFiltered(
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          child: Image.asset(
            'assets/icon/app_icon_clear_bg.png',
            height: 16,
            width: 16,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'ScoreSensei disc golf',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: subtleColor.withValues(alpha: 0.85),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 40),
            height: 1,
            color: subtleColor.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}
