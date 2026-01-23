import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/putt_detail/components/putt_heat_map_card.dart';
import 'package:turbo_disc_golf/screens/stats/components/putting_distance_card.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/services/round_analysis/putting_analysis_service.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';
import 'package:turbo_disc_golf/utils/constants/putting_constants.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/components/indicators/circular_stat_indicator.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';

class PuttingDetailScreen extends StatelessWidget {
  static const String screenName = 'Putting Detail';

  final DGRound round;

  const PuttingDetailScreen({super.key, required this.round});

  @override
  Widget build(BuildContext context) {
    // Track screen impression
    WidgetsBinding.instance.addPostFrameCallback((_) {
      locator.get<LoggingService>().track(
        'Screen Impression',
        properties: {
          'screen_name': PuttingDetailScreen.screenName,
          'screen_class': 'PuttingDetailScreen',
        },
      );
    });

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

    return Container(
      color: SenseiColors.gray[50],
      child: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 80),
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
              child: PuttHeatMapCard(round: round, shouldAnimate: true),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildAllPuttsCard(context, allPutts),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildComebackPutts(context, comebackStats),
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
          ],
          runSpacing: 12,
          axis: Axis.vertical,
        ),
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
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            locator.get<FeatureFlagService>().useHeroAnimationsForRoundReview
                ? Hero(
                    tag: 'putting_c1',
                    child: CircularStatIndicator(
                      label: 'C1',
                      percentage: puttingStats.c1Percentage,
                      color: const Color(0xFF137e66),
                      internalLabel:
                          '(${puttingStats.c1Makes}/${puttingStats.c1Attempts})',
                      size: 90,
                      shouldAnimate: true,
                      shouldGlow: true,
                    ),
                  )
                : CircularStatIndicator(
                    label: 'C1',
                    percentage: puttingStats.c1Percentage,
                    color: const Color(0xFF137e66),
                    internalLabel:
                        '(${puttingStats.c1Makes}/${puttingStats.c1Attempts})',
                    size: 90,
                    shouldAnimate: true,
                    shouldGlow: true,
                  ),
            locator.get<FeatureFlagService>().useHeroAnimationsForRoundReview
                ? Hero(
                    tag: 'putting_c1x',
                    child: CircularStatIndicator(
                      label: 'C1X',
                      percentage: c1xPct,
                      color: const Color(0xFF4CAF50),
                      internalLabel: '($c1xMakes/$c1xAttempts)',
                      size: 90,
                      shouldAnimate: true,
                      shouldGlow: true,
                    ),
                  )
                : CircularStatIndicator(
                    label: 'C1X',
                    percentage: c1xPct,
                    color: const Color(0xFF4CAF50),
                    internalLabel: '($c1xMakes/$c1xAttempts)',
                    size: 90,
                    shouldAnimate: true,
                    shouldGlow: true,
                  ),
            locator.get<FeatureFlagService>().useHeroAnimationsForRoundReview
                ? Hero(
                    tag: 'putting_c2',
                    child: CircularStatIndicator(
                      label: 'C2',
                      percentage: puttingStats.c2Percentage,
                      color: const Color(0xFF2196F3),
                      internalLabel:
                          '(${puttingStats.c2Makes}/${puttingStats.c2Attempts})',
                      size: 90,
                      shouldAnimate: true,
                      shouldGlow: true,
                    ),
                  )
                : CircularStatIndicator(
                    label: 'C2',
                    percentage: puttingStats.c2Percentage,
                    color: const Color(0xFF2196F3),
                    internalLabel:
                        '(${puttingStats.c2Makes}/${puttingStats.c2Attempts})',
                    size: 90,
                    shouldAnimate: true,
                    shouldGlow: true,
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
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
        ),
        child: ExpansionTile(
          onExpansionChanged: (_) => HapticFeedback.lightImpact(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comeback Putts',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // CircularStatIndicator on the left
                  CircularStatIndicator(
                    label: '',
                    percentage: percentage,
                    color: const Color(0xFF4CAF50),
                    size: 80,
                    internalLabel: '$makes/$attempts',
                    shouldAnimate: true,
                    shouldGlow: true,
                  ),
                  const SizedBox(width: 16),
                  // Dots to the right
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: details.map((putt) {
                        final made = putt['made'] as bool;
                        return Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: made
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFFF7A7A),
                            shape: BoxShape.circle,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
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

  Widget _buildAllPuttsCard(
    BuildContext context,
    List<Map<String, dynamic>> allPutts,
  ) {
    if (allPutts.isEmpty) {
      return const SizedBox.shrink();
    }

    final int totalMade = allPutts.where((putt) => putt['made'] as bool).length;
    final int totalAttempts = allPutts.length;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
        ),
        child: ExpansionTile(
          onExpansionChanged: (_) => HapticFeedback.lightImpact(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'All Putts ($totalMade/$totalAttempts)',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allPutts.map((putt) {
                  final bool made = putt['made'] as bool;
                  return Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: made
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFFF7A7A),
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList(),
              ),
            ],
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
