import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/compact_stat_cards.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';
import 'package:turbo_disc_golf/services/round_analysis/psych_analysis_service.dart';

/// Registry for stat card widgets that can be embedded in AI responses
/// All cards are small, clean, and lightweight - perfect for storytelling
class StatCardRegistry {
  /// Build a stat card widget from its ID
  ///
  /// Returns null if card ID is not recognized or data is unavailable
  static Widget? buildCard(
    String cardId,
    DGRound round,
    RoundAnalysis analysis, {
    Map<String, dynamic>? params,
  }) {
    // Make card ID case-insensitive
    final id = cardId.toUpperCase();

    switch (id) {
      // ===== PUTTING CARDS =====
      case 'C1X_PUTTING':
        return _buildC1xPuttingCard(analysis);
      case 'C1_PUTTING':
        return _buildC1PuttingCard(analysis);
      case 'C2_PUTTING':
        return _buildC2PuttingCard(analysis);
      case 'PUTTING_COMPARISON':
        return _buildPuttingComparisonCard(analysis);

      // ===== DRIVING CARDS =====
      case 'FAIRWAY_HIT':
        return _buildFairwayHitCard(analysis);
      case 'C1_IN_REG':
        return _buildC1InRegCard(analysis);
      case 'OB_RATE':
        return _buildOBRateCard(analysis);

      // ===== SCORING CARDS =====
      case 'BIRDIES':
        return _buildBirdiesCard(analysis);
      case 'BOGEYS':
        return _buildBogeysCard(analysis);
      case 'SCORING_MIX':
        return _buildScoringMixCard(analysis);

      // ===== MISTAKE CARDS =====
      case 'TOTAL_MISTAKES':
        return _buildTotalMistakesCard(analysis);
      case 'DRIVING_MISTAKES':
        return _buildDrivingMistakesCard(analysis);
      case 'PUTTING_MISTAKES':
        return _buildPuttingMistakesCard(analysis);
      case 'APPROACH_MISTAKES':
        return _buildApproachMistakesCard(analysis);

      // ===== MENTAL GAME CARDS =====
      case 'BOUNCE_BACK':
        return _buildBounceBackCard(analysis);
      case 'HOT_STREAK':
        return _buildHotStreakCard(round);
      case 'COLD_STREAK':
        return _buildColdStreakCard(round);

      // ===== DISC PERFORMANCE CARDS =====
      case 'TOP_DISC':
        return _buildTopDiscCard(analysis);
      case 'DISC_COUNT':
        return _buildDiscCountCard(analysis);

      default:
        debugPrint('Unknown stat card ID: $cardId');
        return _buildUnknownCard(cardId);
    }
  }

  // ===== PUTTING CARDS =====

  static Widget _buildC1xPuttingCard(RoundAnalysis analysis) {
    final stats = analysis.puttingStats;
    return CompactStatCards.buildFractionCard(
      label: 'C1x Putts Made',
      numerator: stats.c1xMakes,
      denominator: stats.c1xAttempts,
      color: const Color(0xFF137e66),
    );
  }

  static Widget _buildC1PuttingCard(RoundAnalysis analysis) {
    final stats = analysis.puttingStats;
    return CompactStatCards.buildFractionCard(
      label: 'C1 Putts Made',
      numerator: stats.c1Makes,
      denominator: stats.c1Attempts,
      color: const Color(0xFF137e66),
    );
  }

  static Widget _buildC2PuttingCard(RoundAnalysis analysis) {
    final stats = analysis.puttingStats;
    return CompactStatCards.buildFractionCard(
      label: 'C2 Putts Made',
      numerator: stats.c2Makes,
      denominator: stats.c2Attempts,
      color: const Color(0xFF10E5FF),
    );
  }

  static Widget _buildPuttingComparisonCard(RoundAnalysis analysis) {
    final stats = analysis.puttingStats;
    return CompactStatCards.buildComparisonCard(
      leftLabel: 'C1',
      leftValue: '${stats.c1Percentage.toStringAsFixed(0)}%',
      leftColor: const Color(0xFF137e66),
      rightLabel: 'C2',
      rightValue: '${stats.c2Percentage.toStringAsFixed(0)}%',
      rightColor: const Color(0xFF10E5FF),
    );
  }

  // ===== DRIVING CARDS =====

