import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/components/stat_card_registry.dart';
import 'package:turbo_disc_golf/components/story/story_callout_card.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/round_story_v2_content.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_story_tab/components/practice_advice_list.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_story_tab/components/story_section_header.dart';
import 'package:turbo_disc_golf/services/round_analysis_generator.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/string_helpers.dart';

/// V2 Story Renderer: Narrative paragraphs with inline callout cards
class StructuredStoryRendererV2 extends StatelessWidget {
  const StructuredStoryRendererV2({
    super.key,
    required this.content,
    required this.round,
    this.tabController,
  });

  final RoundStoryV2Content content;
  final DGRound round;
  final TabController? tabController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeadline(context),
        const SizedBox(height: 12),

        // Main story paragraphs with callouts
        ..._buildStoryParagraphs(context),

        // What Could Have Been section
        const SizedBox(height: 12),
        _buildWhatCouldHaveBeen(context),

        // Optional: Practice advice
        if (content.practiceAdvice.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildPracticeAdvice(context),
        ],

        // Optional: Strategy tips
        if (content.strategyTips.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildStrategyTips(context),
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
                  color: const Color(0xFF6366F1),
                  fontSize: 22,
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

  List<Widget> _buildStoryParagraphs(BuildContext context) {
    final List<Widget> widgets = [];
    final RoundAnalysis analysis = RoundAnalysisGenerator.generateAnalysis(round);

    for (int i = 0; i < content.story.length; i++) {
      final StoryParagraph paragraph = content.story[i];

      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Card(
            elevation: 1,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Paragraph text
                  Text(
                    paragraph.text,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),

                  // Callout cards (0-2 per paragraph)
                  ...paragraph.callouts.map((callout) {
                    final Widget? statWidget = _buildStatWidget(callout.cardId, analysis);
                    if (statWidget == null) {
                      debugPrint('⚠️  Unknown cardId: ${callout.cardId}');
                      return const SizedBox.shrink();
                    }

                    return InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        // TODO: Add navigation to detail screen if needed
                      },
                      child: StoryCalloutCard(
                        statWidget: statWidget,
                        reason: callout.reason,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildWhatCouldHaveBeen(BuildContext context) {
    final WhatCouldHaveBeenV2 data = content.whatCouldHaveBeen;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF6366F1).withValues(alpha: 0.05),
                const Color(0xFF8B5CF6).withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StorySectionHeader(
                  title: 'What Could Have Been',
                  icon: Icons.insights,
                  accentColor: const Color(0xFF6366F1),
                ),
                const SizedBox(height: 16),

                // Current vs Potential Score
                _buildScoreComparison(data.currentScore, data.potentialScore),

                const SizedBox(height: 16),

                // Improvement scenarios
                ...data.scenarios.map((scenario) => _buildScenarioRow(scenario)),

                // Encouragement message
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: Color(0xFF6366F1),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data.encouragement,
                          style: const TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreComparison(String current, String potential) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildScoreBox('Current Score', current, TurbColors.gray[600]!),
        Icon(Icons.arrow_forward, color: TurbColors.gray[400]),
        _buildScoreBox('Potential Score', potential, const Color(0xFF4CAF50)),
      ],
    );
  }

  Widget _buildScoreBox(String label, String score, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: TurbColors.gray[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          score,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildScenarioRow(ImprovementScenarioV2 scenario) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scenario.fix,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Result: ${scenario.resultScore} (${scenario.strokesSaved} strokes saved)',
                  style: TextStyle(
                    fontSize: 12,
                    color: TurbColors.gray[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeAdvice(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StorySectionHeader(
                title: 'Practice Focus',
                icon: Icons.sports_handball,
                accentColor: const Color(0xFFFFA726),
              ),
              const SizedBox(height: 12),
              PracticeAdviceList(advice: content.practiceAdvice),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStrategyTips(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StorySectionHeader(
                title: 'Strategy Tips',
                icon: Icons.psychology,
                accentColor: const Color(0xFF2196F3),
              ),
              const SizedBox(height: 12),
              PracticeAdviceList(advice: content.strategyTips),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildStatWidget(String cardId, RoundAnalysis analysis) {
    try {
      return StatCardRegistry.buildCard(
        cardId,
        round,
        analysis,
      );
    } catch (e) {
      debugPrint('Failed to build stat widget for cardId: $cardId - $e');
      return null;
    }
  }
}
