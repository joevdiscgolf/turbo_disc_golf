import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/share/generic_share_card.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/score_helpers.dart';

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

  @override
  Widget build(BuildContext context) {
    // Base gradient colors
    final List<Color> baseColors = isGlaze
        ? [const Color(0xFF137e66), const Color(0xFF1a9f7f)] // Green theme
        : [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)];

    // Lighter card colors using flattenedOverWhite for better scorecard contrast
    // Use lower opacity for roast to make it darker
    final double cardOpacity = isGlaze ? 0.85 : 0.95;
    final List<Color> gradientColors = [
      flattenedOverWhite(baseColors[0], cardOpacity),
      flattenedOverWhite(baseColors[1], cardOpacity),
    ];

    final Color containerBgAlpha = isGlaze
        ? Colors.white.withValues(alpha: 0.25)
        : Colors.white.withValues(alpha: 0.2);

    // Build stats list
    final List<ShareCardStat> stats = _buildStats();

    return GenericShareCard(
      round: round,
      gradientColors: gradientColors,
      headline: headline,
      overview: tagline,
      stats: stats,
      containerBgAlpha: containerBgAlpha,
    );
  }

  List<ShareCardStat> _buildStats() {
    // Just 3 stats: Score + 2 AI-chosen relevant stats
    final List<ShareCardStat> stats = [
      ShareCardStat(
        label: 'Score',
        value: getRelativeScoreString(analysis.totalScoreRelativeToPar),
      ),
    ];

    // Add up to 2 AI-chosen stats
    final Set<String> usedLabels = {'Score'};
    for (final String statKey in highlightStats.take(2)) {
      final ShareCardStat? item = _getStatItem(statKey);
      if (item != null && !usedLabels.contains(item.label)) {
        stats.add(item);
        usedLabels.add(item.label);
      }
    }

    // Fallback pool if AI didn't provide enough stats
    final List<ShareCardStat> fallbackPool = [
      ShareCardStat(
        label: 'C1 Reg',
        value: '${analysis.coreStats.c1InRegPct.toStringAsFixed(0)}%',
      ),
      ShareCardStat(
        label: 'Fairway',
        value: '${analysis.coreStats.fairwayHitPct.toStringAsFixed(0)}%',
      ),
    ];

    // Fill to 3 stats if needed
    for (final ShareCardStat fallback in fallbackPool) {
      if (stats.length >= 3) break;
      if (!usedLabels.contains(fallback.label)) {
        stats.add(fallback);
        usedLabels.add(fallback.label);
      }
    }

    return stats;
  }

  ShareCardStat? _getStatItem(String statKey) {
    // Labels must match the pool in _buildStats for duplicate detection
    switch (statKey) {
      case 'fairwayPct':
        return ShareCardStat(
          label: 'Fairway',
          value: '${analysis.coreStats.fairwayHitPct.toStringAsFixed(0)}%',
        );
      case 'c1xPuttPct':
        return ShareCardStat(
          label: 'C1X',
          value: '${analysis.puttingStats.c1xPercentage.toStringAsFixed(0)}%',
        );
      case 'obPct':
        return ShareCardStat(
          label: 'OB Rate',
          value: '${analysis.coreStats.obPct.toStringAsFixed(0)}%',
        );
      case 'parkedPct':
        return ShareCardStat(
          label: 'Parked',
          value: '${analysis.coreStats.parkedPct.toStringAsFixed(0)}%',
        );
      case 'scramblePct':
        return ShareCardStat(
          label: 'Scramble',
          value: '${analysis.scrambleStats.scrambleRate.toStringAsFixed(0)}%',
        );
      case 'bounceBackPct':
        return ShareCardStat(
          label: 'Bounce',
          value: '${analysis.bounceBackPercentage.toStringAsFixed(0)}%',
        );
      default:
        return null;
    }
  }
}
