import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/components/what_could_have_been_card.dart';
import 'package:turbo_disc_golf/components/stat_card_registry.dart';
import 'package:turbo_disc_golf/components/stat_cards/disc_performance_story_card.dart';
import 'package:turbo_disc_golf/components/stat_cards/hole_type_story_card.dart';
import 'package:turbo_disc_golf/components/stat_cards/mistakes_card.dart';
import 'package:turbo_disc_golf/components/stat_cards/scoring_stats_card.dart';
import 'package:turbo_disc_golf/components/stat_cards/shot_shape_story_card.dart';
import 'package:turbo_disc_golf/components/stat_cards/throw_type_story_card.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/models/data/structured_story_content.dart';
import 'package:turbo_disc_golf/services/round_analysis_generator.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_story_tab/components/practice_advice_list.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_story_tab/components/story_section_header.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_story_tab/story_navigation_helper.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/constants/naming_constants.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/utils/string_helpers.dart';

/// Renderer for structured story content with specific sections
///
/// Displays structured AI coaching in organized sections:
/// 1. Round Overview (context setting)
/// 2. What You Did Well (strengths with stat cards)
/// 3. What Cost You Strokes (weaknesses with stat cards)
/// 4. Biggest Opportunity (emphasized single focus)
/// 5. Practice & Strategy (actionable advice)
class StructuredStoryRenderer extends StatelessWidget {
  const StructuredStoryRenderer({
    super.key,
    required this.content,
    required this.round,
    this.tabController,
  });

