import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/ai_content_renderer.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/components/custom_markdown_content.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_story_tab/structured_story_renderer.dart';
import 'package:turbo_disc_golf/services/round_analysis_generator.dart';

class AiSummaryTab extends StatelessWidget {
  final DGRound round;
  final TabController? tabController;

  const AiSummaryTab({super.key, required this.round, this.tabController});

  @override
  Widget build(BuildContext context) {
    // Generate analysis if we have AI content with segments
    final analysis =
        (round.aiSummary != null && round.aiSummary!.segments != null)
        ? RoundAnalysisGenerator.generateAnalysis(round)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (round.aiSummary != null &&
              round.aiSummary!.content.isNotEmpty) ...[
            Row(
              children: [
                Image.asset(
                  'assets/mascots/turbo_mascot.png',
                  width: 60,
                  height: 60,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Here\'s your round analysis and coaching!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (round.isAISummaryOutdated)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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
                          'This summary is out of date with the current round',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: round.aiSummary?.structuredContent != null
                    ? StructuredStoryRenderer(
                        content: round.aiSummary!.structuredContent!,
                        round: round,
                        tabController: tabController,
                      )
                    : (analysis != null
                          ? AIContentRenderer(
                              aiContent: round.aiSummary!,
                              round: round,
                              analysis: analysis,
                            )
                          : CustomMarkdownContent(
                              data: round.aiSummary!.content,
                            )),
              ),
            ),
          ] else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No AI summary available for this round',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI summaries are generated automatically for new rounds',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
