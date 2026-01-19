import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/components/mistakes_bar_chart_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/components/potential_score_card.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/services/round_analysis/mistakes_analysis_service.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

class MistakesTab extends StatelessWidget {
  static const String screenName = 'Mistakes';
  static const String tabName = 'Mistakes';

  final DGRound round;

  const MistakesTab({super.key, required this.round});

  @override
  Widget build(BuildContext context) {
    // Track screen impression
    WidgetsBinding.instance.addPostFrameCallback((_) {
      locator.get<LoggingService>().track('Screen Impression', properties: {
        'screen_name': MistakesTab.screenName,
        'screen_class': 'MistakesTab',
        'tab_name': MistakesTab.tabName,
      });
    });

    final MistakesAnalysisService mistakesAnalysisService = locator
        .get<MistakesAnalysisService>();

    final totalMistakes = mistakesAnalysisService.getTotalMistakesCount(round);
    // final mistakesByCategory = mistakesAnalysisService.getMistakesByCategory(
    //   round,
    // );
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

    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 80),
      children: addRunSpacing(
        [
          // New bar chart design with expandable all mistakes list
          MistakesBarChartCard(
            totalMistakes: totalMistakes,
            mistakeTypes: mistakeTypes,
            mistakeDetails: mistakeDetails,
          ),
          // New potential score card (V2)
          PotentialScoreCard(
            currentScore: currentScore,
            mistakeTypes: mistakeTypes,
          ),
          // Old design (commented out) - uncomment to revert
          // _buildMistakeKPIs(context, totalMistakes, mistakesByCategory),
          // _buildWhatCouldHaveBeen(context),
          // _buildMistakeBreakdown(context, mistakeTypes, totalMistakes),
          // _buildMistakesList(context, mistakeDetails), // Now inside expandable card
        ],
        runSpacing: 16,
        axis: Axis.vertical,
      ),
    );
  }
}