  final StructuredStoryContent content;
  final DGRound round;
  final TabController? tabController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeadline(context),
        const SizedBox(height: 12),
        // What Could Have Been - After headline (from AI data)
        if (locator.get<FeatureFlagService>().showWhatCouldHaveBeenCard && content.whatCouldHaveBeen != null) ...[
          WhatCouldHaveBeenCard(data: content.whatCouldHaveBeen!),
          const SizedBox(height: 12),
        ],
        if (content.strengths.isNotEmpty) ...[
          _buildStrengths(context),
          const SizedBox(height: 12),
        ],
        // Merged: weaknesses + mistakes in a single cohesive section
        if (content.weaknesses.isNotEmpty || content.mistakes != null) ...[
          _buildWeaknesses(context),
          const SizedBox(height: 12),
        ],
        // Blow-up breakdown (calculated from round data)
        if (_hasBlowUpHoles) ...[
          _buildBlowUpBreakdown(context),
          const SizedBox(height: 12),
        ],
        if (content.biggestOpportunity != null) ...[
          _buildOpportunity(context),
          const SizedBox(height: 12),
        ],
        if (content.practiceAdvice.isNotEmpty) ...[
          _buildPractice(context),
          const SizedBox(height: 12),
        ],
        if (content.strategyTips.isNotEmpty) ...[
          _buildStrategy(context),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildHeadline(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content.roundTitle.capitalizeFirst(),
                style: kStorySectionHeaderStyle.copyWith(
                  color: const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                content.overview,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStrengths(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StorySectionHeader(
                title: 'What you did well',
                icon: Icons.trending_up,
                accentColor: const Color(0xFF4CAF50),
              ),
              const SizedBox(height: 16),
              ...content.strengths.map(
                (highlight) => Padding(
                  padding: EdgeInsets.only(
                    bottom: highlight != content.strengths.last ? 20 : 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Optional sub-headline
                      if (highlight.headline != null) ...[
                        Text(
                          highlight.headline!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Widget (if cardId present)
                      if (highlight.cardId != null) ...[
                        InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            StoryNavigationHelper.navigateToDetailScreen(
                              context,
                              highlight.cardId!,
                              round,
                            );
                          },
                          child: _buildStatWidget(highlight.cardId!),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Explanation text
                      if (highlight.explanation != null)
                        Text(
                          highlight.explanation!,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeaknesses(BuildContext context) {
    final StoryHighlight? mistakes = content.mistakes;
    final bool hasMistakes = mistakes != null;
    final bool hasWeaknesses = content.weaknesses.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StorySectionHeader(
                title: 'What cost you strokes',
                icon: Icons.trending_down,
                accentColor: const Color(0xFFFF7A7A),
              ),
              const SizedBox(height: 16),

              // Compact mistakes bar chart summary at top
              if (hasMistakes) ...[
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    StoryNavigationHelper.navigateToDetailScreen(
                      context,
                      'MISTAKES',
                      round,
                    );
                  },
                  child: MistakesCard(
                    round: round,
                    compact: true,
                    showHeader: false,
                    showCard: false,
                  ),
                ),
                if (hasWeaknesses) const SizedBox(height: 16),
              ],

              // Detailed weakness highlights
              ...content.weaknesses.map(
                (highlight) => Padding(
                  padding: EdgeInsets.only(
                    bottom: highlight != content.weaknesses.last ? 20 : 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Optional sub-headline
                      if (highlight.headline != null) ...[
                        Text(
                          highlight.headline!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Widget (if cardId present)
                      if (highlight.cardId != null) ...[
                        InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            StoryNavigationHelper.navigateToDetailScreen(
                              context,
                              highlight.cardId!,
                              round,
                            );
                          },
                          child: _buildStatWidget(highlight.cardId!),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Explanation text
                      if (highlight.explanation != null)
                        Text(
                          highlight.explanation!,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOpportunity(BuildContext context) {
    final opportunity = content.biggestOpportunity!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StorySectionHeader(
                title: 'Where to improve',
                icon: Icons.stars,
                accentColor: const Color(0xFFFFA726),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: opportunity.cardId != null
                    ? () {
                        HapticFeedback.lightImpact();
                        StoryNavigationHelper.navigateToDetailScreen(
                          context,
                          opportunity.cardId!,
                          round,
                        );
                      }
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (opportunity.cardId != null)
                      _buildStatWidget(opportunity.cardId!),
                    if (opportunity.explanation != null) ...[
                      if (opportunity.cardId != null)
                        const SizedBox(height: 12),
                      Text(
                        opportunity.explanation!,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPractice(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StorySectionHeader(
                title: 'Practice focus',
                icon: Icons.emoji_objects,
                accentColor: const Color(0xFF2196F3),
              ),
              const SizedBox(height: 16),
              PracticeAdviceList(advice: content.practiceAdvice),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStrategy(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StorySectionHeader(
                title: 'Strategy tips',
                icon: Icons.psychology,
                accentColor: const Color(0xFF9C27B0),
              ),
              const SizedBox(height: 16),
              PracticeAdviceList(advice: content.strategyTips),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // BLOW-UP & ELITE POTENTIAL SECTIONS (Calculated from round data)
  // ============================================================================

  /// Returns true if there are any blow-up holes (double bogey or worse)
  bool get _hasBlowUpHoles => round.holes.any((h) => h.holeScore - h.par >= 2);

  /// Get all blow-up holes (double bogey or worse)
  List<DGHole> get _blowUpHoles =>
      round.holes.where((h) => h.holeScore - h.par >= 2).toList();

  Widget _buildBlowUpBreakdown(BuildContext context) {
    final List<DGHole> blowUps = _blowUpHoles;
    if (blowUps.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StorySectionHeader(
                title: 'Blow-up breakdown',
                icon: Icons.warning_amber_rounded,
                accentColor: const Color(0xFFE53935),
              ),
              const SizedBox(height: 16),
              ...blowUps.map((hole) => _buildBlowUpHoleCard(hole)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlowUpHoleCard(DGHole hole) {
    final int strokesLost = hole.holeScore - hole.par;
    final String scoreName = _getScoreName(strokesLost);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0E0E0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with hole info
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${hole.number}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD32F2F),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hole ${hole.number}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '$scoreName (+$strokesLost)',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFD32F2F),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+$strokesLost',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD32F2F),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 12),
            // Throw sequence
            ...hole.throws.asMap().entries.map((entry) {
              final int index = entry.key;
              final DiscThrow throw_ = entry.value;
              final String throwText = throw_.rawText?.isNotEmpty == true
                  ? throw_.rawText!
                  : _formatThrowStructured(throw_);
              final bool hasPenalty = throw_.penaltyStrokes > 0;
              final bool isLastThrow = index == hole.throws.length - 1;

              return Padding(
                padding: EdgeInsets.only(bottom: isLastThrow ? 0 : 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Throw number with icon
                    SizedBox(
                      width: 28,
                      child: Icon(
                        _getThrowPurposeIcon(throw_.purpose),
                        size: 16,
                        color: hasPenalty
                            ? const Color(0xFFE53935)
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Throw details
                    Expanded(
                      child: Text(
                        throwText,
                        style: TextStyle(
                          fontSize: 13,
                          color: hasPenalty
                              ? const Color(0xFFD32F2F)
                              : Colors.black87,
                          fontWeight: hasPenalty
                              ? FontWeight.w500
                              : FontWeight.normal,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _getScoreName(int relativeToPar) {
    switch (relativeToPar) {
      case 2:
        return 'Double Bogey';
      case 3:
        return 'Triple Bogey';
      case 4:
        return 'Quadruple Bogey';
      default:
        return '+$relativeToPar';
    }
  }

  String _formatThrowStructured(DiscThrow throw_) {
    final List<String> parts = [];

    // Disc name - use 'Putter' as fallback for putts, 'Unknown disc' otherwise
    String disc;
    if (throw_.discName != null) {
      disc = throw_.discName!;
    } else if (throw_.purpose == ThrowPurpose.putt) {
      disc = 'Putter';
    } else {
      disc = 'Unknown disc';
    }
    parts.add(disc);

    // Technique in parentheses (using short names for compact display)
    if (throw_.technique != null) {
      final String technique =
          throwTechniqueToShortName[throw_.technique] ?? throw_.technique!.name;
      parts.add('($technique)');
    }

    // Landing spot with arrow (using short names for compact display)
    if (throw_.landingSpot != null) {
      final String landing =
          landingSpotToShortName[throw_.landingSpot] ??
          throw_.landingSpot!.name;
      parts.add('→ $landing');
    }

    // Penalty strokes
    if (throw_.penaltyStrokes > 0) {
      parts.add('(+${throw_.penaltyStrokes} penalty)');
    }

    return parts.join(' ');
  }

  IconData _getThrowPurposeIcon(ThrowPurpose? purpose) {
    switch (purpose) {
      case ThrowPurpose.teeDrive:
        return Icons.sports_golf;
      case ThrowPurpose.fairwayDrive:
        return Icons.trending_flat;
      case ThrowPurpose.approach:
        return Icons.call_made;
      case ThrowPurpose.putt:
        return Icons.flag;
      case ThrowPurpose.scramble:
        return Icons.refresh;
      case ThrowPurpose.penalty:
        return Icons.warning;
      default:
        return Icons.sports;
    }
  }

  Widget _buildStatWidget(String cardId) {
    // Handle parameterized cards (e.g., DISC_PERFORMANCE:Destroyer)
    if (cardId.startsWith('DISC_PERFORMANCE:')) {
      final String discName = cardId.split(':')[1];
      return DiscPerformanceStoryCard(discName: discName, round: round);
    }

    if (cardId.startsWith('HOLE_TYPE:')) {
      final String holeType = cardId.split(':')[1]; // "Par 3", "Par 4", "Par 5"
      return HoleTypeStoryCard(holeType: holeType, round: round);
    }

    // NEW: Check if this is one of the new suffix-based story cards
    // (ends with _CIRCLE or _BAR) OR if it's a base card ID that maps to a new widget
    final List<String> newFocusedCardIds = [
      'FAIRWAY_HIT',
      'C1_IN_REG',
      'OB_RATE',
      'PARKED',
      'C1_PUTTING',
      'C1X_PUTTING',
      'C2_PUTTING',
      'BIRDIE_RATE',
      'BOGEY_RATE',
      'PAR_RATE',
      'BOUNCE_BACK',
      'HOT_STREAK',
      'FLOW_STATE',
      'MISTAKES',
      'SKILLS_SCORE',
    ];

    // Check if this is a new focused card (with or without suffix)
    String cardIdToUse = cardId;
    if (cardId.endsWith('_CIRCLE') || cardId.endsWith('_BAR')) {
      // Already has suffix, use as-is
      cardIdToUse = cardId;
    } else if (newFocusedCardIds.contains(cardId)) {
      // Base card ID without suffix - default to BAR mode (horizontal)
      cardIdToUse = '${cardId}_BAR';
    }

    // Try to build using StatCardRegistry for new focused widgets
    if (cardIdToUse.endsWith('_CIRCLE') || cardIdToUse.endsWith('_BAR')) {
      final analysis = RoundAnalysisGenerator.generateAnalysis(round);
      final Widget? widget = StatCardRegistry.buildCard(
        cardIdToUse,
        round,
        analysis,
      );
      if (widget != null) {
        return widget;
      }
    }

    // Map card IDs to appropriate stat widgets (legacy behavior for old composite cards)
    switch (cardId) {
      // Scoring cards - show scoring distribution
      case 'BIRDIES':
      case 'SCORING':
      case 'EAGLES':
      case 'PARS':
        return ScoringStatsCard(round: round);

      // NEW: Throw type comparison
      case 'THROW_TYPE_COMPARISON':
        return ThrowTypeStoryCard(round: round);

      // NEW: Shot shape breakdown
      case 'SHOT_SHAPE_BREAKDOWN':
        return ShotShapeStoryCard(round: round);

      // Fallback: simple placeholder for unsupported card types
      default:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Stat: $cardId',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        );
    }
  }
}
