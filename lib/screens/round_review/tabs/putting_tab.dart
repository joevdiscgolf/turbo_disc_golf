import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/components/putt_heat_map_card_v2.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/deep_analysis/components/putting_distance_card.dart';
import 'package:turbo_disc_golf/services/round_analysis/putting_analysis_service.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';
import 'package:turbo_disc_golf/utils/putting_constants.dart';
import 'package:turbo_disc_golf/widgets/circular_stat_indicator.dart';

class PuttingTab extends StatelessWidget {
  final DGRound round;

  const PuttingTab({super.key, required this.round});

  @override
  Widget build(BuildContext context) {
    final PuttingAnalysisService puttingAnalysisService = locator
        .get<PuttingAnalysisService>();

    final PuttStats puttingStats = puttingAnalysisService.getPuttingSummary(
      round,
    );
    final avgBirdiePuttDist = puttingAnalysisService
        .getAverageBirdiePuttDistance(round);
    final comebackStats = puttingAnalysisService.getComebackPuttStats(round);
    final allPutts = puttingAnalysisService.getPuttAttempts(round);

    if (puttingStats.totalAttempts == 0) {
      return const Center(child: Text('No putting data available'));
    }

    return ListView(
      padding: const EdgeInsets.only(top: 24, bottom: 80),
      children: addRunSpacing(
        [
          // Putting stats KPIs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildPuttingStatsKPIs(context, puttingStats),
          ),

          // Heat map visualization
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PuttHeatMapCardV2(round: round),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildAllPuttsCard(context, allPutts),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PuttingDistanceCard(
              avgMakeDistance: puttingStats.avgMakeDistance,
              avgAttemptDistance: puttingStats.avgAttemptDistance,
              avgBirdiePuttDistance: avgBirdiePuttDist,
              totalMadeDistance: puttingStats.totalMadeDistance,
              horizontalPadding: 0,
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildComebackPutts(context, comebackStats),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSummaryInsight(context, puttingStats),
          ),
        ],
        runSpacing: 16,
        axis: Axis.vertical,
      ),
    );
  }

  Widget _buildPuttingStatsKPIs(BuildContext context, PuttStats puttingStats) {
    // Calculate C1X percentage (putts made from 11-33 ft)
    // C1X combines the buckets defined in putting_constants.dart
    int c1xAttempts = 0;
    int c1xMakes = 0;
    for (final bucketName in c1xBuckets) {
      final bucket = puttingStats.bucketStats[bucketName];
      c1xAttempts += (bucket?.attempts ?? 0);
      c1xMakes += (bucket?.makes ?? 0);
    }
    final c1xPct = c1xAttempts > 0 ? (c1xMakes / c1xAttempts) * 100 : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CircularStatIndicator(
              label: 'C1',
              percentage: puttingStats.c1Percentage,
              color: const Color(0xFF137e66),
              internalLabel:
                  '(${puttingStats.c1Makes}/${puttingStats.c1Attempts})',
              size: 90,
              strokeWidth: 7,
            ),
            CircularStatIndicator(
              label: 'C1X',
              percentage: c1xPct,
              color: const Color(0xFF4CAF50),
              internalLabel: '($c1xMakes/$c1xAttempts)',
              size: 90,
              strokeWidth: 7,
            ),
            CircularStatIndicator(
              label: 'C2',
              percentage: puttingStats.c2Percentage,
              color: const Color(0xFF2196F3),
              internalLabel:
                  '(${puttingStats.c2Makes}/${puttingStats.c2Attempts})',
              size: 90,
              strokeWidth: 7,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComebackPutts(
    BuildContext context,
    Map<String, dynamic> comebackStats,
  ) {
    final attempts = comebackStats['attempts'] ?? 0;
    final makes = comebackStats['makes'] ?? 0;
    final details =
        comebackStats['details'] as List<Map<String, dynamic>>? ?? [];
    final percentage = attempts > 0 ? (makes / attempts) * 100 : 0.0;

    if (attempts == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Row(
            children: [
              SmallCircularStatIndicator(
                label: '',
                percentage: percentage,
                color: const Color(0xFF4CAF50),
                internalLabel: '$makes/$attempts',
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comeback Putts',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$makes/$attempts made',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          children: details.isEmpty
              ? []
              : [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        ...details.map((putt) {
                          final holeNumber = putt['holeNumber'];
                          final distance = putt['distance'];
                          final made = putt['made'] as bool;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: made
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFFFF7A7A),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$holeNumber',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Hole $holeNumber${distance != null ? ' - $distance ft' : ''}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: made
                                        ? const Color(
                                            0xFF4CAF50,
                                          ).withValues(alpha: 0.1)
                                        : const Color(
                                            0xFFFF7A7A,
                                          ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    made ? 'Made' : 'Missed',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: made
                                              ? const Color(0xFF4CAF50)
                                              : const Color(0xFFFF7A7A),
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                              ],
                            ),
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

  Widget _buildSummaryInsight(BuildContext context, puttingSummary) {
    final c1Pct = puttingSummary.c1Percentage;
    final c2Pct = puttingSummary.c2Percentage;

    String worstRange = 'N/A';
    double worstPercentage = 100;

    puttingSummary.bucketStats.forEach((key, bucket) {
      if (bucket.attempts > 0 && bucket.makePercentage < worstPercentage) {
        worstPercentage = bucket.makePercentage;
        worstRange = key;
      }
    });

    return Card(
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
                'You made ${c1Pct.toStringAsFixed(0)}% of C1 putts and ${c2Pct.toStringAsFixed(0)}% of C2 putts. ${worstRange != 'N/A' ? 'Misses were most common in the $worstRange range.' : ''}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllPuttsCard(
    BuildContext context,
    List<Map<String, dynamic>> allPutts,
  ) {
    if (allPutts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            'All Putt Attempts',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${allPutts.length} total attempts',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: allPutts.map((putt) {
                  final holeNumber = putt['holeNumber'];
                  final distance = putt['distance'];
                  final made = putt['made'] as bool;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: made
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFFF7A7A),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$holeNumber',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Hole $holeNumber - ${distance.toStringAsFixed(0)} ft',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: made
                                ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                                : const Color(
                                    0xFFFF7A7A,
                                  ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            made ? 'Made' : 'Missed',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: made
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFFFF7A7A),
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
