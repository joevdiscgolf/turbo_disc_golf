import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/what_could_have_been_card.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/mistakes_detail/components/all_mistakes_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/mistakes_detail/components/mistakes_bar_chart_card.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/services/round_analysis/mistakes_analysis_service.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

class MistakesDetailScreen extends StatelessWidget {
  static const String screenName = 'Mistakes Detail';

  final DGRound round;

  const MistakesDetailScreen({super.key, required this.round});

  @override
  Widget build(BuildContext context) {
    // Track screen impression
    WidgetsBinding.instance.addPostFrameCallback((_) {
      locator.get<LoggingService>().track(
        'Screen Impression',
        properties: {'screen_name': MistakesDetailScreen.screenName},
      );
    });

    final MistakesAnalysisService mistakesAnalysisService = locator
        .get<MistakesAnalysisService>();

    final totalMistakes = mistakesAnalysisService.getTotalMistakesCount(round);
    final mistakeTypes = mistakesAnalysisService.getMistakeTypes(round);
    final mistakeDetails = mistakesAnalysisService.getMistakeThrowDetails(
      round,
    );

    // Calculate current score
    final int currentScore = round.holes.fold<int>(
      0,
      (sum, hole) => sum + hole.relativeHoleScore,
    );

    if (totalMistakes == 0) {
      return const Center(child: Text('No mistakes detected'));
    }

    return Container(
      color: SenseiColors.gray[50],
      child: ListView(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 80,
        ),
        children: addRunSpacing(
          [
            // Mistakes breakdown card (bar chart only, not expandable)
            MistakesBarChartCard(
              totalMistakes: totalMistakes,
              mistakeTypes: mistakeTypes,
            ),
            // View all mistakes card (expandable)
            AllMistakesCard(mistakeDetails: mistakeDetails),
            // What Could Have Been section (V3 design)
            _buildWhatCouldHaveBeen(currentScore, mistakeTypes),
          ],
          runSpacing: 8,
          axis: Axis.vertical,
        ),
      ),
    );
  }

  Widget _buildWhatCouldHaveBeen(int currentScore, List<dynamic> mistakeTypes) {
    // Filter out mistakes with count > 0
    final List<dynamic> nonZeroMistakes = mistakeTypes
        .where((mistake) => mistake.count > 0)
        .toList();

    if (nonZeroMistakes.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate total mistakes for "perfect round" scenario
    final int totalMistakeCount = nonZeroMistakes.fold(
      0,
      (sum, mistake) => sum + (mistake.count as int),
    );

    // Build scenarios list
    final List<WhatCouldHaveBeenScenario> scenarios = nonZeroMistakes.map((
      mistake,
    ) {
      final int mistakeCount = mistake.count;
      final String mistakeLabel = mistake.label;
      final int potentialScore = currentScore - mistakeCount;
      final String improvementLabel = _getImprovementLabel(mistakeLabel);

      return WhatCouldHaveBeenScenario(
        fix: improvementLabel,
        resultScore: _formatScore(potentialScore),
        strokesSaved: mistakeCount.toString(),
      );
    }).toList();

    return WhatCouldHaveBeenCard(
      currentScore: _formatScore(currentScore),
      potentialScore: _formatScore(currentScore - totalMistakeCount),
      scenarios: scenarios,
    );
  }

  String _formatScore(int score) {
    if (score == 0) return 'E';
    return score > 0 ? '+$score' : '$score';
  }

  String _getImprovementLabel(String mistakeLabel) {
    // Convert mistake labels to positive improvement actions (shortened)
    if (mistakeLabel.toLowerCase().contains('missed c1x')) {
      return 'Make C1X putts';
    } else if (mistakeLabel.toLowerCase().contains('missed c2')) {
      return 'Make C2 putts';
    } else if (mistakeLabel.toLowerCase().contains('missed c1 ')) {
      return 'Make C1 putts';
    } else if (mistakeLabel.toLowerCase().contains('ob tee')) {
      return 'Eliminate OB drives';
    } else if (mistakeLabel.toLowerCase().contains('ob')) {
      return 'Eliminate OB throws';
    } else if (mistakeLabel.toLowerCase().contains('3-putt')) {
      return 'Eliminate 3-putts';
    } else if (mistakeLabel.toLowerCase().contains('roll away')) {
      return 'Prevent roll aways';
    } else if (mistakeLabel.toLowerCase().contains('hit first available')) {
      return 'Hit first available';
    } else {
      // Default: remove "missed" or "failed" and make positive
      return mistakeLabel
          .replaceAll('Missed', 'Make')
          .replaceAll('missed', 'make')
          .replaceAll('Failed', 'Complete')
          .replaceAll('failed', 'complete');
    }
  }
}