  static Widget _buildFairwayHitCard(RoundAnalysis analysis) {
    return CompactStatCards.buildPercentageCard(
      label: 'Fairway Hit',
      percentage: analysis.coreStats.fairwayHitPct,
      color: const Color(0xFF9D4EDD),
      subtitle: 'Off the tee',
    );
  }

  static Widget _buildC1InRegCard(RoundAnalysis analysis) {
    return CompactStatCards.buildPercentageCard(
      label: 'C1 in Regulation',
      percentage: analysis.coreStats.c1InRegPct,
      color: const Color(0xFF137e66),
      subtitle: 'Chance for birdie in C1',
    );
  }

  static Widget _buildOBRateCard(RoundAnalysis analysis) {
    return CompactStatCards.buildPercentageCard(
      label: 'Out of Bounds',
      percentage: analysis.coreStats.obPct,
      color: const Color(0xFFFF7A7A),
      subtitle: 'OB rate',
    );
  }

  // ===== SCORING CARDS =====

  static Widget _buildBirdiesCard(RoundAnalysis analysis) {
    return CompactStatCards.buildCountCard(
      label: 'Birdies',
      count: analysis.scoringStats.birdies,
      color: const Color(0xFF4CAF50),
      icon: Icons.arrow_downward,
    );
  }

  static Widget _buildBogeysCard(RoundAnalysis analysis) {
    return CompactStatCards.buildCountCard(
      label: 'Bogeys',
      count: analysis.scoringStats.bogeys,
      color: const Color(0xFFFFB800),
      icon: Icons.arrow_upward,
    );
  }

  static Widget _buildScoringMixCard(RoundAnalysis analysis) {
    final stats = analysis.scoringStats;
    return CompactStatCards.buildHighlightCard(
      title: 'Scoring Breakdown',
      description:
          '${stats.birdies} birdies, ${stats.pars} pars, ${stats.bogeys} bogeys, ${stats.doubleBogeyPlus} double+',
      accentColor: const Color(0xFF9D4EDD),
      icon: Icons.analytics_outlined,
    );
  }

  // ===== MISTAKE CARDS =====

  static Widget _buildTotalMistakesCard(RoundAnalysis analysis) {
    return CompactStatCards.buildCountCard(
      label: 'Total Mistakes',
      count: analysis.totalMistakes,
      color: const Color(0xFFFF7A7A),
      icon: Icons.error_outline,
    );
  }

  static Widget _buildDrivingMistakesCard(RoundAnalysis analysis) {
    final count = analysis.mistakesByCategory['driving'] ?? 0;
    return CompactStatCards.buildCountCard(
      label: 'Driving Mistake${count == 1 ? '' : 's'}',
      count: count,
      color: const Color(0xFFFF7A7A),
    );
  }

  static Widget _buildPuttingMistakesCard(RoundAnalysis analysis) {
    final count = analysis.mistakesByCategory['putting'] ?? 0;
    return CompactStatCards.buildCountCard(
      label: 'Putting Mistakes',
      count: count,
      color: const Color(0xFFFF7A7A),
    );
  }

  static Widget _buildApproachMistakesCard(RoundAnalysis analysis) {
    final count = analysis.mistakesByCategory['approach'] ?? 0;
    return CompactStatCards.buildCountCard(
      label: 'Approach Mistakes',
      count: count,
      color: const Color(0xFFFF7A7A),
    );
  }

  // ===== MENTAL GAME CARDS =====

  static Widget _buildBounceBackCard(RoundAnalysis analysis) {
    return CompactStatCards.buildPercentageCard(
      label: 'Bounce Back Rate',
      percentage: analysis.bounceBackPercentage,
      color: const Color(0xFF4CAF50),
      subtitle: 'Recovery from bogeys',
    );
  }

