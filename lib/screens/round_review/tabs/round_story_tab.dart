import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:turbo_disc_golf/components/ai_content_renderer.dart';
import 'package:turbo_disc_golf/components/buttons/primary_button.dart';
import 'package:turbo_disc_golf/components/story/story_highlights_share_card.dart';
import 'package:turbo_disc_golf/components/story/story_poster_share_card.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/ai_content_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/round_story_v2_content.dart';
import 'package:turbo_disc_golf/models/data/structured_story_content.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';
import 'package:turbo_disc_golf/screens/round_review/share_story_preview_screen.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_story_tab/story_loading_animation.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_story_tab/structured_story_renderer.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_story_tab/structured_story_renderer_v2.dart';
import 'package:turbo_disc_golf/services/round_analysis_generator.dart';
import 'package:turbo_disc_golf/services/round_storage_service.dart';
import 'package:turbo_disc_golf/services/share_service.dart';
import 'package:turbo_disc_golf/services/story_generator_service.dart';
import 'package:turbo_disc_golf/state/round_review_cubit.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/constants/testing_constants.dart';
import 'package:turbo_disc_golf/utils/navigation_helpers.dart';

/// AI narrative story tab that tells the story of your round
/// with embedded visualizations and insights
class RoundStoryTab extends StatefulWidget {
  final DGRound round;
  final TabController? tabController;

  const RoundStoryTab({super.key, required this.round, this.tabController});

  @override
  State<RoundStoryTab> createState() => _RoundStoryTabState();
}

