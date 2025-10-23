import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/deep_analysis/components/core_stats_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/deep_analysis/components/disc_performance_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/deep_analysis/components/mistake_reason_breakdown_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/deep_analysis/components/putting_distance_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/deep_analysis/components/putting_summary_cards.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/deep_analysis/components/shot_type_birdie_rates_card.dart';
import 'package:turbo_disc_golf/services/multi_round_statistics_service.dart';
import 'package:turbo_disc_golf/services/rounds_service.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final RoundsService _roundsService = locator.get<RoundsService>();
  int _selectedRoundCount = 10; // Default to last 10 rounds

  final List<int> _roundCountOptions = [
    5,
    10,
    15,
    20,
    -1,
  ]; // -1 means all rounds

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<DGRound>>(
      valueListenable: _roundsService.roundsNotifier,
      builder: (context, allRounds, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: _roundsService.isLoading,
          builder: (context, isLoading, _) {
            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (allRounds.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 80,
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No rounds available',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Play some rounds to see your stats!',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }

            // Get filtered rounds based on selection
            final filteredRounds = _selectedRoundCount == -1
                ? allRounds
                : _roundsService.getLastXRounds(_selectedRoundCount);

            if (filteredRounds.isEmpty) {
              return const Center(
                child: Text('No rounds match the selected filter'),
              );
            }

            // Create statistics service for filtered rounds
            final statsService = MultiRoundStatisticsService(filteredRounds);

            // Calculate all stats
            final scoringStats = statsService.getScoringStats();
            final puttingStats = statsService.getPuttingStats();
            final coreStats = statsService.getCoreStats();
            final teeShotBirdieRates = statsService.getTeeShotBirdieRates();
            final discPerformances = statsService.getDiscPerformanceSummaries();
            final mistakeTypes = statsService.getMistakeTypes();
            final avgBirdiePuttDistance = statsService
                .getAverageBirdiePuttDistance();
            final avgScoreRelativeToPar = statsService
                .getAverageScoreRelativeToPar();
            final backhandVsForehand = statsService
                .compareBackhandVsForehandTeeShots();
            final scrambleStats = statsService.getScrambleStats();

            return Column(
              children: [
                // Filter dropdown
                _buildFilterBar(context, allRounds.length),

                // Stats content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(top: 16, bottom: 80),
                    children: addRunSpacing(
                      [
                        // Overview card
                        _buildOverviewCard(
                          context,
                          filteredRounds.length,
                          statsService.getTotalHolesPlayed(),
                          avgScoreRelativeToPar,
                        ),

                        // Scoring stats
                        _buildScoringStatsCard(context, scoringStats),

                        // Core performance
                        CoreStatsCard(coreStats: coreStats),

                        // Tee shot birdie rates
                        if (teeShotBirdieRates.isNotEmpty)
                          ShotTypeBirdieRatesCard(
                            teeShotBirdieRateStats: teeShotBirdieRates,
                            teeShotBirdieDetails:
                                const {}, // Not showing details in multi-round view
                          ),

                        // Backhand vs Forehand comparison
                        if (backhandVsForehand.technique1Count > 0 ||
                            backhandVsForehand.technique2Count > 0)
                          _buildTechniqueComparisonCard(
                            context,
                            backhandVsForehand,
                          ),

                        // Putting summary
                        if (puttingStats.totalAttempts > 0)
                          PuttingSummaryCards(puttingSummary: puttingStats),

                        // Putting distance stats
                        if (puttingStats.totalAttempts > 0)
                          PuttingDistanceCard(
                            avgMakeDistance: puttingStats.avgMakeDistance,
                            avgAttemptDistance: puttingStats.avgAttemptDistance,
                            avgBirdiePuttDistance: avgBirdiePuttDistance,
                            totalMadeDistance: puttingStats.totalMadeDistance,
                          ),

                        // Scramble stats
                        if (scrambleStats.scrambleOpportunities > 0)
                          _buildScrambleStatsCard(context, scrambleStats),

                        // Disc performance
                        if (discPerformances.isNotEmpty)
                          DiscPerformanceCard(
                            discPerformances: discPerformances,
                          ),

                        // Mistakes breakdown
                        if (mistakeTypes.isNotEmpty)
                          MistakeReasonBreakdownCard(
                            mistakeTypes: mistakeTypes,
                          ),
                      ],
                      runSpacing: 12,
                      axis: Axis.vertical,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFilterBar(BuildContext context, int totalRounds) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Show stats for:',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<int>(
              value: _selectedRoundCount,
              isExpanded: true,
              underline: Container(),
              items: _roundCountOptions.map((count) {
                String label;
                if (count == -1) {
                  label = 'All rounds ($totalRounds)';
                } else {
                  final actualCount = count > totalRounds ? totalRounds : count;
                  label =
                      'Last $actualCount round${actualCount == 1 ? '' : 's'}';
                }
                return DropdownMenuItem<int>(value: count, child: Text(label));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedRoundCount = value;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(
    BuildContext context,
    int roundCount,
    int totalHoles,
    double avgScoreRelativeToPar,
  ) {
    final scoreText = avgScoreRelativeToPar == 0
        ? 'E'
        : avgScoreRelativeToPar > 0
        ? '+${avgScoreRelativeToPar.toStringAsFixed(1)}'
        : avgScoreRelativeToPar.toStringAsFixed(1);

    Color scoreColor;
    if (avgScoreRelativeToPar <= -2) {
      scoreColor = Colors.purple;
    } else if (avgScoreRelativeToPar < 0) {
      scoreColor = Colors.blue;
    } else if (avgScoreRelativeToPar == 0) {
      scoreColor = Colors.green;
    } else if (avgScoreRelativeToPar <= 2) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Statistics Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOverviewStat(
                context,
                'Rounds',
                roundCount.toString(),
                Icons.golf_course,
              ),
              _buildOverviewStat(
                context,
                'Total Holes',
                totalHoles.toString(),
                Icons.flag,
              ),
              _buildOverviewStat(
                context,
                'Avg Score',
                scoreText,
                Icons.trending_up,
                valueColor: scoreColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStat(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: valueColor ?? Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color:
                valueColor ?? Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildScoringStatsCard(BuildContext context, ScoringStats stats) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scoring Summary',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildScoringStatRow(
            context,
            'Birdies',
            stats.birdies,
            stats.birdieRate,
            Colors.blue,
          ),
          const SizedBox(height: 8),
          _buildScoringStatRow(
            context,
            'Pars',
            stats.pars,
            stats.parRate,
            Colors.green,
          ),
          const SizedBox(height: 8),
          _buildScoringStatRow(
            context,
            'Bogeys',
            stats.bogeys,
            stats.bogeyRate,
            Colors.orange,
          ),
          const SizedBox(height: 8),
          _buildScoringStatRow(
            context,
            'Double Bogey+',
            stats.doubleBogeyPlus,
            stats.doubleBogeyPlusRate,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildScoringStatRow(
    BuildContext context,
    String label,
    int count,
    double percentage,
    Color color,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text(
            '$count',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 12,
              backgroundColor: color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 50,
          child: Text(
            '${percentage.toStringAsFixed(1)}%',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTechniqueComparisonCard(
    BuildContext context,
    ComparisonResult comparison,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tee Shot Technique Comparison',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTechniqueColumn(
                  context,
                  comparison.technique1,
                  comparison.technique1BirdieRate,
                  comparison.technique1Count,
                  const Color(0xFF137e66),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTechniqueColumn(
                  context,
                  comparison.technique2,
                  comparison.technique2BirdieRate,
                  comparison.technique2Count,
                  const Color(0xFFFF7A7A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTechniqueColumn(
    BuildContext context,
    String technique,
    double birdieRate,
    int attempts,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            technique,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${birdieRate.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text('birdie rate', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(
            '$attempts attempts',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildScrambleStatsCard(BuildContext context, ScrambleStats stats) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scramble Performance',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '${stats.scrambleRate.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                  Text(
                    'Scramble Rate',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    '${stats.scrambleSaves}/${stats.scrambleOpportunities}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Saves / Opportunities',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
