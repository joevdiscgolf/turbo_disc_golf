import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:turbo_disc_golf/components/compact_scorecard.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/utils/string_helpers.dart';

/// A stat item for display in the share card stats grid.
class ShareCardStat {
  const ShareCardStat({required this.label, required this.value});

  final String label;
  final String value;
}

/// Generic shareable card widget for round content.
///
/// This card is designed to be captured as an image and shared on social media.
/// It includes the course info, headline, overview, stats, scorecard, and date/time.
class GenericShareCard extends StatelessWidget {
  const GenericShareCard({
    super.key,
    required this.round,
    required this.gradientColors,
    required this.headline,
    required this.overview,
    required this.stats,
    required this.containerBgAlpha,
    this.overviewFontSize = 14,
  });

  final DGRound round;
  final List<Color> gradientColors;
  final String headline;
  final String overview;
  final List<ShareCardStat> stats;
  final Color containerBgAlpha;
  final double overviewFontSize;

  /// Fixed width for the card
  static const double cardWidth = 400;

  @override
  Widget build(BuildContext context) {
    // Text colors - white works well on all gradient backgrounds
    const Color headlineColor = Colors.white;
    const Color bodyColor = Colors.white;
    final Color subtleColor = Colors.white.withValues(alpha: 0.9);

    return Container(
      width: cardWidth,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
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
            _buildCourseInfo(bodyColor),
            const SizedBox(height: 8),
            _buildHeader(headlineColor),
            const SizedBox(height: 16),
            _buildOverview(bodyColor, containerBgAlpha),
            const SizedBox(height: 8),
            _buildStatsGrid(bodyColor, subtleColor, containerBgAlpha),
            const SizedBox(height: 8),
            _buildScorecard(subtleColor, containerBgAlpha),
            const SizedBox(height: 12),
            _buildDateTimeFooter(subtleColor),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseInfo(Color textColor) {
    // Find the layout name
    String layoutName = '';
    try {
      final layout = round.course.layouts.firstWhere(
        (l) => l.id == round.layoutId,
      );
      layoutName = layout.name;
    } catch (e) {
      // If layout not found, try to use first layout
      if (round.course.layouts.isNotEmpty) {
        layoutName = round.course.layouts.first.name;
      }
    }

    return Text(
      layoutName.isNotEmpty
          ? '${round.courseName} · $layoutName'
          : round.courseName,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  Widget _buildHeader(Color textColor) {
    return SizedBox(
      height: 32,
      child: FittedBox(
        child: Text(
          headline.capitalizeFirst(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: -0.3,
          ),
          maxLines: 1,
        ),
      ),
    );
  }

  Widget _buildOverview(Color textColor, Color bgColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        overview,
        style: TextStyle(
          fontSize: overviewFontSize,
          fontWeight: FontWeight.w600,
          color: textColor,
          height: 1.3,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget _buildStatsGrid(Color textColor, Color subtleColor, Color bgColor) {
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

  Widget _buildStatCell(
    ShareCardStat stat,
    Color textColor,
    Color subtleColor,
  ) {
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

  Widget _buildDateTimeFooter(Color textColor) {
    String dateStr;
    String timeStr;
    try {
      final DateTime dateTime = round.playedRoundAt.isNotEmpty
          ? DateTime.parse(round.playedRoundAt)
          : DateTime.parse(round.createdAt);
      dateStr = DateFormat('MMM d, yyyy').format(dateTime);
      timeStr = DateFormat('h:mm a').format(dateTime);
    } catch (e) {
      dateStr = round.playedRoundAt.isNotEmpty
          ? round.playedRoundAt
          : round.createdAt;
      timeStr = '';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dateStr,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          if (timeStr.isNotEmpty)
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
        ],
      ),
    );
  }
}