  static Widget _buildHotStreakCard(DGRound round) {
    try {
      final psychStats = locator.get<PsychAnalysisService>().getPsychStats(
        round,
      );
      final birdieTransition = psychStats.transitionMatrix['Birdie'];
      final birdieAfterBirdie = birdieTransition?.toBirdiePercent ?? 0.0;

      return CompactStatCards.buildPercentageCard(
        label: 'Hot Streak',
        percentage: birdieAfterBirdie,
        color: const Color(0xFFFF6B35),
        subtitle: 'Birdie after birdie',
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  static Widget _buildColdStreakCard(DGRound round) {
    try {
      final psychStats = locator.get<PsychAnalysisService>().getPsychStats(
        round,
      );
      final bogeyTransition = psychStats.transitionMatrix['Bogey'];
      final bogeyAfterBogey = bogeyTransition?.bogeyOrWorsePercent ?? 0.0;

      return CompactStatCards.buildPercentageCard(
        label: 'Struggle Rate',
        percentage: bogeyAfterBogey,
        color: const Color(0xFFFFB800),
        subtitle: 'Bogey+ after bogey',
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  // ===== DISC PERFORMANCE CARDS =====

  static Widget _buildTopDiscCard(RoundAnalysis analysis) {
    if (analysis.discPerformances.isEmpty) {
      return const SizedBox.shrink();
    }

    final topDisc = analysis.discPerformances.first;
    return CompactStatCards.buildHighlightCard(
      title: 'Top Disc: ${topDisc.discName}',
      description:
          '${topDisc.totalShots} throws, ${topDisc.goodPercentage.toStringAsFixed(0)}% good',
      accentColor: const Color(0xFF9D4EDD),
      icon: Icons.album_outlined,
    );
  }

  static Widget _buildDiscCountCard(RoundAnalysis analysis) {
    final discCount = analysis.discPerformances.length;
    return CompactStatCards.buildCountCard(
      label: 'Discs Used',
      count: discCount,
      color: const Color(0xFF9D4EDD),
      icon: Icons.disc_full,
    );
  }

  /// Fallback for unknown card IDs
  static Widget _buildUnknownCard(String cardId) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Unknown card: $cardId',
            style: const TextStyle(fontSize: 11, color: Colors.orange),
          ),
        ],
      ),
    );
  }

  /// Get list of all supported card IDs
  static List<String> getSupportedCardIds() {
    return [
      // Putting
      'C1X_PUTTING',
      'C1_PUTTING',
      'C2_PUTTING',
      'PUTTING_COMPARISON',
      // Driving
      'FAIRWAY_HIT',
      'C1_IN_REG',
      'OB_RATE',
      // Scoring
      'BIRDIES',
      'BOGEYS',
      'SCORING_MIX',
      // Mistakes
      'TOTAL_MISTAKES',
      'DRIVING_MISTAKES',
      'PUTTING_MISTAKES',
      'APPROACH_MISTAKES',
      // Mental game
      'BOUNCE_BACK',
      'HOT_STREAK',
      'COLD_STREAK',
      // Disc performance
      'TOP_DISC',
      'DISC_COUNT',
    ];
  }

  /// Get description for a card ID (useful for AI prompts)
  static String getCardDescription(String cardId) {
    switch (cardId.toUpperCase()) {
      // Putting
      case 'C1X_PUTTING':
        return 'C1x putting (12-33ft outer ring): makes/attempts with percentage - THE KEY PUTTING STAT';
      case 'C1_PUTTING':
        return 'C1 putting: makes/attempts with percentage';
      case 'C2_PUTTING':
        return 'C2 putting: makes/attempts with percentage';
      case 'PUTTING_COMPARISON':
        return 'C1 vs C2 putting percentages side-by-side';
      // Driving
      case 'FAIRWAY_HIT':
        return 'Fairway hit percentage';
      case 'C1_IN_REG':
        return 'C1 in regulation percentage (parked opportunities)';
      case 'OB_RATE':
        return 'Out of bounds rate';
      // Scoring
      case 'BIRDIES':
        return 'Total birdies count';
      case 'BOGEYS':
        return 'Total bogeys count';
      case 'SCORING_MIX':
        return 'Scoring breakdown (birdies, pars, bogeys, double+)';
      // Mistakes
      case 'TOTAL_MISTAKES':
        return 'Total mistakes count';
      case 'DRIVING_MISTAKES':
        return 'Driving mistakes count';
      case 'PUTTING_MISTAKES':
        return 'Putting mistakes count';
      case 'APPROACH_MISTAKES':
        return 'Approach mistakes count';
      // Mental game
      case 'BOUNCE_BACK':
        return 'Bounce back rate (recovery from bogeys)';
      case 'HOT_STREAK':
        return 'Hot streak: birdie rate after birdies';
      case 'COLD_STREAK':
        return 'Struggle rate: bogey+ after bogeys';
      // Disc performance
      case 'TOP_DISC':
        return 'Top performing disc with stats';
      case 'DISC_COUNT':
        return 'Number of discs used';
      default:
        return 'Unknown card';
    }
  }
}
