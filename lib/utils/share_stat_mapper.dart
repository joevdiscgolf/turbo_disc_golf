import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/structured_story_content.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';

/// A single stat to display on a share card
class ShareStat {
  const ShareStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

/// Maps stat IDs to their display values for share cards
class ShareStatMapper {
  /// Get a ShareStat from a stat ID
  static ShareStat? getStatFromId(
    String statId,
    DGRound round,
    RoundAnalysis analysis,
  ) {
    switch (statId) {
      case 'score':
        return ShareStat(
          label: 'Score',
          value: _formatScore(round.getRelativeToPar()),
        );
      case 'c1PuttPct':
        return ShareStat(
          label: 'C1 Putt',
          value: '${analysis.puttingStats.c1Percentage.round()}%',
        );
      case 'c1xPuttPct':
        return ShareStat(
          label: 'C1X Putt',
          value: '${analysis.puttingStats.c1xPercentage.round()}%',
        );
      case 'c2PuttPct':
        return ShareStat(
          label: 'C2 Putt',
          value: '${analysis.puttingStats.c2Percentage.round()}%',
        );
      case 'fairwayPct':
        return ShareStat(
          label: 'Fairway',
          value: '${analysis.coreStats.fairwayHitPct.round()}%',
        );
      case 'parkedPct':
        return ShareStat(
          label: 'Parked',
          value: '${analysis.coreStats.parkedPct.round()}%',
        );
      case 'c1InRegPct':
        return ShareStat(
          label: 'C1 Reg',
          value: '${analysis.coreStats.c1InRegPct.round()}%',
        );
      case 'obPct':
        return ShareStat(
          label: 'OB Rate',
          value: '${analysis.coreStats.obPct.round()}%',
        );
      case 'birdies':
        return ShareStat(
          label: 'Birdies',
          value: '${analysis.scoringStats.birdies}',
        );
      case 'bounceBack':
        return ShareStat(
          label: 'Bounce Back',
          value: '${analysis.bounceBackPercentage.round()}%',
        );
      default:
        return null;
    }
  }

  /// Get stats from AI-selected shareHighlightStats, with fallbacks
  ///
  /// Returns a list of 3 stats: Score + 2 AI-selected or fallback stats
  static List<ShareStat> getShareStats(
    DGRound round,
    RoundAnalysis analysis,
    List<ShareHighlightStat>? shareHighlightStats,
  ) {
    final List<ShareStat> stats = [
      ShareStat(
        label: 'Score',
        value: _formatScore(round.getRelativeToPar()),
      ),
    ];

    // Try to get AI-selected stats
    if (shareHighlightStats != null && shareHighlightStats.isNotEmpty) {
      for (final ShareHighlightStat highlight in shareHighlightStats.take(2)) {
        final ShareStat? stat = getStatFromId(
          highlight.statId,
          round,
          analysis,
        );
        if (stat != null) {
          stats.add(stat);
        }
      }
    }

    // If we still don't have 3 stats, use fallbacks
    if (stats.length < 3) {
      final List<ShareStat> fallbacks = _getFallbackStats(round, analysis);
      for (final ShareStat fallback in fallbacks) {
        if (stats.length >= 3) break;
        // Don't add duplicates
        if (!stats.any((s) => s.label == fallback.label)) {
          stats.add(fallback);
        }
      }
    }

    return stats.take(3).toList();
  }

  /// Fallback stats for legacy stories without shareHighlightStats
  /// Returns most impressive/notable stats from analysis
  static List<ShareStat> _getFallbackStats(
    DGRound round,
    RoundAnalysis analysis,
  ) {
    final List<ShareStat> candidates = [];

    // Add C1 Putt % if above average (>70%)
    if (analysis.puttingStats.c1Percentage >= 70) {
      candidates.add(ShareStat(
        label: 'C1 Putt',
        value: '${analysis.puttingStats.c1Percentage.round()}%',
      ));
    }

    // Add Fairway % if above average (>60%)
    if (analysis.coreStats.fairwayHitPct >= 60) {
      candidates.add(ShareStat(
        label: 'Fairway',
        value: '${analysis.coreStats.fairwayHitPct.round()}%',
      ));
    }

    // Add birdies count if notable (3+)
    if (analysis.scoringStats.birdies >= 3) {
      candidates.add(ShareStat(
        label: 'Birdies',
        value: '${analysis.scoringStats.birdies}',
      ));
    }

    // Add C1 in Reg if above average (>30%)
    if (analysis.coreStats.c1InRegPct >= 30) {
      candidates.add(ShareStat(
        label: 'C1 Reg',
        value: '${analysis.coreStats.c1InRegPct.round()}%',
      ));
    }

    // Add parked % if notable (>10%)
    if (analysis.coreStats.parkedPct >= 10) {
      candidates.add(ShareStat(
        label: 'Parked',
        value: '${analysis.coreStats.parkedPct.round()}%',
      ));
    }

    // If we don't have enough good stats, add defaults
    if (candidates.isEmpty) {
      candidates.add(ShareStat(
        label: 'C1 Putt',
        value: '${analysis.puttingStats.c1Percentage.round()}%',
      ));
      candidates.add(ShareStat(
        label: 'Fairway',
        value: '${analysis.coreStats.fairwayHitPct.round()}%',
      ));
    }

    return candidates;
  }

  /// Format score relative to par
  static String _formatScore(int relativeToPar) {
    if (relativeToPar == 0) return 'E';
    if (relativeToPar > 0) return '+$relativeToPar';
    return '$relativeToPar';
  }
}
