import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/stat_cards/horizontal_driving_stats_card.dart';
import 'package:turbo_disc_golf/components/stat_cards/horizontal_putting_stats_card.dart';
import 'package:turbo_disc_golf/components/stat_cards/mistakes_stats_card.dart';
import 'package:turbo_disc_golf/components/stat_cards/scoring_stats_card.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/structured_story_content.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_story_tab/components/practice_advice_list.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_story_tab/components/story_section_header.dart';

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
        const SizedBox(height: 8),
        if (content.strengths.isNotEmpty) ...[
          _buildStrengths(context),
          const SizedBox(height: 8),
        ],
        if (content.weaknesses.isNotEmpty) ...[
          _buildWeaknesses(context),
          const SizedBox(height: 8),
        ],
        if (content.mistakes != null) ...[
          _buildMistakes(context),
          const SizedBox(height: 8),
        ],
        if (content.biggestOpportunity != null) ...[
          _buildOpportunity(context),
          const SizedBox(height: 8),
        ],
        if (content.practiceAdvice.isNotEmpty) ...[
          _buildPractice(context),
          const SizedBox(height: 8),
        ],
        if (content.strategyTips.isNotEmpty) ...[
          _buildStrategy(context),
          const SizedBox(height: 8),
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
                content.roundTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF137e66),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                content.overview,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
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
                    bottom: highlight != content.strengths.last ? 16 : 0,
                  ),
                  child: InkWell(
                    onTap: () =>
                        _navigateToStatsTab(context, highlight.targetTab),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatWidget(highlight.cardId),
                        if (highlight.explanation != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            highlight.explanation!,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ],
                    ),
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
              ...content.weaknesses.map(
                (highlight) => Padding(
                  padding: EdgeInsets.only(
                    bottom: highlight != content.weaknesses.last ? 16 : 0,
                  ),
                  child: InkWell(
                    onTap: () =>
                        _navigateToStatsTab(context, highlight.targetTab),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatWidget(highlight.cardId),
                        if (highlight.explanation != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            highlight.explanation!,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMistakes(BuildContext context) {
    final mistakes = content.mistakes!;
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
                title: 'Key mistakes',
                icon: Icons.warning_rounded,
                accentColor: const Color(0xFFFF7A7A),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _navigateToStatsTab(context, mistakes.targetTab),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatWidget(mistakes.cardId),
                    if (mistakes.explanation != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        mistakes.explanation!,
                        style: const TextStyle(
                          fontSize: 15,
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
                onTap: () =>
                    _navigateToStatsTab(context, opportunity.targetTab),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatWidget(opportunity.cardId),
                    if (opportunity.explanation != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        opportunity.explanation!,
                        style: const TextStyle(
                          fontSize: 15,
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

  Widget _buildStatWidget(String cardId) {
    // Map card IDs to appropriate stat widgets
    switch (cardId) {
      // Putting cards - show horizontal compact putting stats
      case 'C1X_PUTTING':
      case 'C1_PUTTING':
      case 'C2_PUTTING':
        return HorizontalPuttingStatsCard(round: round);

      // Driving cards - show horizontal compact driving stats
      case 'FAIRWAY_HIT':
      case 'C1_IN_REG':
      case 'OB_RATE':
      case 'PARKED':
        return HorizontalDrivingStatsCard(round: round);

      // Scoring cards - show scoring distribution
      case 'BIRDIES':
      case 'SCORING':
      case 'EAGLES':
      case 'PARS':
        return ScoringStatsCard(round: round);

      // Mistakes card - show mistakes breakdown
      case 'MISTAKES':
        return MistakesStatsCard(round: round);

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

  void _navigateToStatsTab(BuildContext context, String? targetTab) {
    if (targetTab == null || tabController == null) return;

    // Map target tab string to tab index
    const Map<String, int> tabMapping = {
      'putting': 5,
      'driving': 4,
      'drives': 4,
      'mistakes': 7,
      'mental': 8,
      'psych': 8,
      'discs': 6,
      'scores': 3,
      'scoring': 3,
      'overview': 0,
      'skills': 1,
      'course': 2,
      'summary': 9,
      'coach': 10,
    };

    final int? tabIndex = tabMapping[targetTab.toLowerCase()];
    if (tabIndex == null) {
      debugPrint('Unknown target tab: $targetTab');
      return;
    }

    // Check if tab index is valid for current controller
    // If out of bounds, navigate to Overview tab (index 0) instead
    final int targetIndex = tabIndex >= tabController!.length ? 0 : tabIndex;

    // Navigate to the target tab
    tabController!.animateTo(targetIndex);
  }
}
