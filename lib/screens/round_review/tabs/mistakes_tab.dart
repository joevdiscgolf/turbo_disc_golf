import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/components/mistakes_bar_chart_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/components/potential_score_card.dart';
import 'package:turbo_disc_golf/services/round_analysis/mistakes_analysis_service.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

class MistakesTab extends StatelessWidget {
  final DGRound round;

  const MistakesTab({super.key, required this.round});

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 80),
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

  // Widget _buildMistakeKPIs(
  //   BuildContext context,
  //   int totalMistakes,
  //   Map<String, int> mistakesByCategory,
  // ) {
  //   final drivingPct = totalMistakes > 0
  //       ? (mistakesByCategory['driving']! / totalMistakes) * 100
  //       : 0.0;
  //   final approachPct = totalMistakes > 0
  //       ? (mistakesByCategory['approach']! / totalMistakes) * 100
  //       : 0.0;
  //   final puttingPct = totalMistakes > 0
  //       ? (mistakesByCategory['putting']! / totalMistakes) * 100
  //       : 0.0;

  //   return Card(
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             'Mistake Overview',
  //             style: Theme.of(
  //               context,
  //             ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
  //           ),
  //           const SizedBox(height: 16),
  //           Center(
  //             child: Column(
  //               children: [
  //                 Text(
  //                   '$totalMistakes',
  //                   style: Theme.of(context).textTheme.displaySmall?.copyWith(
  //                     fontWeight: FontWeight.bold,
  //                     color: const Color(0xFFFF7A7A),
  //                   ),
  //                 ),
  //                 Text(
  //                   'Total Mistakes',
  //                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
  //                     color: Theme.of(context).colorScheme.onSurfaceVariant,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //           const SizedBox(height: 16),
  //           Wrap(
  //             spacing: 12,
  //             runSpacing: 12,
  //             children: [
  //               _buildCategoryChip(
  //                 context,
  //                 'Driving',
  //                 '${drivingPct.toStringAsFixed(0)}%',
  //                 const Color(0xFF2196F3),
  //               ),
  //               _buildCategoryChip(
  //                 context,
  //                 'Approach',
  //                 '${approachPct.toStringAsFixed(0)}%',
  //                 const Color(0xFFFFA726),
  //               ),
  //               _buildCategoryChip(
  //                 context,
  //                 'Putting',
  //                 '${puttingPct.toStringAsFixed(0)}%',
  //                 const Color(0xFF9C27B0),
  //               ),
  //             ],
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildCategoryChip(
  //   BuildContext context,
  //   String label,
  //   String value,
  //   Color color,
  // ) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //     decoration: BoxDecoration(
  //       color: color.withValues(alpha: 0.1),
  //       borderRadius: BorderRadius.circular(8),
  //       border: Border.all(color: color.withValues(alpha: 0.3)),
  //     ),
  //     child: Column(
  //       children: [
  //         Text(
  //           value,
  //           style: Theme.of(context).textTheme.titleLarge?.copyWith(
  //             fontWeight: FontWeight.bold,
  //             color: color,
  //           ),
  //         ),
  //         const SizedBox(height: 4),
  //         Text(
  //           label,
  //           style: Theme.of(context).textTheme.bodySmall?.copyWith(
  //             color: Theme.of(context).colorScheme.onSurfaceVariant,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildMistakeBreakdown(
  //   BuildContext context,
  //   List<dynamic> mistakeTypes,
  //   int totalMistakes,
  // ) {
  //   final topMistakes = mistakeTypes.take(5).toList();

  //   return Card(
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             'Most Common Mistakes',
  //             style: Theme.of(
  //               context,
  //             ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
  //           ),
  //           const SizedBox(height: 16),
  //           ...topMistakes.map((mistake) {
  //             final percentage = totalMistakes > 0
  //                 ? (mistake.count / totalMistakes) * 100
  //                 : 0.0;

  //             return Padding(
  //               padding: const EdgeInsets.only(bottom: 12),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Row(
  //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                     children: [
  //                       Expanded(
  //                         child: Text(
  //                           mistake.label,
  //                           style: Theme.of(context).textTheme.bodyMedium,
  //                         ),
  //                       ),
  //                       Text(
  //                         '${mistake.count} (${percentage.toStringAsFixed(0)}%)',
  //                         style: Theme.of(context).textTheme.bodyMedium
  //                             ?.copyWith(fontWeight: FontWeight.bold),
  //                       ),
  //                     ],
  //                   ),
  //                   const SizedBox(height: 4),
  //                   ClipRRect(
  //                     borderRadius: BorderRadius.circular(4),
  //                     child: LinearProgressIndicator(
  //                       value: percentage / 100,
  //                       minHeight: 12,
  //                       backgroundColor: const Color(
  //                         0xFFFF7A7A,
  //                       ).withValues(alpha: 0.2),
  //                       valueColor: const AlwaysStoppedAnimation<Color>(
  //                         Color(0xFFFF7A7A),
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             );
  //           }),
  //           if (topMistakes.isNotEmpty)
  //             Padding(
  //               padding: const EdgeInsets.only(top: 8),
  //               child: Card(
  //                 color: Theme.of(context).colorScheme.errorContainer,
  //                 child: Padding(
  //                   padding: const EdgeInsets.all(12),
  //                   child: Row(
  //                     children: [
  //                       Icon(
  //                         Icons.priority_high,
  //                         color: Theme.of(context).colorScheme.onErrorContainer,
  //                         size: 20,
  //                       ),
  //                       const SizedBox(width: 8),
  //                       Expanded(
  //                         child: Text(
  //                           'Most common mistake: ${topMistakes.first.label}',
  //                           style: Theme.of(context).textTheme.bodySmall
  //                               ?.copyWith(
  //                                 color: Theme.of(
  //                                   context,
  //                                 ).colorScheme.onErrorContainer,
  //                                 fontWeight: FontWeight.bold,
  //                               ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildMistakesList(
  //   BuildContext context,
  //   List<Map<String, dynamic>> mistakes,
  // ) {
  //   return Card(
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             'All Mistakes',
  //             style: Theme.of(
  //               context,
  //             ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
  //           ),
  //           const SizedBox(height: 16),
  //           ...mistakes.map((mistake) {
  //             final holeNumber = mistake['holeNumber'];
  //             final throwIndex = mistake['throwIndex'];
  //             final DiscThrow discThrow = mistake['throw'];
  //             final label = mistake['label'];

  //             final List<String> subtitleParts = [];
  //             subtitleParts.add('Hole $holeNumber, Shot ${throwIndex + 1}');
  //             if (discThrow.distanceFeetBeforeThrow != null) {
  //               subtitleParts.add('${discThrow.distanceFeetBeforeThrow} ft');
  //             }

  //             return Card(
  //               margin: const EdgeInsets.only(bottom: 8),
  //               color: Theme.of(
  //                 context,
  //               ).colorScheme.errorContainer.withValues(alpha: 0.3),
  //               child: ListTile(
  //                 leading: CircleAvatar(
  //                   backgroundColor: const Color(0xFFFF7A7A),
  //                   child: Text(
  //                     '$holeNumber',
  //                     style: const TextStyle(
  //                       color: Colors.white,
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                   ),
  //                 ),
  //                 title: Text(
  //                   label,
  //                   style: const TextStyle(fontWeight: FontWeight.bold),
  //                 ),
  //                 subtitle: Text(subtitleParts.join(' • ')),
  //                 trailing: const Icon(Icons.chevron_right),
  //                 onTap: () {
  //                   // todo: Navigate to throw detail view
  //                 },
  //               ),
  //             );
  //           }),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildWhatCouldHaveBeen(BuildContext context) {
  //   final scenarios = _calculateScenarios();

  //   if (scenarios.isEmpty) {
  //     return const SizedBox.shrink();
  //   }

  //   final currentScore = round.holes.fold<int>(
  //     0,
  //     (sum, hole) => sum + hole.relativeHoleScore,
  //   );
  //   final currentScoreStr = currentScore >= 0
  //       ? '+$currentScore'
  //       : '$currentScore';

  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         'What Could Have Been',
  //         style: Theme.of(
  //           context,
  //         ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
  //       ),
  //       const SizedBox(height: 16),
  //       Card(
  //         child: Padding(
  //           padding: const EdgeInsets.all(16),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   Text(
  //                     'Your Score',
  //                     style: Theme.of(context).textTheme.bodyMedium?.copyWith(
  //                       color: Theme.of(context).colorScheme.onSurfaceVariant,
  //                     ),
  //                   ),
  //                   Text(
  //                     currentScoreStr,
  //                     style: Theme.of(context).textTheme.headlineMedium
  //                         ?.copyWith(
  //                           fontWeight: FontWeight.bold,
  //                           color: currentScore < 0
  //                               ? const Color(0xFF137e66)
  //                               : currentScore > 0
  //                               ? const Color(0xFFFF7A7A)
  //                               : Theme.of(context).colorScheme.onSurface,
  //                         ),
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(height: 16),
  //               const Divider(),
  //               ...scenarios.map((scenario) {
  //                 return Padding(
  //                   padding: const EdgeInsets.symmetric(vertical: 8),
  //                   child: ImprovementScenarioItem(
  //                     scenario: scenario,
  //                     currentScore: currentScore,
  //                   ),
  //                 );
  //               }),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // List<ImprovementScenario> _calculateScenarios() {
  //   final scenarios = <ImprovementScenario>[];

  //   // Scenario 1: Clean Up C1X - count missed putts from 11-33 feet
  //   final puttingService = locator.get<PuttingAnalysisService>();
  //   final allPutts = puttingService.getPuttAttempts(round);

  //   // Get all C1X putts (11-33 feet) that were missed
  //   final missedC1xPutts = allPutts.where((putt) {
  //     final distance = putt['distance'] as double?;
  //     final made = putt['made'] as bool? ?? false;
  //     return distance != null && distance >= 11 && distance <= 33 && !made;
  //   }).toList();

  //   if (missedC1xPutts.isNotEmpty) {
  //     // Count missed C1X putts per hole
  //     final missedPuttsPerHole = <int, int>{};
  //     for (final putt in missedC1xPutts) {
  //       final holeNumber = putt['holeNumber'] as int?;
  //       if (holeNumber != null) {
  //         missedPuttsPerHole[holeNumber] =
  //             (missedPuttsPerHole[holeNumber] ?? 0) + 1;
  //       }
  //     }

  //     // Get unique holes where C1X putts were missed
  //     final c1xMissedHoles = <DGHole>[];
  //     for (final holeNumber in missedPuttsPerHole.keys) {
  //       final hole = round.holes.firstWhere((h) => h.number == holeNumber);
  //       c1xMissedHoles.add(hole);
  //     }

  //     scenarios.add(
  //       ImprovementScenario(
  //         title: 'Clean Up C1X Putts',
  //         description: 'Make your putts from 11-33 feet (Circle 1 extended)',
  //         strokesSaved: missedC1xPutts.length,
  //         category: 'Easy Wins',
  //         emoji: '🎯',
  //         affectedHoles: c1xMissedHoles,
  //         getImprovementLabel: (hole) {
  //           final count = missedPuttsPerHole[hole.number] ?? 1;
  //           return count > 1 ? 'Make C1X ($count misses)' : 'Make C1X';
  //         },
  //       ),
  //     );
  //   }

  //   // Scenario 2: Eliminate Disasters - turn double bogeys+ into bogeys
  //   final disasterHoles = round.holes
  //       .where((h) => h.relativeHoleScore >= 2)
  //       .toList();
  //   if (disasterHoles.isNotEmpty) {
  //     final strokesSaved = disasterHoles.fold<int>(
  //       0,
  //       (sum, hole) =>
  //           sum + (hole.relativeHoleScore - 1), // Convert to bogey (+1)
  //     );
  //     scenarios.add(
  //       ImprovementScenario(
  //         title: 'Eliminate Disasters',
  //         description: 'Limit damage on blow-up holes to single bogeys',
  //         strokesSaved: strokesSaved,
  //         category: 'Mental Game',
  //         emoji: '🧠',
  //         affectedHoles: disasterHoles,
  //         getImprovementLabel: (hole) => hole.relativeHoleScore == 2
  //             ? 'Dbl→Bogey'
  //             : '+${hole.relativeHoleScore}→Bogey',
  //       ),
  //     );
  //   }

  //   // Scenario 3: Perfect Scrambling - holes where they went off fairway and made bogey+
  //   final missedScrambles = <DGHole>[];
  //   for (final hole in round.holes) {
  //     bool wentOffFairway = false;

  //     // Check if any throw went off fairway
  //     for (final discThrow in hole.throws) {
  //       if (discThrow.landingSpot == LandingSpot.offFairway) {
  //         wentOffFairway = true;
  //         break;
  //       }
  //     }

  //     // If they went off fairway and made bogey or worse
  //     if (wentOffFairway && hole.relativeHoleScore > 0) {
  //       missedScrambles.add(hole);
  //     }
  //   }

  //   if (missedScrambles.isNotEmpty) {
  //     final strokesSaved = missedScrambles.fold<int>(
  //       0,
  //       (sum, hole) => sum + hole.relativeHoleScore, // Convert to par (0)
  //     );
  //     scenarios.add(
  //       ImprovementScenario(
  //         title: 'Perfect Scrambling',
  //         description: 'Save par when you go off fairway with good short game',
  //         strokesSaved: strokesSaved,
  //         category: 'Short Game',
  //         emoji: '🎲',
  //         affectedHoles: missedScrambles,
  //         getImprovementLabel: (hole) => hole.relativeHoleScore == 1
  //             ? 'Bogey→Par'
  //             : '+${hole.relativeHoleScore}→Par',
  //       ),
  //     );
  //   }

  //   // Sort by strokes saved (biggest impact first)
  //   scenarios.sort((a, b) => b.strokesSaved.compareTo(a.strokesSaved));

  //   return scenarios;
  // }
}
