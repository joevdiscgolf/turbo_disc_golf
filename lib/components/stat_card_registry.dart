import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/compact_stat_cards.dart';
import 'package:turbo_disc_golf/components/stat_cards/birdie_rate_story_card.dart';
import 'package:turbo_disc_golf/components/stat_cards/bogey_rate_story_card.dart';
import 'package:turbo_disc_golf/components/stat_cards/bounce_back_story_card.dart';
import 'package:turbo_disc_golf/components/stat_cards/c1_in_reg_story_card.dart';
import 'package:turbo_disc_golf/components/stat_cards/c1_putting_story_card.dart';
import 'package:turbo_disc_golf/components/stat_cards/c1x_putting_story_card.dart';
import 'package:turbo_disc_golf/components/stat_cards/c2_putting_story_card.dart';
import 'package:turbo_disc_golf/components/stat_cards/fairway_hit_story_card.dart';
import 'package:turbo_disc_golf/components/stat_cards/flow_state_story_card.dart';
import 'package:turbo_disc_golf/components/stat_cards/hot_streak_story_card.dart';
import 'package:turbo_disc_golf/components/stat_cards/mistakes_card.dart';
import 'package:turbo_disc_golf/components/stat_cards/ob_rate_story_card.dart';
import 'package:turbo_disc_golf/components/stat_cards/par_rate_story_card.dart';
import 'package:turbo_disc_golf/components/stat_cards/parked_story_card.dart';
import 'package:turbo_disc_golf/components/stat_cards/skills_score_story_card.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';
import 'package:turbo_disc_golf/models/stat_render_mode.dart';
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
    final String id = cardId.toUpperCase();

    // Check for render mode suffix (_CIRCLE or _BAR)
    StatRenderMode renderMode = StatRenderMode.circle; // Default
    String baseId = id;

    if (id.endsWith('_CIRCLE')) {
      renderMode = StatRenderMode.circle;
      baseId = id.substring(0, id.length - 7); // Remove '_CIRCLE'
    } else if (id.endsWith('_BAR')) {
      renderMode = StatRenderMode.bar;
      baseId = id.substring(0, id.length - 4); // Remove '_BAR'
    }

    // Handle new suffix-based story cards
    switch (baseId) {
      // ===== DRIVING STORY CARDS (with dual rendering) =====
      case 'FAIRWAY_HIT':
        return FairwayHitStoryCard(round: round, renderMode: renderMode);
      case 'C1_IN_REG':
        return C1InRegStoryCard(round: round, renderMode: renderMode);
      case 'OB_RATE':
        return OBRateStoryCard(round: round, renderMode: renderMode);
      case 'PARKED':
        return ParkedStoryCard(round: round, renderMode: renderMode);

      // ===== PUTTING STORY CARDS (with dual rendering) =====
      case 'C1_PUTTING':
        return C1PuttingStoryCard(round: round, renderMode: renderMode);
      case 'C1X_PUTTING':
        return C1XPuttingStoryCard(round: round, renderMode: renderMode);
      case 'C2_PUTTING':
        return C2PuttingStoryCard(round: round, renderMode: renderMode);

      // ===== SCORING STORY CARDS (with dual rendering) =====
      case 'BIRDIE_RATE':
        return BirdieRateStoryCard(round: round, renderMode: renderMode);
      case 'BOGEY_RATE':
        return BogeyRateStoryCard(round: round, renderMode: renderMode);
      case 'PAR_RATE':
        return ParRateStoryCard(round: round, renderMode: renderMode);

      // ===== MENTAL GAME STORY CARDS (with dual rendering) =====
      case 'BOUNCE_BACK':
        return BounceBackStoryCard(round: round, renderMode: renderMode);
      case 'HOT_STREAK':
        return HotStreakStoryCard(round: round, renderMode: renderMode);
      case 'FLOW_STATE':
        return FlowStateStoryCard(round: round, renderMode: renderMode);

      // ===== PERFORMANCE STORY CARDS (with dual rendering) =====
      case 'MISTAKES':
        return MistakesCard(
          round: round,
          compact: true,
          showHeader: false,
          showCard: false,
        );
      case 'SKILLS_SCORE':
        return SkillsScoreStoryCard(round: round, renderMode: renderMode);
    }

    // Fall back to original switch statement for legacy cards
    switch (id) {
      // ===== COMPOSITE STORY CARDS =====
      case 'PUTTING_STATS':
        return _buildPuttingStatsCard(analysis);
      case 'DRIVING_STATS':
        return _buildDrivingStatsCard(analysis);
      case 'SCORE_BREAKDOWN':
        return _buildScoreBreakdownCard(analysis);
      case 'MISTAKES_CHART':
        return _buildMistakesChartCard(analysis);

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

  // ===== COMPOSITE STORY CARDS =====

  /// Comprehensive putting stats card with C1, C1X, and C2
  static Widget _buildPuttingStatsCard(RoundAnalysis analysis) {
    final stats = analysis.puttingStats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            '🥏 Putting Performance',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            CompactStatCards.buildFractionCard(
              label: 'C1 Putts',
              numerator: stats.c1Makes,
              denominator: stats.c1Attempts,
              color: const Color(0xFF137e66),
            ),
            CompactStatCards.buildFractionCard(
              label: 'C1X Putts',
              numerator: stats.c1xMakes,
              denominator: stats.c1xAttempts,
              color: const Color(0xFF4CAF50),
            ),
            CompactStatCards.buildFractionCard(
              label: 'C2 Putts',
              numerator: stats.c2Makes,
              denominator: stats.c2Attempts,
              color: const Color(0xFF2196F3),
            ),
          ],
        ),
      ],
    );
  }

  /// Comprehensive driving stats card
  static Widget _buildDrivingStatsCard(RoundAnalysis analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            '🎯 Driving Performance',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            CompactStatCards.buildPercentageCard(
              label: 'Fairway Hit',
              percentage: analysis.coreStats.fairwayHitPct,
              color: const Color(0xFF4CAF50),
              subtitle: 'Off the tee',
            ),
            CompactStatCards.buildPercentageCard(
              label: 'C1 in Reg',
              percentage: analysis.coreStats.c1InRegPct,
              color: const Color(0xFF137e66),
              subtitle: 'Birdie chances',
            ),
            CompactStatCards.buildPercentageCard(
              label: 'OB Rate',
              percentage: analysis.coreStats.obPct,
              color: const Color(0xFFFF7A7A),
              subtitle: 'Out of bounds',
            ),
            CompactStatCards.buildPercentageCard(
              label: 'Parked',
              percentage: analysis.coreStats.parkedPct,
              color: const Color(0xFFFFA726),
              subtitle: 'Tap-in range',
            ),
          ],
        ),
      ],
    );
  }

  /// Score breakdown card with birdies, pars, bogeys, doubles
  static Widget _buildScoreBreakdownCard(RoundAnalysis analysis) {
    final stats = analysis.scoringStats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            '📊 Score Breakdown',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (stats.eagles > 0)
              CompactStatCards.buildCountCard(
                label: 'Eagles',
                count: stats.eagles,
                color: const Color(0xFF9C27B0),
                icon: Icons.star,
              ),
            CompactStatCards.buildCountCard(
              label: 'Birdies',
              count: stats.birdies,
              color: const Color(0xFF4CAF50),
              icon: Icons.arrow_downward,
            ),
            CompactStatCards.buildCountCard(
              label: 'Pars',
              count: stats.pars,
              color: const Color(0xFF2196F3),
              icon: Icons.horizontal_rule,
            ),
            CompactStatCards.buildCountCard(
              label: 'Bogeys',
              count: stats.bogeys,
              color: const Color(0xFFFFB800),
              icon: Icons.arrow_upward,
            ),
            if (stats.doubleBogeyPlus > 0)
              CompactStatCards.buildCountCard(
                label: 'Double+',
                count: stats.doubleBogeyPlus,
                color: const Color(0xFFFF7A7A),
                icon: Icons.double_arrow,
              ),
          ],
        ),
      ],
    );
  }

  /// Mistakes breakdown chart
  static Widget _buildMistakesChartCard(RoundAnalysis analysis) {
    final mistakesByCategory = analysis.mistakesByCategory;
    final List<MapEntry<String, int>> sortedMistakes = mistakesByCategory.entries
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedMistakes.isEmpty) {
      return CompactStatCards.buildHighlightCard(
        title: 'Perfect Round!',
        description: 'No mistakes detected',
        accentColor: const Color(0xFF4CAF50),
        icon: Icons.check_circle_outline,
      );
    }

    // Map category names to friendly labels
    String getCategoryLabel(String category) {
      switch (category.toLowerCase()) {
        case 'driving':
          return 'Driving Mistakes';
        case 'putting':
          return 'Putting Mistakes';
        case 'approach':
          return 'Approach Mistakes';
        case 'mental':
          return 'Mental Mistakes';
        default:
          return category;
      }
    }

    // Get colors for each category
    Color getCategoryColor(int index) {
      final colors = [
        const Color(0xFFFF7A7A), // Red
        const Color(0xFFFFB800), // Orange
        const Color(0xFF9C27B0), // Purple
        const Color(0xFF2196F3), // Blue
      ];
      return colors[index % colors.length];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            '⚠️ Mistakes Breakdown',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sortedMistakes.asMap().entries.map((entry) {
            final index = entry.key;
            final mistake = entry.value;
            return CompactStatCards.buildCountCard(
              label: getCategoryLabel(mistake.key),
              count: mistake.value,
              color: getCategoryColor(index),
              icon: Icons.warning_amber_rounded,
            );
          }).toList(),
        ),
      ],
    );
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
      // Composite story cards (legacy)
      'PUTTING_STATS',
      'DRIVING_STATS',
      'SCORE_BREAKDOWN',
      'MISTAKES_CHART',

      // Driving story cards (dual rendering with _CIRCLE / _BAR suffix)
      'FAIRWAY_HIT_CIRCLE',
      'FAIRWAY_HIT_BAR',
      'C1_IN_REG_CIRCLE',
      'C1_IN_REG_BAR',
      'OB_RATE_CIRCLE',
      'OB_RATE_BAR',
      'PARKED_CIRCLE',
      'PARKED_BAR',

      // Putting story cards (dual rendering with _CIRCLE / _BAR suffix)
      'C1_PUTTING_CIRCLE',
      'C1_PUTTING_BAR',
      'C1X_PUTTING_CIRCLE',
      'C1X_PUTTING_BAR',
      'C2_PUTTING_CIRCLE',
      'C2_PUTTING_BAR',

      // Scoring story cards (dual rendering with _CIRCLE / _BAR suffix)
      'BIRDIE_RATE_CIRCLE',
      'BIRDIE_RATE_BAR',
      'BOGEY_RATE_CIRCLE',
      'BOGEY_RATE_BAR',
      'PAR_RATE_CIRCLE',
      'PAR_RATE_BAR',

      // Mental game story cards (dual rendering with _CIRCLE / _BAR suffix)
      'BOUNCE_BACK_CIRCLE',
      'BOUNCE_BACK_BAR',
      'HOT_STREAK_CIRCLE',
      'HOT_STREAK_BAR',
      'FLOW_STATE_CIRCLE',
      'FLOW_STATE_BAR',

      // Performance story cards (dual rendering with _CIRCLE / _BAR suffix)
      'MISTAKES_CIRCLE',
      'MISTAKES_BAR',
      'SKILLS_SCORE_CIRCLE',
      'SKILLS_SCORE_BAR',

      // Legacy compact cards (kept for backward compatibility)
      'PUTTING_COMPARISON',
      'BIRDIES',
      'BOGEYS',
      'SCORING_MIX',
      'TOTAL_MISTAKES',
      'DRIVING_MISTAKES',
      'PUTTING_MISTAKES',
      'APPROACH_MISTAKES',
      'COLD_STREAK',
      'TOP_DISC',
      'DISC_COUNT',
    ];
  }

  /// Get description for a card ID (useful for AI prompts)
  static String getCardDescription(String cardId) {
    switch (cardId.toUpperCase()) {
      // Composite story cards
      case 'PUTTING_STATS':
        return 'Comprehensive putting visualization with C1, C1X, and C2 stats';
      case 'DRIVING_STATS':
        return 'Complete driving breakdown: fairway hits, C1 in reg, OB rate, parked';
      case 'SCORE_BREAKDOWN':
        return 'Full scoring distribution: eagles, birdies, pars, bogeys, doubles';
      case 'MISTAKES_CHART':
        return 'Mistakes breakdown by category with counts';
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

      // ===== NEW STORY CARDS WITH DUAL RENDERING =====

      // Driving story cards
      case 'FAIRWAY_HIT_CIRCLE':
      case 'FAIRWAY_HIT_BAR':
        return 'Fairway hit percentage - Shows accuracy off the tee, avoiding trouble';
      case 'C1_IN_REG_CIRCLE':
      case 'C1_IN_REG_BAR':
        return 'C1 in Regulation percentage - Measures birdie opportunity creation';
      case 'OB_RATE_CIRCLE':
      case 'OB_RATE_BAR':
        return 'Out of Bounds rate - Shows penalty avoidance and course management';
      case 'PARKED_CIRCLE':
      case 'PARKED_BAR':
        return 'Parked percentage - Elite accuracy metric for tap-in range shots';

      // Putting story cards
      case 'C1_PUTTING_CIRCLE':
      case 'C1_PUTTING_BAR':
        return 'C1 Putting percentage (0-33 ft) - Overall putting performance inside Circle 1';
      case 'C1X_PUTTING_CIRCLE':
      case 'C1X_PUTTING_BAR':
        return 'C1X Putting percentage (11-33 ft) - Key putting metric excluding gimme putts';
      case 'C2_PUTTING_CIRCLE':
      case 'C2_PUTTING_BAR':
        return 'C2 Putting percentage (33-66 ft) - Long-range putting performance';

      // Scoring story cards
      case 'BIRDIE_RATE_CIRCLE':
      case 'BIRDIE_RATE_BAR':
        return 'Birdie Rate percentage - Shows scoring aggression and success';
      case 'BOGEY_RATE_CIRCLE':
      case 'BOGEY_RATE_BAR':
        return 'Bogey Rate percentage - Indicates error frequency and consistency';
      case 'PAR_RATE_CIRCLE':
      case 'PAR_RATE_BAR':
        return 'Par Rate percentage - Measures consistency and solid performance';

      // Mental game story cards
      case 'BOUNCE_BACK_CIRCLE':
      case 'BOUNCE_BACK_BAR':
        return 'Bounce Back Rate - Recovery rate after bogeys, shows mental resilience';
      case 'HOT_STREAK_CIRCLE':
      case 'HOT_STREAK_BAR':
        return 'Hot Streak Energy - Birdie-after-birdie rate, shows scoring momentum';
      case 'FLOW_STATE_CIRCLE':
      case 'FLOW_STATE_BAR':
        return 'Flow State percentage - Time spent in peak performance zones';

      // Performance story cards
      case 'MISTAKES_CIRCLE':
      case 'MISTAKES_BAR':
        return 'Total Mistakes count - Overall error frequency across all categories';
      case 'SKILLS_SCORE_CIRCLE':
      case 'SKILLS_SCORE_BAR':
        return 'Overall Skills Score (0-100) - Comprehensive performance rating';

      default:
        return 'Unknown card';
    }
  }
}
