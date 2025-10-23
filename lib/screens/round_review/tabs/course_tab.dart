import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/hole_breakdown_list.dart';
import 'package:turbo_disc_golf/components/improvement_scenario.dart';
import 'package:turbo_disc_golf/components/improvement_scenario_item.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/services/round_analysis/putting_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_analysis/score_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_statistics_service.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

class CourseTab extends StatelessWidget {
  final DGRound round;

  const CourseTab({super.key, required this.round});

  @override
  Widget build(BuildContext context) {
    // Use cached analysis if available, otherwise compute live
    final analysis = round.analysis;
    final statsService = RoundStatisticsService(round);

    final scoringStats =
        analysis?.scoringStats ??
        locator.get<ScoreAnalysisService>().getScoringStats(round);
    statsService.getBounceBackPercentage();
    final birdieRateByPar =
        analysis?.birdieRateByPar ?? statsService.getBirdieRateByPar();
    final birdieRateByLength =
        analysis?.birdieRateByLength ??
        statsService.getBirdieRateByHoleLength();
    final avgBirdieDistance =
        analysis?.avgBirdieHoleDistance ??
        statsService.getAverageBirdieHoleDistance();

    // New statistics
    final performanceByPar = statsService.getPerformanceByPar();
    final c1c2ByLength = statsService.getC1C2ByHoleLength();
    final performanceByFairwayWidth = statsService
        .getPerformanceByFairwayWidth();

    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 80),
      children: addRunSpacing(
        [
          // _buildScoreSummary(context, totalScore, scoringStats, bounceBackPct),
          _buildScoreDistribution(context, scoringStats),
          _buildWhatCouldHaveBeen(context),
          _buildPerformanceByPar(context, performanceByPar),
          _buildBirdieTrends(
            context,
            birdieRateByPar,
            birdieRateByLength,
            avgBirdieDistance,
            c1c2ByLength,
          ),
          _buildPerformanceByFairwayWidth(context, performanceByFairwayWidth),
        ],
        runSpacing: 16,
        axis: Axis.vertical,
      ),
    );
  }

  // Widget _buildScoreSummary(
  //   BuildContext context,
  //   int totalScore,
  //   ScoringStats scoringStats,
  //   double bounceBackPct,
  // ) {
  //   final scoreColor = totalScore < 0
  //       ? const Color(0xFF137e66)
  //       : totalScore > 0
  //       ? const Color(0xFFFF7A7A)
  //       : const Color(0xFFF5F5F5);

  //   final hasEagles = scoringStats.eagles > 0;

  //   return Card(
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             'Round Summary',
  //             style: Theme.of(
  //               context,
  //             ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
  //           ),
  //           const SizedBox(height: 16),
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceAround,
  //             children: [
  //               _buildKPI(
  //                 context,
  //                 'Score',
  //                 totalScore >= 0 ? '+$totalScore' : '$totalScore',
  //                 scoreColor,
  //               ),
  //               if (hasEagles)
  //                 _buildKPI(
  //                   context,
  //                   scoringStats.eagles == 1 ? 'Eagle' : 'Eagles',
  //                   '${scoringStats.eagles}',
  //                   const Color(0xFFFFD700),
  //                 ),
  //               _buildKPI(
  //                 context,
  //                 scoringStats.birdies == 1 ? 'Birdie' : 'Birdies',
  //                 '${scoringStats.birdies}',
  //                 const Color(0xFF137e66),
  //               ),
  //               _buildKPI(
  //                 context,
  //                 scoringStats.pars == 1 ? 'Par' : 'Pars',
  //                 '${scoringStats.pars}',
  //                 Colors.grey,
  //               ),
  //             ],
  //           ),
  //           const SizedBox(height: 16),
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceAround,
  //             children: [
  //               _buildKPI(
  //                 context,
  //                 scoringStats.bogeys == 1 ? 'Bogey' : 'Bogeys',
  //                 '${scoringStats.bogeys}',
  //                 const Color(0xFFFF7A7A),
  //               ),
  //               _buildKPI(
  //                 context,
  //                 'Double Bogey+',
  //                 '${scoringStats.doubleBogeyPlus}',
  //                 const Color(0xFFD32F2F),
  //               ),
  //             ],
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildKPI(
  //   BuildContext context,
  //   String label,
  //   String value,
  //   Color color,
  // ) {
  //   return Column(
  //     children: [
  //       Text(
  //         value,
  //         style: Theme.of(context).textTheme.headlineMedium?.copyWith(
  //           fontWeight: FontWeight.bold,
  //           color: color,
  //         ),
  //       ),
  //       const SizedBox(height: 4),
  //       Text(
  //         label,
  //         style: Theme.of(context).textTheme.bodySmall?.copyWith(
  //           color: Theme.of(context).colorScheme.onSurfaceVariant,
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildScoreDistribution(BuildContext context, scoringStats) {
    final totalHoles =
        scoringStats.birdies +
        scoringStats.pars +
        scoringStats.bogeys +
        scoringStats.doubleBogeyPlus;

    // Group holes by score type
    final birdieHoles = round.holes
        .where((h) => h.relativeHoleScore < 0)
        .toList();
    final parHoles = round.holes
        .where((h) => h.relativeHoleScore == 0)
        .toList();
    final bogeyHoles = round.holes
        .where((h) => h.relativeHoleScore == 1)
        .toList();
    final doublePlusHoles = round.holes
        .where((h) => h.relativeHoleScore >= 2)
        .toList();

    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (scoringStats.birdies > 0)
                    _buildLegendItem(
                      context,
                      'Birdie',
                      const Color(0xFF137e66),
                    ),
                  if (scoringStats.pars > 0)
                    _buildLegendItem(context, 'Par', Colors.grey),
                  if (scoringStats.bogeys > 0)
                    _buildLegendItem(context, 'Bogey', const Color(0xFFFF7A7A)),
                  if (scoringStats.doubleBogeyPlus > 0)
                    _buildLegendItem(context, 'Dbl+', const Color(0xFFD32F2F)),
                ],
              ),
              const SizedBox(height: 12),
              // Stacked progress bar with percentages inside
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      if (scoringStats.birdies > 0)
                        _buildBarSegment(
                          context,
                          scoringStats.birdies,
                          totalHoles,
                          const Color(0xFF137e66),
                        ),
                      if (scoringStats.birdies > 0 && scoringStats.pars > 0)
                        const SizedBox(width: 2),
                      if (scoringStats.pars > 0)
                        _buildBarSegment(
                          context,
                          scoringStats.pars,
                          totalHoles,
                          Colors.grey,
                        ),
                      if ((scoringStats.birdies > 0 || scoringStats.pars > 0) &&
                          scoringStats.bogeys > 0)
                        const SizedBox(width: 2),
                      if (scoringStats.bogeys > 0)
                        _buildBarSegment(
                          context,
                          scoringStats.bogeys,
                          totalHoles,
                          const Color(0xFFFF7A7A),
                        ),
                      if ((scoringStats.birdies > 0 ||
                              scoringStats.pars > 0 ||
                              scoringStats.bogeys > 0) &&
                          scoringStats.doubleBogeyPlus > 0)
                        const SizedBox(width: 2),
                      if (scoringStats.doubleBogeyPlus > 0)
                        _buildBarSegment(
                          context,
                          scoringStats.doubleBogeyPlus,
                          totalHoles,
                          const Color(0xFFD32F2F),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          children: [
            const Divider(),
            HoleBreakdownList(
              classifications: [
                HoleClassification(
                  label: 'Birdies (${birdieHoles.length})',
                  circleColor: const Color(0xFF137e66),
                  holes: birdieHoles,
                  getBadgeLabel: (hole) => hole.relativeHoleScore == -1
                      ? 'Birdie'
                      : hole.relativeHoleScore == -2
                      ? 'Eagle'
                      : '${hole.relativeHoleScore}',
                  badgeColor: const Color(0xFF137e66),
                ),
                HoleClassification(
                  label: 'Pars (${parHoles.length})',
                  circleColor: Colors.grey.withValues(alpha: 0.3),
                  holes: parHoles,
                  getBadgeLabel: (hole) => 'Par',
                  badgeColor: Colors.grey,
                ),
                HoleClassification(
                  label: 'Bogeys (${bogeyHoles.length})',
                  circleColor: const Color(0xFFFF7A7A).withValues(alpha: 0.3),
                  holes: bogeyHoles,
                  getBadgeLabel: (hole) => 'Bogey',
                  badgeColor: const Color(0xFFFF7A7A),
                ),
                HoleClassification(
                  label: 'Double Bogey+ (${doublePlusHoles.length})',
                  circleColor: const Color(0xFFD32F2F).withValues(alpha: 0.3),
                  holes: doublePlusHoles,
                  getBadgeLabel: (hole) => hole.relativeHoleScore == 2
                      ? 'Double'
                      : '+${hole.relativeHoleScore}',
                  badgeColor: const Color(0xFFD32F2F),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildBarSegment(
    BuildContext context,
    int count,
    int total,
    Color color,
  ) {
    final percentage = (count / total * 100).round();
    return Expanded(
      flex: count,
      child: Container(
        constraints: const BoxConstraints(minWidth: 45),
        color: color,
        child: Center(
          child: Text(
            '$percentage%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildBirdieTrends(
    BuildContext context,
    Map<int, double> birdieRateByPar,
    Map<String, double> birdieRateByLength,
    double avgBirdieDistance,
    Map<String, Map<String, double>> c1c2ByLength,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance by Distance',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header row
                Row(
                  children: [
                    SizedBox(
                      width: 85,
                      child: Text(
                        'Distance',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Avg',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Birdie',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Par',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Bogey',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Dbl+',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                // Data rows
                ...[
                  '<300 ft',
                  '300-400 ft',
                  '400-500 ft',
                  '>500 ft',
                ].asMap().entries.map((entry) {
                  final index = entry.key;
                  final distanceCategory = entry.value;
                  final holesInCategory = _getHolesForDistanceCategory(
                    distanceCategory,
                  );

                  if (holesInCategory.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  // Calculate stats for this distance category
                  final totalHoles = holesInCategory.length;
                  final totalScore = holesInCategory.fold<int>(
                    0,
                    (sum, hole) => sum + hole.relativeHoleScore,
                  );
                  final avgScore = totalScore / totalHoles;
                  final birdieCount = holesInCategory
                      .where((h) => h.relativeHoleScore < 0)
                      .length;
                  final parCount = holesInCategory
                      .where((h) => h.relativeHoleScore == 0)
                      .length;
                  final bogeyCount = holesInCategory
                      .where((h) => h.relativeHoleScore == 1)
                      .length;
                  final doublePlusCount = holesInCategory
                      .where((h) => h.relativeHoleScore >= 2)
                      .length;

                  final birdieRate = (birdieCount / totalHoles) * 100;
                  final parRate = (parCount / totalHoles) * 100;
                  final bogeyRate = (bogeyCount / totalHoles) * 100;
                  final doublePlusRate = (doublePlusCount / totalHoles) * 100;

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 85,
                              child: Text(
                                distanceCategory,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                avgScore.toStringAsFixed(2),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: const Color(0xFF1976D2),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${birdieRate.toStringAsFixed(0)}%',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: const Color(0xFF137e66),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${parRate.toStringAsFixed(0)}%',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${bogeyRate.toStringAsFixed(0)}%',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: const Color(0xFFFF7A7A),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${doublePlusRate.toStringAsFixed(0)}%',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: const Color(0xFFD32F2F),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (index < 3 &&
                          _getHolesForDistanceCategory(
                            [
                              '<300 ft',
                              '300-400 ft',
                              '400-500 ft',
                              '>500 ft',
                            ][(index + 1)],
                          ).isNotEmpty)
                        const Divider(height: 1),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.insights,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Average hole distance when birdied: ${avgBirdieDistance.toStringAsFixed(0)} ft',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceStatItem(
    BuildContext context,
    String label,
    double value,
  ) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          '${value.toStringAsFixed(0)}%',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // Widget _buildSmallStatCard(BuildContext context, String label, String value) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(vertical: 12),
  //     decoration: BoxDecoration(
  //       color: Theme.of(context).colorScheme.surfaceContainerHighest,
  //       borderRadius: BorderRadius.circular(8),
  //     ),
  //     child: Column(
  //       children: [
  //         Text(
  //           value,
  //           style: Theme.of(context).textTheme.titleMedium?.copyWith(
  //             fontWeight: FontWeight.bold,
  //             color: const Color(0xFF137e66),
  //           ),
  //         ),
  //         const SizedBox(height: 4),
  //         Text(label, style: Theme.of(context).textTheme.bodySmall),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildPerformanceByPar(
    BuildContext context,
    Map<int, Map<String, double>> performanceByPar,
  ) {
    if (performanceByPar.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedEntries = performanceByPar.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Filter out entries with no holes played
    final validEntries = sortedEntries
        .where((entry) => (entry.value['holesPlayed']?.toInt() ?? 0) > 0)
        .toList();

    if (validEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance by Par',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header row
                Row(
                  children: [
                    SizedBox(
                      width: 45,
                      child: Text(
                        'Par',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Avg',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Birdie',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Par',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Bogey',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Dbl+',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                // Data rows
                ...validEntries.asMap().entries.map((mapEntry) {
                  final index = mapEntry.key;
                  final entry = mapEntry.value;
                  final par = entry.key;
                  final stats = entry.value;
                  final avgScore = stats['avgScore'] ?? 0;
                  final birdieRate = stats['birdieRate'] ?? 0;
                  final parRate = stats['parRate'] ?? 0;
                  final bogeyRate = stats['bogeyRate'] ?? 0;
                  final doubleBogeyPlusRate = stats['doubleBogeyPlusRate'] ?? 0;

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 45,
                              child: Text(
                                '$par',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                avgScore.toStringAsFixed(2),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: const Color(0xFF1976D2),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${birdieRate.toStringAsFixed(0)}%',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: const Color(0xFF137e66),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${parRate.toStringAsFixed(0)}%',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${bogeyRate.toStringAsFixed(0)}%',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: const Color(0xFFFF7A7A),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${doubleBogeyPlusRate.toStringAsFixed(0)}%',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: const Color(0xFFD32F2F),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (index < validEntries.length - 1)
                        const Divider(height: 1),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceByFairwayWidth(
    BuildContext context,
    Map<String, Map<String, double>> performanceByWidth,
  ) {
    if (performanceByWidth.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance by Fairway Width',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: performanceByWidth.entries.map((entry) {
                final width = entry.key;
                final stats = entry.value;
                final holesPlayed = stats['holesPlayed']?.toInt() ?? 0;

                if (holesPlayed == 0) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatFairwayWidth(width),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '$holesPlayed holes',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildWidthStatItem(
                            context,
                            'Birdie',
                            stats['birdieRate'] ?? 0,
                          ),
                          _buildWidthStatItem(
                            context,
                            'Par',
                            stats['parRate'] ?? 0,
                          ),
                          _buildWidthStatItem(
                            context,
                            'Bogey+',
                            stats['bogeyRate'] ?? 0,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildWidthStatItem(
                            context,
                            'C1 Reg',
                            stats['c1InRegRate'] ?? 0,
                          ),
                          _buildWidthStatItem(
                            context,
                            'C2 Reg',
                            stats['c2InRegRate'] ?? 0,
                          ),
                          _buildWidthStatItem(
                            context,
                            'OB',
                            stats['obRate'] ?? 0,
                          ),
                        ],
                      ),
                      if (entry != performanceByWidth.entries.last)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Divider(),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  String _formatFairwayWidth(String width) {
    switch (width) {
      case 'open':
        return 'Open Fairway';
      case 'moderate':
        return 'Moderate Fairway';
      case 'tight':
        return 'Tight Fairway';
      case 'very_tight':
        return 'Very Tight Fairway';
      default:
        return width;
    }
  }

  Widget _buildWidthStatItem(BuildContext context, String label, double value) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          '${value.toStringAsFixed(0)}%',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  List<DGHole> _getHolesForDistanceCategory(String category) {
    return round.holes.where((hole) {
      final feet = hole.feet;
      if (feet == null) return false;

      switch (category) {
        case '<300 ft':
          return feet < 300;
        case '300-400 ft':
          return feet >= 300 && feet < 400;
        case '400-500 ft':
          return feet >= 400 && feet < 500;
        case '>500 ft':
          return feet >= 500;
        default:
          return false;
      }
    }).toList();
  }

  Widget _buildHolesList(BuildContext context, List<DGHole> holes) {
    final birdieHoles = holes.where((h) => h.relativeHoleScore < 0).toList();
    final parHoles = holes.where((h) => h.relativeHoleScore == 0).toList();
    final bogeyHoles = holes.where((h) => h.relativeHoleScore > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (birdieHoles.isNotEmpty) ...[
          Text(
            'Birdies (${birdieHoles.length})',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...birdieHoles.map((hole) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFF137e66),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${hole.number}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hole ${hole.number} - Par ${hole.par}${hole.feet != null ? ' • ${hole.feet} ft' : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF137e66).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      hole.relativeHoleScore == -1
                          ? 'Birdie'
                          : hole.relativeHoleScore == -2
                          ? 'Eagle'
                          : '${hole.relativeHoleScore}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: const Color(0xFF137e66),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        if (birdieHoles.isNotEmpty &&
            (parHoles.isNotEmpty || bogeyHoles.isNotEmpty)) ...[
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
        ],
        if (parHoles.isNotEmpty) ...[
          Text(
            'Pars (${parHoles.length})',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...parHoles.map((hole) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${hole.number}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hole ${hole.number} - Par ${hole.par}${hole.feet != null ? ' • ${hole.feet} ft' : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Par',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        if (parHoles.isNotEmpty && bogeyHoles.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
        ],
        if (bogeyHoles.isNotEmpty) ...[
          Text(
            'Bogeys (${bogeyHoles.length})',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...bogeyHoles.map((hole) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${hole.number}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hole ${hole.number} - Par ${hole.par}${hole.feet != null ? ' • ${hole.feet} ft' : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      hole.relativeHoleScore == 1
                          ? 'Bogey'
                          : hole.relativeHoleScore == 2
                          ? 'Double'
                          : '+${hole.relativeHoleScore}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildWhatCouldHaveBeen(BuildContext context) {
    final scenarios = _calculateScenarios();

    if (scenarios.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentScore = round.holes.fold<int>(
      0,
      (sum, hole) => sum + hole.relativeHoleScore,
    );
    final currentScoreStr = currentScore >= 0 ? '+$currentScore' : '$currentScore';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What Could Have Been',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Score',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    Text(
                      currentScoreStr,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: currentScore < 0
                                ? const Color(0xFF137e66)
                                : currentScore > 0
                                    ? const Color(0xFFFF7A7A)
                                    : Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                ...scenarios.map((scenario) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ImprovementScenarioItem(
                      scenario: scenario,
                      currentScore: currentScore,
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<ImprovementScenario> _calculateScenarios() {
    final scenarios = <ImprovementScenario>[];

    // Scenario 1: Clean Up C1X - count missed putts from 11-33 feet
    final puttingService = locator.get<PuttingAnalysisService>();
    final allPutts = puttingService.getPuttAttempts(round);

    // Get all C1X putts (11-33 feet) that were missed
    final missedC1xPutts = allPutts.where((putt) {
      final distance = putt['distance'] as double?;
      final made = putt['made'] as bool? ?? false;
      return distance != null && distance >= 11 && distance <= 33 && !made;
    }).toList();

    if (missedC1xPutts.isNotEmpty) {
      // Count missed C1X putts per hole
      final missedPuttsPerHole = <int, int>{};
      for (final putt in missedC1xPutts) {
        final holeNumber = putt['holeNumber'] as int?;
        if (holeNumber != null) {
          missedPuttsPerHole[holeNumber] = (missedPuttsPerHole[holeNumber] ?? 0) + 1;
        }
      }

      // Get unique holes where C1X putts were missed
      final c1xMissedHoles = <DGHole>[];
      for (final holeNumber in missedPuttsPerHole.keys) {
        final hole = round.holes.firstWhere((h) => h.number == holeNumber);
        c1xMissedHoles.add(hole);
      }

      scenarios.add(
        ImprovementScenario(
          title: 'Clean Up C1X Putts',
          description:
              'Make your putts from 11-33 feet (Circle 1 extended)',
          strokesSaved: missedC1xPutts.length,
          category: 'Easy Wins',
          emoji: '🎯',
          affectedHoles: c1xMissedHoles,
          getImprovementLabel: (hole) {
            final count = missedPuttsPerHole[hole.number] ?? 1;
            return count > 1 ? 'Make C1X ($count misses)' : 'Make C1X';
          },
        ),
      );
    }

    // Scenario 2: Eliminate Disasters - turn double bogeys+ into bogeys
    final disasterHoles =
        round.holes.where((h) => h.relativeHoleScore >= 2).toList();
    if (disasterHoles.isNotEmpty) {
      final strokesSaved = disasterHoles.fold<int>(
        0,
        (sum, hole) => sum + (hole.relativeHoleScore - 1), // Convert to bogey (+1)
      );
      scenarios.add(
        ImprovementScenario(
          title: 'Eliminate Disasters',
          description: 'Limit damage on blow-up holes to single bogeys',
          strokesSaved: strokesSaved,
          category: 'Mental Game',
          emoji: '🧠',
          affectedHoles: disasterHoles,
          getImprovementLabel: (hole) => hole.relativeHoleScore == 2
              ? 'Dbl→Bogey'
              : '+${hole.relativeHoleScore}→Bogey',
        ),
      );
    }

    // Scenario 3: Perfect Scrambling - holes where they went off fairway and made bogey+
    final missedScrambles = <DGHole>[];
    for (final hole in round.holes) {
      bool wentOffFairway = false;

      // Check if any throw went off fairway
      for (final discThrow in hole.throws) {
        if (discThrow.landingSpot == LandingSpot.offFairway) {
          wentOffFairway = true;
          break;
        }
      }

      // If they went off fairway and made bogey or worse
      if (wentOffFairway && hole.relativeHoleScore > 0) {
        missedScrambles.add(hole);
      }
    }

    if (missedScrambles.isNotEmpty) {
      final strokesSaved = missedScrambles.fold<int>(
        0,
        (sum, hole) => sum + hole.relativeHoleScore, // Convert to par (0)
      );
      scenarios.add(
        ImprovementScenario(
          title: 'Perfect Scrambling',
          description:
              'Save par when you go off fairway with good short game',
          strokesSaved: strokesSaved,
          category: 'Short Game',
          emoji: '🎲',
          affectedHoles: missedScrambles,
          getImprovementLabel: (hole) => hole.relativeHoleScore == 1
              ? 'Bogey→Par'
              : '+${hole.relativeHoleScore}→Par',
        ),
      );
    }

    // Sort by strokes saved (biggest impact first)
    scenarios.sort((a, b) => b.strokesSaved.compareTo(a.strokesSaved));

    return scenarios;
  }
}
