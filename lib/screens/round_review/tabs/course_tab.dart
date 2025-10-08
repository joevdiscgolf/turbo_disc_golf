import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/services/round_statistics_service.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

class CourseTab extends StatelessWidget {
  final DGRound round;

  const CourseTab({super.key, required this.round});

  @override
  Widget build(BuildContext context) {
    final RoundStatisticsService statsService = RoundStatisticsService(round);

    final scoringStats = statsService.getScoringStats();
    final totalScore = statsService.getTotalScoreRelativeToPar();
    final bounceBackPct = statsService.getBounceBackPercentage();
    final birdieRateByPar = statsService.getBirdieRateByPar();
    final birdieRateByLength = statsService.getBirdieRateByHoleLength();
    final avgBirdieDistance = statsService.getAverageBirdieHoleDistance();

    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 80),
      children: addRunSpacing(
        [
          _buildScoreSummary(context, totalScore, scoringStats, bounceBackPct),
          _buildScoreDistribution(context, scoringStats),
          _buildBirdieTrends(
            context,
            birdieRateByPar,
            birdieRateByLength,
            avgBirdieDistance,
          ),
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                  'Pars',
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '$count (${percentage.toStringAsFixed(0)}%)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Birdie Trends',
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
                Text(
                  'Birdie % by Par',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
                  'Birdie % by Hole Length',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                ...birdieRateByLength.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key),
                        Text(
                          '${entry.value.toStringAsFixed(0)}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
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
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
