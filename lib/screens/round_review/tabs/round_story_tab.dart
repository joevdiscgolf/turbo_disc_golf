import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/ai_content_renderer.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/ai_content_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_story_tab/structured_story_renderer.dart';
import 'package:turbo_disc_golf/services/gemini_service.dart';
import 'package:turbo_disc_golf/services/round_analysis_generator.dart';
import 'package:turbo_disc_golf/services/round_storage_service.dart';
import 'package:turbo_disc_golf/services/story_generator_service.dart';

/// AI narrative story tab that tells the story of your round
/// with embedded visualizations and insights
class RoundStoryTab extends StatefulWidget {
  final DGRound round;

  const RoundStoryTab({super.key, required this.round});

  @override
  State<RoundStoryTab> createState() => _RoundStoryTabState();
}

class _RoundStoryTabState extends State<RoundStoryTab>
    with AutomaticKeepAliveClientMixin {
  late DGRound _currentRound;
  late RoundAnalysis _analysis;
  bool _isGenerating = false;
  String? _errorMessage;

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

  Future<void> _generateStory() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      // Get services
      final GeminiService geminiService = locator.get<GeminiService>();
      final StoryGeneratorService storyService = StoryGeneratorService(
        geminiService,
      );

      // Generate story
      final AIContent? story = await storyService.generateRoundStory(
        widget.round,
      );

      if (story == null) {
        throw Exception('Failed to generate story content');
      }

      // Update round with new story
      final RoundStorageService storageService = locator
          .get<RoundStorageService>();
      final DGRound updatedRound = _currentRound.copyWith(aiSummary: story);
      await storageService.saveRound(updatedRound);

      if (mounted) {
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isGenerating)
              _buildLoadingState(context)
            else if (_errorMessage != null)
              _buildErrorState(context)
            else if (_currentRound.aiSummary != null &&
                _currentRound.aiSummary!.content.isNotEmpty) ...[
              _buildRegenerateButton(),
              const SizedBox(height: 8),
              _buildStoryContent(context, _analysis),
            ] else
              _buildEmptyState(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Generating your round story...',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This may take a few moments',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
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

  Widget _buildRegenerateButton() {
    // Only show in debug mode
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.centerRight,
      child: OutlinedButton.icon(
        onPressed: _isGenerating ? null : _generateStory,
        icon: const Icon(Icons.refresh, size: 16),
        label: const Text('Regenerate (Debug)'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(fontSize: 12),
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
        // Render structured story if available (new format)
        if (story?.structuredContent != null)
          StructuredStoryRenderer(
            content: story!.structuredContent!,
            round: _currentRound,
          )
        // Fallback: render old format with AIContentRenderer
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
