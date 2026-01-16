import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/components/stat_card_registry.dart';
import 'package:turbo_disc_golf/components/story/story_callout_card.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/round_story_v2_content.dart';
import 'package:turbo_disc_golf/models/round_analysis.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_story_tab/components/practice_advice_list.dart';
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
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              content.roundTitle.capitalizeFirst(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6366F1),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Overview
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              content.overview,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Main story paragraphs with callouts
          ..._buildStoryParagraphs(context),

          // What Could Have Been section (integrated)
          _buildWhatCouldHaveBeen(context),

          // Practice advice (integrated)
          if (content.practiceAdvice.isNotEmpty)
            _buildPracticeAdvice(context),

          // Strategy tips (integrated)
          if (content.strategyTips.isNotEmpty)
            _buildStrategyTips(context),
        ],
      ),
    );
  }


  List<Widget> _buildStoryParagraphs(BuildContext context) {
    final List<Widget> widgets = [];
    final RoundAnalysis analysis = RoundAnalysisGenerator.generateAnalysis(round);

    for (int i = 0; i < content.story.length; i++) {
      final StoryParagraph paragraph = content.story[i];

      // Add paragraph text with horizontal padding
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            paragraph.text,
            style: const TextStyle(
              fontSize: 15,
              height: 1.7,
              color: Colors.black87,
            ),
          ),
        ),
      );

      // Add spacing after paragraph
      widgets.add(const SizedBox(height: 16));

      // Add callout cards (0-2 per paragraph) - with 16px horizontal padding
      for (final callout in paragraph.callouts) {
        final Widget? statWidget = _buildStatWidget(callout.cardId, analysis);
        if (statWidget == null) {
          debugPrint('⚠️  Unknown cardId: ${callout.cardId}');
          continue;
        }

        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                // TODO: Add navigation to detail screen if needed
              },
              child: StoryCalloutCard(
                statWidget: statWidget,
                reason: callout.reason,
              ),
            ),
          ),
        );
        widgets.add(const SizedBox(height: 16));
      }
    }

    return widgets;
  }

  Widget _buildWhatCouldHaveBeen(BuildContext context) {
    final WhatCouldHaveBeenV2 data = content.whatCouldHaveBeen;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Divider
          Container(
            height: 1,
            color: TurbColors.gray[200],
            margin: const EdgeInsets.symmetric(vertical: 24),
          ),

          // Section header
          Row(
            children: [
              const Icon(
                Icons.insights,
                color: Color(0xFF6366F1),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'What Could Have Been',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6366F1),
                ),
              ),
            ],
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
              color: const Color(0xFF6366F1).withValues(alpha: 0.08),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Divider
          Container(
            height: 1,
            color: TurbColors.gray[200],
            margin: const EdgeInsets.symmetric(vertical: 24),
          ),

          // Section header
          Row(
            children: [
              const Icon(
                Icons.sports_handball,
                color: Color(0xFFFFA726),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Practice Focus',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFA726),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PracticeAdviceList(advice: content.practiceAdvice),
        ],
      ),
    );
  }

  Widget _buildStrategyTips(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Divider
          Container(
            height: 1,
            color: TurbColors.gray[200],
            margin: const EdgeInsets.symmetric(vertical: 24),
          ),

          // Section header
          Row(
            children: [
              const Icon(
                Icons.psychology,
                color: Color(0xFF2196F3),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Strategy Tips',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2196F3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PracticeAdviceList(advice: content.strategyTips),
        ],
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
