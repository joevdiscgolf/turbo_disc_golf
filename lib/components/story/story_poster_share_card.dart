import 'dart:math';

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

  /// Seed for random emoji positions (based on round data for consistency)
  int get _randomSeed => round.versionId.hashCode;

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

    // Outer background tint
    final List<Color> outerColors = [
      baseColors[0].withValues(alpha: 0.10),
      baseColors[1].withValues(alpha: 0.10),
    ];

    final double screenHeight = MediaQuery.of(context).size.height;

    // Determine if this is an under par round for graph color
    final int totalRelative = round.getRelativeToPar();
    final Color graphLineColor = totalRelative <= 0
        ? const Color(0xFF4ADE80) // Green for under/even par
        : const Color(0xFFFF6B6B); // Red for over par

    // White background ensures proper image capture
    return Container(
      width: double.infinity,
      height: screenHeight,
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: outerColors,
          ),
        ),
        child: Stack(
          children: [
            // Random background emojis
            ..._buildBackgroundEmojis(screenHeight),
            // Main content
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header outside the card
                    _buildHeaderText(),
                    const SizedBox(height: 16),
                    // Inner card
                    Container(
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
                            _buildScoreJourneySection(
                              containerBgAlpha,
                              graphLineColor,
                              subtleColor,
                            ),
                            const SizedBox(height: 16),
                            _buildFooter(bodyColor, subtleColor),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds random background emojis
  List<Widget> _buildBackgroundEmojis(double screenHeight) {
    final Random random = Random(_randomSeed);
    const String bgEmoji = '\u{1F94F}'; // Flying disc emoji
    final List<Widget> emojis = [];

    const int cols = 6;
    const int rows = 10;
    const double screenWidth = 450.0;

    final double cellWidth = screenWidth / cols;
    final double cellHeight = screenHeight / rows;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final double offsetX = 0.1 + random.nextDouble() * 0.8;
        final double offsetY = 0.1 + random.nextDouble() * 0.8;

        final double left = col * cellWidth + offsetX * cellWidth;
        final double top = row * cellHeight + offsetY * cellHeight;

        final double rotation = (random.nextDouble() - 0.5) * 1.2;
        final double opacity = 0.05 + random.nextDouble() * 0.06;
        final double size = 14 + random.nextDouble() * 10;

        emojis.add(
          Positioned(
            top: top,
            left: left,
            child: Transform.rotate(
              angle: rotation,
              child: Opacity(
                opacity: opacity,
                child: Text(bgEmoji, style: TextStyle(fontSize: size)),
              ),
            ),
          ),
        );
      }
    }

    return emojis;
  }

  Widget _buildHeaderText() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '\u{1F94F}', // Flying disc emoji
          style: TextStyle(fontSize: 24),
        ),
        const SizedBox(width: 8),
        Text(
          'My Round Story',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: TurbColors.gray[700]!,
          ),
        ),
      ],
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

  Widget _buildFooter(Color textColor, Color subtleColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 50),
            height: 1,
            color: subtleColor.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(width: 12),
        ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Colors.white,
            BlendMode.srcIn,
          ),
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: subtleColor.withValues(alpha: 0.8),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 50),
            height: 1,
            color: subtleColor.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}
