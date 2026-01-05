import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/app_bar/generic_app_bar.dart';
import 'package:turbo_disc_golf/components/stat_cards/disc_performance_story_card.dart';
import 'package:turbo_disc_golf/components/stat_cards/hole_type_story_card.dart';
import 'package:turbo_disc_golf/components/stat_cards/horizontal_driving_stats_card.dart';
import 'package:turbo_disc_golf/components/stat_cards/horizontal_putting_stats_card.dart';
import 'package:turbo_disc_golf/components/stat_cards/mistakes_stats_card.dart';
import 'package:turbo_disc_golf/components/stat_cards/scoring_stats_card.dart';
import 'package:turbo_disc_golf/components/stat_cards/shot_shape_story_card.dart';
import 'package:turbo_disc_golf/components/stat_cards/throw_type_story_card.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/structured_story_content.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/course_tab/score_detail_screen.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/drives_tab/drives_tab.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/mistakes_tab.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/putting_tab.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_story_tab/components/practice_advice_list.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_story_tab/components/story_section_header.dart';
import 'package:turbo_disc_golf/utils/constants/testing_constants.dart';
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
        if (content.strengths.isNotEmpty) ...[
          _buildStrengths(context),
          const SizedBox(height: 12),
        ],
        if (content.weaknesses.isNotEmpty) ...[
          _buildWeaknesses(context),
          const SizedBox(height: 12),
        ],
        if (content.mistakes != null) ...[
          _buildMistakes(context),
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
                          onTap: () => _navigateToDetailScreen(
                            context,
                            highlight.cardId!,
                          ),
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
                          onTap: () => _navigateToDetailScreen(
                            context,
                            highlight.cardId!,
                          ),
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
              GestureDetector(
                onTap: mistakes.cardId != null
                    ? () => _navigateToDetailScreen(context, mistakes.cardId!)
                    : null,
                child: Container(
                  color: Colors.transparent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (mistakes.cardId != null)
                        _buildStatWidget(mistakes.cardId!),
                      if (mistakes.explanation != null) ...[
                        if (mistakes.cardId != null) const SizedBox(height: 12),
                        Text(
                          mistakes.explanation!,
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
                    ? () =>
                        _navigateToDetailScreen(context, opportunity.cardId!)
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (opportunity.cardId != null)
                      _buildStatWidget(opportunity.cardId!),
                    if (opportunity.explanation != null) ...[
                      if (opportunity.cardId != null) const SizedBox(height: 12),
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

  Widget _buildStatWidget(String cardId) {
    // Handle parameterized cards (e.g., DISC_PERFORMANCE:Destroyer)
    if (cardId.startsWith('DISC_PERFORMANCE:')) {
      final String discName = cardId.split(':')[1];
      return DiscPerformanceStoryCard(
        discName: discName,
        round: round,
      );
    }

    if (cardId.startsWith('HOLE_TYPE:')) {
      final String holeType = cardId.split(':')[1]; // "Par 3", "Par 4", "Par 5"
      return HoleTypeStoryCard(
        holeType: holeType,
        round: round,
      );
    }

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

  /// Maps card ID to detail screen widget and title
  ({Widget screen, String title})? _getDetailScreenForCardId(String cardId) {
    // Handle parameterized cards - no specific detail screen yet
    if (cardId.startsWith('DISC_PERFORMANCE:') ||
        cardId.startsWith('HOLE_TYPE:')) {
      return null;
    }

    switch (cardId) {
      // Putting cards -> Putting detail screen
      case 'C1X_PUTTING':
      case 'C1_PUTTING':
      case 'C2_PUTTING':
        return (screen: PuttingTab(round: round), title: 'Putting');

      // Driving cards -> Driving detail screen
      case 'FAIRWAY_HIT':
      case 'C1_IN_REG':
      case 'OB_RATE':
      case 'PARKED':
        return (screen: DrivesTab(round: round), title: 'Driving');

      // Scoring cards -> Score detail screen
      case 'BIRDIES':
      case 'SCORING':
      case 'EAGLES':
      case 'PARS':
        return (screen: ScoreDetailScreen(round: round), title: 'Scores');

      // Mistakes card -> Mistakes detail screen
      case 'MISTAKES':
        return (screen: MistakesTab(round: round), title: 'Mistakes');

      // NEW: Throw type and shot shape -> Drives tab
      case 'THROW_TYPE_COMPARISON':
      case 'SHOT_SHAPE_BREAKDOWN':
        return (screen: DrivesTab(round: round), title: 'Driving');

      default:
        return null;
    }
  }

  /// Navigate to detail screen for the given card ID
  void _navigateToDetailScreen(BuildContext context, String cardId) {
    final detailScreen = _getDetailScreenForCardId(cardId);
    if (detailScreen == null) {
      debugPrint('No detail screen configured for card ID: $cardId');
      return;
    }

    if (!context.mounted) return;

    final Widget screenWithAppBar = _DetailScreenWrapper(
      title: detailScreen.title,
      child: detailScreen.screen,
    );

    if (useCustomPageTransitionsForRoundReview) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              screenWithAppBar,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Fade + scale animation for card expansion effect
            const begin = 0.92;
            const end = 1.0;
            const curve = Curves.easeInOut;

            final tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            final scaleAnimation = animation.drive(tween);

            final fadeAnimation = animation.drive(
              CurveTween(curve: curve),
            );

            return FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(scale: scaleAnimation, child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    } else {
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => screenWithAppBar,
        ),
      );
    }
  }
}

/// Detail Screen Wrapper for V2 navigation
class _DetailScreenWrapper extends StatelessWidget {
  final String title;
  final Widget child;

  const _DetailScreenWrapper({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEEE8F5), // Light gray with faint purple tint
            Color(0xFFECECEE), // Light gray
            Color(0xFFE8F4E8), // Light gray with faint green tint
            Color(0xFFEAE8F0), // Light gray with subtle purple
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GenericAppBar(
          topViewPadding: MediaQuery.of(context).viewPadding.top,
          title: title,
          backgroundColor: Colors.transparent,
        ),
        body: child,
      ),
    );
  }
}