class _RoundStoryTabState extends State<RoundStoryTab>
    with AutomaticKeepAliveClientMixin {
  late DGRound _currentRound;
  late RoundAnalysis _analysis;
  bool _isGenerating = false;
  String? _errorMessage;

  // Share card key for capturing as image
  final GlobalKey _shareCardKey = GlobalKey();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Initialize local state with widget round
    _currentRound = widget.round;
    // Cache analysis to avoid regenerating on every build
    _analysis = RoundAnalysisGenerator.generateAnalysis(_currentRound);
  }

  @override
  void didUpdateWidget(RoundStoryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync with parent widget's round if it changed (e.g., from Firestore update)
    if (oldWidget.round != widget.round) {
      setState(() {
        _currentRound = widget.round;
        _analysis = RoundAnalysisGenerator.generateAnalysis(_currentRound);
      });
    }
  }

  Future<void> _generateStory() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      // Get service from locator
      final StoryGeneratorService storyService =
          locator.get<StoryGeneratorService>();

      // Generate story based on feature flag
      final AIContent? story = storyV2Enabled
          ? await storyService.generateRoundStoryV2(_currentRound)  // V2
          : await storyService.generateRoundStory(_currentRound);   // V1

      if (story == null) {
        throw Exception('Failed to generate story content');
      }

      // Update round with new story
      final RoundStorageService storageService = locator
          .get<RoundStorageService>();
      final DGRound updatedRound = _currentRound.copyWith(aiSummary: story);
      await storageService.saveRound(updatedRound);

      if (mounted) {
        // Update the RoundReviewCubit so it knows about the new story
        // This ensures the updated round is available when switching tabs
        try {
          final RoundReviewCubit? reviewCubit = context
              .read<RoundReviewCubit?>();
          reviewCubit?.updateRoundData(updatedRound);
        } catch (e) {
          // Cubit might not be available in all contexts (e.g., standalone usage)
          debugPrint('RoundReviewCubit not available: $e');
        }

        setState(() {
          _isGenerating = false;
          _currentRound =
              updatedRound; // Update local state to trigger UI rebuild
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _errorMessage = 'Failed to generate story: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Full-screen loading state (no scroll wrapper)
    if (_isGenerating || showStoryLoadingAnimation) {
      return const StoryLoadingAnimation();
    }

    final bool hasStory = _currentRound.aiSummary != null &&
        _currentRound.aiSummary!.content.isNotEmpty;

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
      child: hasStory ? _buildContentWithShareBar(context) : _buildScrollableContent(context),
    );
  }

  Widget _buildScrollableContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_errorMessage != null)
            _buildErrorState(context)
          else
            _buildEmptyState(context),
        ],
      ),
    );
  }

  /// Extract share data with V2/V1 fallback logic
  (String, String, String?) _getShareData() {
    final AIContent? aiSummary = _currentRound.aiSummary;

    if (aiSummary == null) {
      return ('Round Story', '', null);
    }

    // Check V2 first (current branch)
    if (aiSummary.structuredContentV2 != null) {
      final RoundStoryV2Content v2 = aiSummary.structuredContentV2!;
      return (v2.roundTitle, v2.overview, v2.shareableHeadline);
    }

    // Fall back to V1
    if (aiSummary.structuredContent != null) {
      final StructuredStoryContent v1 = aiSummary.structuredContent!;
      return (v1.roundTitle, v1.overview, v1.shareableHeadline);
    }

    // No story data available
    return ('Round Story', '', null);
  }

  Widget _buildContentWithShareBar(BuildContext context) {
    return Stack(
      children: [
        // Scrollable content
        Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 12, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRegenerateButton(),
                    const SizedBox(height: 8),
                    _buildStoryContent(context, _analysis),
                  ],
                ),
              ),
            ),
            // Fixed bottom action bar
            _buildShareActionBar(),
          ],
        ),
        // Hidden share card for capture (using Offstage)
        Offstage(
          offstage: true,
          child: RepaintBoundary(
            key: _shareCardKey,
            child: _buildShareCard(),
          ),
        ),
      ],
    );
  }

  Widget _buildShareCard() {
    final (roundTitle, overview, shareableHeadline) = _getShareData();

    if (useStoryPosterShareCard) {
      return StoryPosterShareCard(
        round: _currentRound,
        analysis: _analysis,
        roundTitle: roundTitle,
        overview: overview,
        shareableHeadline: shareableHeadline,
        shareHighlightStats: null, // V2 doesn't use shareHighlightStats yet
      );
    } else {
      return StoryHighlightsShareCard(
        round: _currentRound,
        analysis: _analysis,
        roundTitle: roundTitle,
        overview: overview,
        shareableHeadline: shareableHeadline,
        shareHighlightStats: null, // V2 doesn't use shareHighlightStats yet
      );
    }
  }

  Future<void> _shareStoryCard() async {
    final (roundTitle, _, _) = _getShareData();
    final ShareService shareService = locator.get<ShareService>();

    final String caption =
        '\u{1F4D6} $roundTitle\n\n${_currentRound.courseName}\nShared from Turbo Disc Golf';

    final bool success = await shareService.captureAndShare(
      _shareCardKey,
      caption: caption,
      filename: 'round_story',
    );

    if (!success && mounted) {
      Clipboard.setData(ClipboardData(text: caption));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard! Ready to share.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showShareCardPreview() {
    final (roundTitle, overview, shareableHeadline) = _getShareData();

    pushCupertinoRoute(
      context,
      ShareStoryPreviewScreen(
        round: _currentRound,
        analysis: _analysis,
        roundTitle: roundTitle,
        overview: overview,
        shareableHeadline: shareableHeadline,
        shareHighlightStats: null, // V2 doesn't use shareHighlightStats yet
      ),
      pushFromBottom: true,
    );
  }

  Widget _buildShareActionBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Preview button
          Expanded(
            child: PrimaryButton(
              width: double.infinity,
              height: 56,
              label: 'Preview',
              backgroundColor: Colors.white,
              labelColor: TurbColors.gray[800]!,
              iconColor: TurbColors.gray[800]!,
              borderColor: TurbColors.gray[100],
              onPressed: _showShareCardPreview,
            ),
          ),
          const SizedBox(width: 8),
          // Share button (primary gradient)
          Expanded(
            flex: 2,
            child: PrimaryButton(
              width: double.infinity,
              height: 56,
              label: 'Share my story',
              icon: Icons.ios_share,
              gradientBackground: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              onPressed: _shareStoryCard,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to generate story',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _generateStory,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No story available yet',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Generate an AI-powered narrative that tells the story of your round with embedded visualizations and insights.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _generateStory,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate Story'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDebugYamlOutput() {
    final String? rawContent = _currentRound.aiSummary?.content;
    if (rawContent == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raw YAML Output'),
        content: SingleChildScrollView(
          child: SelectableText(
            rawContent,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: rawContent));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildRegenerateButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onLongPress: kDebugMode ? _showDebugYamlOutput : null,
          child: OutlinedButton.icon(
            onPressed: _isGenerating ? null : _generateStory,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Regenerate'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoryContent(BuildContext context, RoundAnalysis analysis) {
    // Check if content is outdated
    if (_currentRound.isAISummaryOutdated) {
      return Column(
        children: [
          _buildOutdatedWarning(context),
          const SizedBox(height: 8),
          _buildContentCard(context, analysis),
        ],
      );
    }

    return _buildContentCard(context, analysis);
  }

  Widget _buildOutdatedWarning(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'This story is out of date with the current round',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
          TextButton(
            onPressed: _generateStory,
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(BuildContext context, RoundAnalysis analysis) {
    final AIContent? story = _currentRound.aiSummary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // V2: Render if structuredContentV2 exists
        if (story?.structuredContentV2 != null)
          StructuredStoryRendererV2(
            content: story!.structuredContentV2!,
            round: _currentRound,
            tabController: widget.tabController,
          )
        // V1: Render if structuredContent exists
        else if (story?.structuredContent != null)
          StructuredStoryRenderer(
            content: story!.structuredContent!,
            round: _currentRound,
            tabController: widget.tabController,
          )
        // Old format: render with AIContentRenderer
        else if (story?.segments != null)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AIContentRenderer(
                aiContent: story!,
                round: _currentRound,
                analysis: analysis,
              ),
            ),
          )
        // Final fallback: plain markdown
        else
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                story?.content ?? 'No story available',
                style: const TextStyle(fontSize: 16, height: 1.6),
              ),
            ),
          ),
      ],
    );
  }

  // List<String> _getKeyMoments(RoundAnalysis analysis) {
  //   final List<String> moments = [];

  //   // Check for significant achievements
  //   if (analysis.scoringStats.eagles > 0) {
  //     moments.add('${analysis.scoringStats.eagles} eagle${analysis.scoringStats.eagles > 1 ? 's' : ''}!');
  //   }

  //   // Check for bounce backs
  //   if (analysis.bounceBackPercentage > 50) {
  //     moments.add('Strong mental game with ${analysis.bounceBackPercentage.toStringAsFixed(0)}% bounce back rate');
  //   }

  //   // Check for birdie performance
  //   if (analysis.scoringStats.birdies > 3) {
  //     moments.add('${analysis.scoringStats.birdies} birdies recorded');
  //   }

  //   return moments.take(3).toList();
  // }

  // Widget _buildQuickStatsOverview(BuildContext context, RoundAnalysis analysis) {
  //   final int coursePar = _currentRound.holes.fold(0, (sum, hole) => sum + hole.par);
  //   final int totalScore = _currentRound.holes.fold(0, (sum, hole) => sum + hole.holeScore);

  //   return Card(
  //     elevation: 1,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     child: Padding(
  //       padding: const EdgeInsets.all(12),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             'Quick Stats',
  //             style: Theme.of(context).textTheme.titleSmall?.copyWith(
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //           ),
  //           const SizedBox(height: 12),
  //           StatPillRow(
  //             pills: [
  //               InlineStatPill(
  //                 label: 'Score',
  //                 value: '$totalScore',
  //                 color: _getScoreColor(totalScore, coursePar),
  //                 icon: Icons.golf_course,
  //               ),
  //               InlineStatPill(
  //                 label: 'Birdies',
  //                 value: '${analysis.scoringStats.birdies}',
  //                 color: const Color(0xFF4CAF50),
  //                 icon: Icons.trending_up,
  //               ),
  //               InlineStatPill(
  //                 label: 'Pars',
  //                 value: '${analysis.scoringStats.pars}',
  //                 color: const Color(0xFF2196F3),
  //                 icon: Icons.check_circle_outline,
  //               ),
  //               if (analysis.totalMistakes > 0)
  //                 InlineStatPill(
  //                   label: 'Mistakes',
  //                   value: '${analysis.totalMistakes}',
  //                   color: const Color(0xFFFF7A7A),
  //                   icon: Icons.warning_amber_rounded,
  //                 ),
  //             ],
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildPerformanceSummary(BuildContext context, RoundAnalysis analysis) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       StorySectionHeader(
  //         title: 'Performance Highlights',
  //         icon: Icons.insights,
  //         accentColor: const Color(0xFF2196F3),
  //       ),
  //       const SizedBox(height: 8),
  //       Card(
  //         elevation: 2,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(16),
  //         ),
  //         child: Padding(
  //           padding: const EdgeInsets.all(16),
  //           child: Column(
  //             children: [
  //               MiniStatCardRow(
  //                 stats: [
  //                   MiniStat(
  //                     label: 'C1 in Reg',
  //                     percentage: analysis.coreStats.c1InRegPct,
  //                     color: const Color(0xFF137e66),
  //                   ),
  //                   MiniStat(
  //                     label: 'C1 Putting',
  //                     percentage: analysis.puttingStats.c1Percentage,
  //                     color: const Color(0xFF4CAF50),
  //                   ),
  //                   MiniStat(
  //                     label: 'Fairway',
  //                     percentage: analysis.coreStats.fairwayHitPct,
  //                     color: const Color(0xFF2196F3),
  //                   ),
  //                 ],
  //                 roundId: _currentRound.id,
  //               ),
  //               const SizedBox(height: 16),
  //               // Key achievements or areas for improvement
  //               if (analysis.scoringStats.eagles > 0)
  //                 KeyMomentHighlight(
  //                   title: 'Eagle Achievement',
  //                   description: 'You scored ${analysis.scoringStats.eagles} eagle${analysis.scoringStats.eagles > 1 ? 's' : ''} this round - exceptional performance!',
  //                   type: MomentType.achievement,
  //                 ),
  //               if (analysis.bounceBackPercentage > 50)
  //                 Padding(
  //                   padding: const EdgeInsets.only(top: 8),
  //                   child: KeyMomentHighlight(
  //                     title: 'Mental Resilience',
  //                     description: 'You bounced back ${analysis.bounceBackPercentage.toStringAsFixed(0)}% of the time after a mistake, showing strong mental game!',
  //                     type: MomentType.bounceBack,
  //                   ),
  //                 ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // Color _getScoreColor(int score, int par) {
  //   final int relative = score - par;
  //   if (relative <= -2) return const Color(0xFF9C27B0); // Purple
  //   if (relative == -1) return const Color(0xFF4CAF50); // Green
  //   if (relative == 0) return const Color(0xFF2196F3); // Blue
  //   if (relative == 1) return const Color(0xFFFFB800); // Yellow
  //   return const Color(0xFFFF7A7A); // Red
  // }
}
