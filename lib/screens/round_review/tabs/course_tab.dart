import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
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
  //       ? const Color(0xFF00F5D4)
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
  //                 const Color(0xFF00F5D4),
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
    final totalHoles = scoringStats.birdies +
        scoringStats.pars +
        scoringStats.bogeys +
        scoringStats.doubleBogeyPlus;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score Distribution',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (scoringStats.birdies > 0)
                  _buildLegendItem(context, 'Birdies', const Color(0xFF00F5D4)),
                if (scoringStats.pars > 0)
                  _buildLegendItem(context, 'Pars', Colors.grey),
                if (scoringStats.bogeys > 0)
                  _buildLegendItem(context, 'Bogeys', const Color(0xFFFF7A7A)),
                if (scoringStats.doubleBogeyPlus > 0)
                  _buildLegendItem(context, 'Double+', const Color(0xFFD32F2F)),
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
                        const Color(0xFF00F5D4),
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
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Performance by Hole Length',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...birdieRateByLength.entries.map((entry) {
                  final distanceCategory = entry.key;
                  final birdieRate = entry.value;
                  final c1c2Stats = c1c2ByLength[distanceCategory];
                  final c1Rate = c1c2Stats?['c1InRegRate'] ?? 0;
                  final c2Rate = c1c2Stats?['c2InRegRate'] ?? 0;
                  final holesPlayed = c1c2Stats?['holesPlayed']?.toInt() ?? 0;

                  // Get holes for this distance category
                  final holesInCategory = _getHolesForDistanceCategory(
                    distanceCategory,
                  );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(top: 8),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              distanceCategory,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (holesPlayed > 0)
                              Text(
                                '$holesPlayed holes',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildDistanceStatItem(
                                context,
                                'Birdie',
                                birdieRate,
                              ),
                              _buildDistanceStatItem(context, 'C1 Reg', c1Rate),
                              _buildDistanceStatItem(context, 'C2 Reg', c2Rate),
                            ],
                          ),
                        ),
                        children: [
                          if (holesInCategory.isNotEmpty) ...[
                            const Divider(),
                            _buildHolesList(context, holesInCategory),
                          ],
                        ],
                      ),
                    ),
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
  //             color: const Color(0xFF00F5D4),
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
        ...sortedEntries.map((entry) {
          final par = entry.key;
          final stats = entry.value;
          final holesPlayed = stats['holesPlayed']?.toInt() ?? 0;

          if (holesPlayed == 0) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Par $par',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '$holesPlayed holes',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildParStatColumn(
                          context,
                          'Avg Score',
                          stats['avgScore'] ?? 0,
                          Theme.of(context).colorScheme.primary,
                          isAverage: true,
                        ),
                        _buildParStatColumn(
                          context,
                          'Birdie',
                          stats['birdieRate'] ?? 0,
                          const Color(0xFF00F5D4),
                        ),
                        _buildParStatColumn(
                          context,
                          'Par',
                          stats['parRate'] ?? 0,
                          Colors.grey,
                        ),
                        _buildParStatColumn(
                          context,
                          'Bogey+',
                          stats['bogeyRate'] ?? 0,
                          const Color(0xFFFF7A7A),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildParStatColumn(
    BuildContext context,
    String label,
    double value,
    Color color, {
    bool isAverage = false,
  }) {
    final displayValue = isAverage
        ? value.toStringAsFixed(2)
        : '${value.toStringAsFixed(0)}%';

    return Column(
      children: [
        Text(
          displayValue,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
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
                      color: Color(0xFF00F5D4),
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
                      color: const Color(0xFF00F5D4).withValues(alpha: 0.15),
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
                        color: const Color(0xFF00F5D4),
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
}
