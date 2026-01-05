import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/drives_tab/models/throw_type_stats.dart';
import 'package:turbo_disc_golf/services/round_statistics_service.dart';

/// Compact throw type comparison card for story context
/// Shows backhand vs forehand performance side-by-side
class ThrowTypeStoryCard extends StatelessWidget {
  const ThrowTypeStoryCard({super.key, required this.round});

  final DGRound round;

  @override
  Widget build(BuildContext context) {
    final RoundStatisticsService statsService = RoundStatisticsService(round);
    final Map<String, dynamic> teeShotBirdieRates =
        statsService.getTeeShotBirdieRateStats();
    final Map<String, Map<String, double>> circleInRegByType =
        statsService.getCircleInRegByThrowType();
    final Map<String, List<MapEntry<DGHole, DiscThrow>>> allTeeShotsByType =
        statsService.getAllTeeShotsByType();

    // Calculate stats for backhand and forehand
    final ThrowTypeStats backhandStats = _calculateThrowTypeStats(
      'backhand',
      teeShotBirdieRates,
      circleInRegByType,
      allTeeShotsByType,
    );
    final ThrowTypeStats forehandStats = _calculateThrowTypeStats(
      'forehand',
      teeShotBirdieRates,
      circleInRegByType,
      allTeeShotsByType,
    );

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _ThrowTypeColumn(
                stats: backhandStats,
                color: const Color(0xFF2196F3),
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
            Expanded(
              child: _ThrowTypeColumn(
                stats: forehandStats,
                color: const Color(0xFF9C27B0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ThrowTypeStats _calculateThrowTypeStats(
    String throwType,
    Map<String, dynamic> teeShotBirdieRates,
    Map<String, Map<String, double>> circleInRegByType,
    Map<String, List<MapEntry<DGHole, DiscThrow>>> allTeeShotsByType,
  ) {
    final dynamic birdieData = teeShotBirdieRates[throwType];
    final Map<String, double>? c1c2Data = circleInRegByType[throwType];

    if (birdieData == null || c1c2Data == null) {
      return ThrowTypeStats(
        throwType: throwType,
        birdieRate: 0,
        birdieCount: 0,
        totalHoles: 0,
        c1InRegPct: 0,
        c1Count: 0,
        c1Total: 0,
        c2InRegPct: 0,
        c2Count: 0,
        c2Total: 0,
      );
    }

    return ThrowTypeStats(
      throwType: throwType,
      birdieRate: birdieData.percentage,
      birdieCount: birdieData.birdieCount,
      totalHoles: birdieData.totalAttempts,
      c1InRegPct: c1c2Data['c1Percentage'] ?? 0,
      c1Count: (c1c2Data['c1Count'] ?? 0).toInt(),
      c1Total: (c1c2Data['totalAttempts'] ?? 0).toInt(),
      c2InRegPct: c1c2Data['c2Percentage'] ?? 0,
      c2Count: (c1c2Data['c2Count'] ?? 0).toInt(),
      c2Total: (c1c2Data['totalAttempts'] ?? 0).toInt(),
    );
  }
}

class _ThrowTypeColumn extends StatelessWidget {
  const _ThrowTypeColumn({
    required this.stats,
    required this.color,
  });

  final ThrowTypeStats stats;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            stats.displayName.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: color,
                ),
          ),
          const SizedBox(height: 12),
          _buildBirdieRate(context),
          const SizedBox(height: 16),
          _buildStatRow(
            context,
            label: 'C1 in Reg',
            percentage: stats.c1InRegPct,
            count: stats.c1Count,
            total: stats.c1Total,
          ),
        ],
      ),
    );
  }

  Widget _buildBirdieRate(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: color,
              width: 2.5,
            ),
          ),
          child: Center(
            child: Text(
              '${stats.birdieRate.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 20,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Birdie Rate',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
        ),
        Text(
          '${stats.birdieCount}/${stats.totalHoles}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
        ),
      ],
    );
  }

  Widget _buildStatRow(
    BuildContext context, {
    required String label,
    required double percentage,
    required int count,
    required int total,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
            ),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 6,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 2),
        Center(
          child: Text(
            '($count/$total)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
          ),
        ),
      ],
    );
  }
}
