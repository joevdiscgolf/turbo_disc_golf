import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/throw_list_item.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/services/gpt_analysis_service.dart';
import 'package:turbo_disc_golf/services/round_statistics_service.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

class DiscsTab extends StatelessWidget {
  final DGRound round;

  const DiscsTab({super.key, required this.round});

  @override
  Widget build(BuildContext context) {
    final RoundStatisticsService statsService = RoundStatisticsService(round);

    final discBirdieRates = statsService.getDiscBirdieRates();
    final discParRates = statsService.getDiscParRates();
    final discBogeyRates = statsService.getDiscBogeyRates();
    final discAverageScores = statsService.getDiscAverageScores();
    final discPerformances = statsService.getDiscPerformanceSummaries();
    final discThrowCounts = statsService.getDiscThrowCounts();
    final discC1InRegPercentages = statsService.getDiscC1InRegPercentages();
    final discC2InRegPercentages = statsService.getDiscC2InRegPercentages();

    if (discPerformances.isEmpty) {
      return const Center(
        child: Text('No disc data available'),
      );
    }

    // Sort all discs by birdie rate (primary), then by throw count (secondary)
    final sortedDiscs = discPerformances.map((perf) {
      final birdieRate = discBirdieRates[perf.discName] ?? 0.0;
      return MapEntry(perf.discName, birdieRate);
    }).toList()
      ..sort((a, b) {
        // First compare by birdie rate (descending)
        final birdieRateComparison = b.value.compareTo(a.value);
        if (birdieRateComparison != 0) return birdieRateComparison;

        // If birdie rates are equal, compare by throw count (descending)
        final aPerf = discPerformances.firstWhere((p) => p.discName == a.key);
        final bPerf = discPerformances.firstWhere((p) => p.discName == b.key);
        return bPerf.totalShots.compareTo(aPerf.totalShots);
      });

    // Get all discs with the top birdie rate(s) - could be more than 3
    final topBirdieRate = sortedDiscs.isNotEmpty ? sortedDiscs.first.value : 0.0;
    final topPerformingDiscs = sortedDiscs
        .where((disc) => disc.value == topBirdieRate && disc.value > 0)
        .toList();

    // Get all discs with tee shots (birdie rate > 0 means used off tee)
    final discsWithTeeSshots = sortedDiscs
        .where((disc) => discBirdieRates.containsKey(disc.key))
        .toList();

    // Get worst performing discs (lowest birdie rate among discs with tee shots)
    final worstBirdieRate = discsWithTeeSshots.isNotEmpty
        ? discsWithTeeSshots.last.value
        : 0.0;
    final worstPerformingDiscs = discsWithTeeSshots
        .where((disc) => disc.value == worstBirdieRate && disc.value < topBirdieRate)
        .toList();

    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 80),
      children: addRunSpacing(
        [
          if (topPerformingDiscs.isNotEmpty)
            _buildTopPerformingDiscs(context, topPerformingDiscs),
          if (worstPerformingDiscs.isNotEmpty)
            _buildWorstPerformingDiscs(context, worstPerformingDiscs),
          ...sortedDiscs.map((entry) {
            final discName = entry.key;
            final birdieRate = entry.value;
            final parRate = discParRates[discName] ?? 0.0;
            final bogeyRate = discBogeyRates[discName] ?? 0.0;
            final avgScore = discAverageScores[discName] ?? 0.0;
            final throwCount = discThrowCounts[discName] ?? 0;
            final c1InRegPct = discC1InRegPercentages[discName] ?? 0.0;
            final c2InRegPct = discC2InRegPercentages[discName] ?? 0.0;
            final performance = discPerformances.firstWhere(
              (p) => p.discName == discName,
            );

            return _buildDiscPerformanceCard(
              context,
              discName,
              birdieRate,
              parRate,
              bogeyRate,
              avgScore,
              throwCount,
              c1InRegPct,
              c2InRegPct,
              performance,
              statsService,
            );
          }),
        ],
        runSpacing: 16,
        axis: Axis.vertical,
      ),
    );
  }

  Widget _buildTopPerformingDiscs(
    BuildContext context,
    List<MapEntry<String, double>> topDiscs,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Performing Discs',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Birdie Rate by Disc',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: topDiscs.map((entry) {
                return _buildTopDiscCard(
                  context,
                  entry.key,
                  entry.value,
                  const Color(0xFF00F5D4),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorstPerformingDiscs(
    BuildContext context,
    List<MapEntry<String, double>> worstDiscs,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Worst Performing Discs',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Birdie Rate by Disc',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: worstDiscs.map((entry) {
                return _buildTopDiscCard(
                  context,
                  entry.key,
                  entry.value,
                  const Color(0xFFFF7A7A),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopDiscCard(
    BuildContext context,
    String discName,
    double birdieRate,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            '${birdieRate.toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            discName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscPerformanceCard(
    BuildContext context,
    String discName,
    double birdieRate,
    double parRate,
    double bogeyRate,
    double avgScore,
    int throwCount,
    double c1InRegPct,
    double c2InRegPct,
    performance,
    RoundStatisticsService statsService,
  ) {
    final throws = statsService.getThrowsForDisc(discName);

    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          title: Text(
            discName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildStatChip(
                  context,
                  'Throws: ${throws.length}',
                  Colors.grey,
                ),
                _buildStatChip(
                  context,
                  'Birdie: ${birdieRate.toStringAsFixed(0)}%',
                  const Color(0xFF00F5D4),
                ),
                _buildStatChip(
                  context,
                  'Par: ${parRate.toStringAsFixed(0)}%',
                  Colors.grey,
                ),
                _buildStatChip(
                  context,
                  'Bogey: ${bogeyRate.toStringAsFixed(0)}%',
                  const Color(0xFFFF7A7A),
                ),
                _buildStatChip(
                  context,
                  'C1 in Reg: ${c1InRegPct.toStringAsFixed(0)}%',
                  const Color(0xFF4CAF50),
                ),
                _buildStatChip(
                  context,
                  'C2 in Reg: ${c2InRegPct.toStringAsFixed(0)}%',
                  const Color(0xFF2196F3),
                ),
                _buildStatChip(
                  context,
                  'Avg: ${avgScore >= 0 ? '+' : ''}${avgScore.toStringAsFixed(1)}',
                  avgScore < 0
                      ? const Color(0xFF00F5D4)
                      : const Color(0xFFFF7A7A),
                ),
              ],
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performance Breakdown',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPerformanceStat(
                        context,
                        'Good',
                        '${performance.goodPercentage.toStringAsFixed(0)}%',
                        const Color(0xFF4CAF50),
                      ),
                      _buildPerformanceStat(
                        context,
                        'Okay',
                        '${performance.okayPercentage.toStringAsFixed(0)}%',
                        const Color(0xFFFFA726),
                      ),
                      _buildPerformanceStat(
                        context,
                        'Bad',
                        '${performance.badPercentage.toStringAsFixed(0)}%',
                        const Color(0xFFFF7A7A),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Total Throws: ${performance.totalShots}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'All Throws',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...throws.map((throwData) {
                    final holeNumber = throwData['holeNumber'];
                    final throwIndex = throwData['throwIndex'];
                    final discThrow = throwData['throw'] as DiscThrow;
                    final analysis = GPTAnalysisService.analyzeThrow(discThrow);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
                          child: Row(
                            children: [
                              Text(
                                'Hole $holeNumber',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              _buildPerformanceBadge(context, analysis.execCategory),
                            ],
                          ),
                        ),
                        ThrowListItem(
                          discThrow: discThrow,
                          throwIndex: throwIndex,
                          showEditButton: false,
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildPerformanceStat(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

  Widget _buildPerformanceBadge(BuildContext context, ExecCategory category) {
    String label;
    Color color;

    switch (category) {
      case ExecCategory.good:
        label = 'Good';
        color = const Color(0xFF4CAF50);
        break;
      case ExecCategory.neutral:
        label = 'Okay';
        color = const Color(0xFFFFA726);
        break;
      case ExecCategory.bad:
      case ExecCategory.severe:
        label = 'Bad';
        color = const Color(0xFFFF7A7A);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
      ),
    );
  }
}
