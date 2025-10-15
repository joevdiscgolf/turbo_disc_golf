import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/components/putt_heat_map_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/deep_analysis/components/putting_distance_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/deep_analysis/components/putting_summary_cards.dart';
import 'package:turbo_disc_golf/services/round_analysis/putting_analysis_service.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

class PuttingTab extends StatelessWidget {
  final DGRound round;

  const PuttingTab({super.key, required this.round});

  @override
  Widget build(BuildContext context) {
    final PuttingAnalysisService puttingAnalysisService = locator
        .get<PuttingAnalysisService>();

    final puttingSummary = puttingAnalysisService.getPuttingSummary(round);
    final avgBirdiePuttDist = puttingAnalysisService
        .getAverageBirdiePuttDistance(round);
    final comebackStats = puttingAnalysisService.getComebackPuttStats(round);
    final allPutts = puttingAnalysisService.getPuttAttempts(round);

    if (puttingSummary.totalAttempts == 0) {
      return const Center(child: Text('No putting data available'));
    }

    return ListView(
      padding: const EdgeInsets.only(top: 24, bottom: 80),
      children: addRunSpacing(
        [
          // New cards from deep analysis
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PuttingSummaryCards(
              puttingSummary: puttingSummary,
              horizontalPadding: 0,
            ),
          ),
          // All putts list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildAllPuttsCard(context, allPutts),
          ),
          // Heat map visualization
          PuttHeatMapCard(round: round),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PuttingDistanceCard(
              avgMakeDistance: puttingSummary.avgMakeDistance,
              avgAttemptDistance: puttingSummary.avgAttemptDistance,
              avgBirdiePuttDistance: avgBirdiePuttDist,
              totalMadeDistance: puttingSummary.totalMadeDistance,
              horizontalPadding: 0,
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildComebackPutts(context, comebackStats),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSummaryInsight(context, puttingSummary),
          ),
        ],
        runSpacing: 16,
        axis: Axis.vertical,
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comeback Putts',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: makes > 0 ? makes : 1,
                  child: Container(
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(4),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Made: $makes',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                if (makes > 0 && attempts - makes > 0) const SizedBox(width: 2),
                Expanded(
                  flex: (attempts - makes) > 0 ? (attempts - makes) : 1,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7A7A),
                      borderRadius: BorderRadius.horizontal(
                        left: makes == 0
                            ? const Radius.circular(4)
                            : Radius.zero,
                        right: const Radius.circular(4),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Missed: ${attempts - makes}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Comeback Rate: ${percentage.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Comeback Putt Details',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
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
                              : const Color(0xFFFF7A7A).withValues(alpha: 0.1),
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
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
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
                                : const Color(0xFFFF7A7A).withValues(alpha: 0.1),
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
