import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:turbo_disc_golf/components/compact_scorecard.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/string_helpers.dart';

/// A shareable card widget for roast/glaze judgments.
///
/// This card is designed to be captured as an image and shared on social media.
/// It includes the verdict, tagline, key stats, scorecard, and branding.
class JudgmentShareCard extends StatelessWidget {
  const JudgmentShareCard({
    super.key,
    required this.isGlaze,
    required this.headline,
    required this.tagline,
    required this.round,
    required this.analysis,
    required this.highlightStats,
  });

  final bool isGlaze;
  final String headline;
  final String tagline;
  final DGRound round;
  final RoundAnalysis analysis;
  final List<String> highlightStats;

  /// Fixed width for the inner card
  static const double cardWidth = 400;

  @override
  Widget build(BuildContext context) {
    // Base gradient colors
    final List<Color> baseColors = isGlaze
        ? [const Color(0xFF137e66), const Color(0xFF1a9f7f)] // Green theme
        : [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)];

    // Lighter card colors using flattenedOverWhite for better scorecard contrast
    // Use lower opacity for roast to make it darker
    final double cardOpacity = isGlaze ? 0.85 : 0.95;
    final List<Color> cardColors = [
      flattenedOverWhite(baseColors[0], cardOpacity),
      flattenedOverWhite(baseColors[1], cardOpacity),
    ];

    // Text colors - white works well on both green and red
    const Color headlineColor = Colors.white;
    const Color bodyColor = Colors.white;
    final Color subtleColor = Colors.white.withValues(alpha: 0.8);
    final Color containerBgAlpha = isGlaze
        ? Colors.white.withValues(alpha: 0.25)
        : Colors.white.withValues(alpha: 0.2);

    // White background ensures proper image capture (no transparency)
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCourseAndDate(bodyColor),
          const SizedBox(height: 12),
          _buildHeader(headlineColor),
          const SizedBox(height: 16),
          _buildTagline(bodyColor, containerBgAlpha),
          const SizedBox(height: 8),
          _buildStatsGrid(bodyColor, subtleColor, containerBgAlpha),
          const SizedBox(height: 8),
          _buildScorecard(subtleColor, containerBgAlpha),
          const SizedBox(height: 16),
          _buildFooter(bodyColor, subtleColor),
        ],
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

  Widget _buildHeader(Color textColor) {
    // Headline only - verdict is now outside the card
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

  Widget _buildTagline(Color textColor, Color bgColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        tagline,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
          height: 1.3,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget _buildStatsGrid(Color textColor, Color subtleColor, Color bgColor) {
    // Just 3 stats: Score + 2 AI-chosen relevant stats
    final List<_StatItem> stats = [
      _StatItem(
        label: 'Score',
        value: _formatScore(analysis.totalScoreRelativeToPar),
      ),
    ];

    // Add up to 2 AI-chosen stats
    final Set<String> usedLabels = {'Score'};
    for (final String statKey in highlightStats.take(2)) {
      final _StatItem? item = _getStatItem(statKey);
      if (item != null && !usedLabels.contains(item.label)) {
        stats.add(item);
        usedLabels.add(item.label);
      }
    }

    // Fallback pool if AI didn't provide enough stats
    final List<_StatItem> fallbackPool = [
      _StatItem(
        label: 'C1 Reg',
        value: '${analysis.coreStats.c1InRegPct.toStringAsFixed(0)}%',
      ),
      _StatItem(
        label: 'Fairway',
        value: '${analysis.coreStats.fairwayHitPct.toStringAsFixed(0)}%',
      ),
    ];

    // Fill to 3 stats if needed
    for (final _StatItem fallback in fallbackPool) {
      if (stats.length >= 3) break;
      if (!usedLabels.contains(fallback.label)) {
        stats.add(fallback);
        usedLabels.add(fallback.label);
      }
    }

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
        children: [
          _buildStatCell(stats[0], textColor, subtleColor),
          _buildStatCell(stats[1], textColor, subtleColor),
          _buildStatCell(stats[2], textColor, subtleColor),
        ],
      ),
    );
  }

  Widget _buildStatCell(_StatItem stat, Color textColor, Color subtleColor) {
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
        holeNumberColor: Colors.white, // Fully opaque white for visibility
        parScoreColor: Colors.white,
        useWhiteCircleText: true,
      ),
    );
  }

  Widget _buildFooter(Color textColor, Color subtleColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (locator.get<FeatureFlagService>().showQrCodeOnShareCard) ...[
          // QR code on left side
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: QrImageView(
              data: locator.get<FeatureFlagService>().shareCardQrUrl,
              version: QrVersions.auto,
              size: 40,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ] else ...[
          // Flexible line that scales down if needed
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 40),
              height: 1,
              color: subtleColor.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(width: 8),
        ],
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
        // Flexible line that scales down if needed
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

  String _formatScore(int score) {
    if (score >= 0) {
      return '+$score';
    }
    return '$score';
  }

  _StatItem? _getStatItem(String statKey) {
    // Labels must match the pool in _buildStatsGrid for duplicate detection
    switch (statKey) {
      case 'fairwayPct':
        return _StatItem(
          label: 'Fairway',
          value: '${analysis.coreStats.fairwayHitPct.toStringAsFixed(0)}%',
        );
      case 'c1xPuttPct':
        return _StatItem(
          label: 'C1X',
          value: '${analysis.puttingStats.c1xPercentage.toStringAsFixed(0)}%',
        );
      case 'obPct':
        return _StatItem(
          label: 'OB Rate',
          value: '${analysis.coreStats.obPct.toStringAsFixed(0)}%',
        );
      case 'parkedPct':
        return _StatItem(
          label: 'Parked',
          value: '${analysis.coreStats.parkedPct.toStringAsFixed(0)}%',
        );
      case 'scramblePct':
        return _StatItem(
          label: 'Scramble',
          value: '${analysis.scrambleStats.scrambleRate.toStringAsFixed(0)}%',
        );
      case 'bounceBackPct':
        return _StatItem(
          label: 'Bounce',
          value: '${analysis.bounceBackPercentage.toStringAsFixed(0)}%',
        );
      default:
        return null;
    }
  }
}

class _StatItem {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;
}
