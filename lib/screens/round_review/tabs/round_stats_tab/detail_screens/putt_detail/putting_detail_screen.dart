import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/components/indicators/circular_stat_indicator.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/putt_detail/components/putt_details_list.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/putt_detail/components/putt_heat_map_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/putt_detail/models/putt_attempt.dart';
import 'package:turbo_disc_golf/screens/stats/components/putting_distance_card.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/services/round_analysis/putting_analysis_service.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/utils/constants/putting_constants.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

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
    final List<PuttAttempt> allPutts = puttingAnalysisService
        .getAllPuttAttempts(round);
    final List<PuttAttempt> comebackPutts = allPutts
        .where((p) => p.isComeback)
        .toList();

    if (puttingStats.totalAttempts == 0) {
      return const Center(child: Text('No putting data available'));
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
      child: Container(
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
                child: _buildComebackPuttsCard(context, comebackPutts),
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

  Widget _buildComebackPuttsCard(
    BuildContext context,
    List<PuttAttempt> comebackPutts,
  ) {
    if (comebackPutts.isEmpty) {
      return const SizedBox.shrink();
    }

    final int makes = comebackPutts.where((p) => p.made).length;
    final int attempts = comebackPutts.length;
    final double percentage = attempts > 0 ? (makes / attempts) * 100 : 0.0;

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
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: comebackPutts.map((putt) {
                        return Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: putt.made
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
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  PuttDetailsList(puttAttempts: comebackPutts),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllPuttsCard(BuildContext context, List<PuttAttempt> allPutts) {
    if (allPutts.isEmpty) {
      return const SizedBox.shrink();
    }

    final int totalMade = allPutts.where((putt) => putt.made).length;
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
                  return Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: putt.made
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
              child: PuttDetailsList(puttAttempts: allPutts),
            ),
          ],
        ),
      ),
    );
  }
}
