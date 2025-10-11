import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
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
        analysis?.scoringStats ?? statsService.getScoringStats();
    final totalScore =
        analysis?.totalScoreRelativeToPar ??
        statsService.getTotalScoreRelativeToPar();
    final bounceBackPct =
        analysis?.bounceBackPercentage ??
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
          _buildScoreSummary(context, totalScore, scoringStats, bounceBackPct),
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

  Widget _buildScoreSummary(
    BuildContext context,
    int totalScore,
    scoringStats,
    double bounceBackPct,
  ) {
    final scoreColor = totalScore < 0
        ? const Color(0xFF00F5D4)
        : totalScore > 0
        ? const Color(0xFFFF7A7A)
        : const Color(0xFFF5F5F5);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Round Summary',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildKPI(
                  context,
                  'Score',
                  totalScore >= 0 ? '+$totalScore' : '$totalScore',
                  scoreColor,
                ),
                _buildKPI(
                  context,
                  'Birdies',
                  '${scoringStats.birdies}',
                  const Color(0xFF00F5D4),
                ),
                _buildKPI(
                  context,
                  scoringStats.pars == 1 ? 'Par' : 'Pars',
                  '${scoringStats.pars}',
                  Colors.grey,
                ),
                _buildKPI(
                  context,
                  'Bogeys',
                  '${scoringStats.bogeys}',
                  const Color(0xFFFF7A7A),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: _buildKPI(
                context,
                'Bounce Back %',
                '${bounceBackPct.toStringAsFixed(0)}%',
                const Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPI(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreDistribution(BuildContext context, scoringStats) {
    final total = scoringStats.totalHoles;

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
            const SizedBox(height: 16),
            _buildDistributionBar(
              context,
              'Birdies',
              scoringStats.birdies,
              total,
              const Color(0xFF00F5D4),
            ),
            const SizedBox(height: 8),
            _buildDistributionBar(
              context,
              'Pars',
              scoringStats.pars,
              total,
              Colors.grey,
            ),
            const SizedBox(height: 8),
            _buildDistributionBar(
              context,
              'Bogeys',
              scoringStats.bogeys,
              total,
              const Color(0xFFFF7A7A),
            ),
            const SizedBox(height: 8),
            _buildDistributionBar(
              context,
              'Double Bogey+',
              scoringStats.doubleBogeyPlus,
              total,
              const Color(0xFFD32F2F),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionBar(
    BuildContext context,
    String label,
    int count,
    int total,
    Color color,
  ) {
    final percentage = total > 0 ? (count / total) * 100 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(
              '$count (${percentage.toStringAsFixed(0)}%)',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: count / total,
            minHeight: 12,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
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
                  'Birdie % by Par',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: birdieRateByPar.entries.expand((entry) sync* {
                    yield Expanded(
                      child: _buildSmallStatCard(
                        context,
                        'Par ${entry.key}',
                        '${entry.value.toStringAsFixed(0)}%',
                      ),
                    );
                    if (entry != birdieRateByPar.entries.last) {
                      yield const SizedBox(width: 12);
                    }
                  }).toList(),
                ),
              ],
            ),
          ),
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

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                        const SizedBox(height: 6),
                        Row(
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
                        if (entry != birdieRateByLength.entries.last)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Divider(),
                          ),
                      ],
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

  Widget _buildSmallStatCard(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF00F5D4),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildPerformanceByPar(
    BuildContext context,
    Map<int, Map<String, double>> performanceByPar,
  ) {
    if (performanceByPar.isEmpty) {
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
        ...performanceByPar.entries.map((entry) {
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
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildParStatColumn(
                          context,
                          'C1 Reg',
                          stats['c1InRegRate'] ?? 0,
                          const Color(0xFF4CAF50),
                        ),
                        _buildParStatColumn(
                          context,
                          'C2 Reg',
                          stats['c2InRegRate'] ?? 0,
                          const Color(0xFF8BC34A),
                        ),
                        _buildParStatColumn(
                          context,
                          'Avg Score',
                          stats['avgScore'] ?? 0,
                          Theme.of(context).colorScheme.primary,
                          isAverage: true,
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

  Widget _buildPerformanceByHoleType(
    BuildContext context,
    Map<String, Map<String, double>> performanceByType,
  ) {
    if (performanceByType.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance by Hole Type',
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
              children: performanceByType.entries.map((entry) {
                final holeType = entry.key;
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
                            _formatHoleType(holeType),
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
                      if (entry != performanceByType.entries.last)
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

  String _formatHoleType(String holeType) {
    switch (holeType) {
      case 'open':
        return 'Open';
      case 'slightlyWooded':
        return 'Slightly Wooded';
      case 'wooded':
        return 'Wooded';
      default:
        return holeType;
    }
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
}
