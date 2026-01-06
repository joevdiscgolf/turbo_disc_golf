import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/drives_tab/models/throw_type_stats.dart';
import 'package:turbo_disc_golf/services/round_statistics_service.dart';
import 'package:turbo_disc_golf/utils/color_helpers.dart';
import 'package:turbo_disc_golf/widgets/circular_stat_indicator.dart';

/// Compact throw type comparison card for story context
/// Shows two throw techniques' performance side-by-side
class ThrowTypeStoryCard extends StatelessWidget {
  const ThrowTypeStoryCard({
    super.key,
    required this.round,
    this.technique1 = ThrowTechnique.backhand,
    this.technique2 = ThrowTechnique.forehand,
    this.technique1Color = const Color(0xFF2196F3),
    this.technique2Color = const Color(0xFF9C27B0),
  });

  final DGRound round;
  final ThrowTechnique technique1;
  final ThrowTechnique technique2;
  final Color technique1Color;
  final Color technique2Color;

  @override
  Widget build(BuildContext context) {
    final RoundStatisticsService statsService = RoundStatisticsService(round);
    final Map<String, dynamic> teeShotBirdieRates =
        statsService.getTeeShotBirdieRateStats();
    final Map<String, Map<String, double>> circleInRegByType =
        statsService.getCircleInRegByThrowType();
    final Map<String, List<MapEntry<DGHole, DiscThrow>>> allTeeShotsByType =
        statsService.getAllTeeShotsByType();

    // Calculate stats for both techniques
    final ThrowTypeStats stats1 = _calculateThrowTypeStats(
      _techniqueToKey(technique1),
      teeShotBirdieRates,
      circleInRegByType,
      allTeeShotsByType,
    );
    final ThrowTypeStats stats2 = _calculateThrowTypeStats(
      _techniqueToKey(technique2),
      teeShotBirdieRates,
      circleInRegByType,
      allTeeShotsByType,
    );

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TurbColors.gray[100]!),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _ThrowTypeColumn(
                stats: stats1,
                color: technique1Color,
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: TurbColors.gray[100],
            ),
            Expanded(
              child: _ThrowTypeColumn(
                stats: stats2,
                color: technique2Color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Converts ThrowTechnique enum to the string key used in stats maps
  String _techniqueToKey(ThrowTechnique technique) {
    switch (technique) {
      case ThrowTechnique.backhand:
        return 'backhand';
      case ThrowTechnique.forehand:
        return 'forehand';
      case ThrowTechnique.tomahawk:
        return 'tomahawk';
      case ThrowTechnique.thumber:
        return 'thumber';
      case ThrowTechnique.overhand:
        return 'overhand';
      case ThrowTechnique.backhandRoller:
        return 'backhand_roller';
      case ThrowTechnique.forehandRoller:
        return 'forehand_roller';
      case ThrowTechnique.grenade:
        return 'grenade';
      case ThrowTechnique.other:
        return 'other';
    }
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
        children: [
          // Label
          Text(
            stats.displayName,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
          ),
          const SizedBox(height: 8),
          // Birdie rate circle
          CircularStatIndicator(
            label: 'Birdie Rate',
            percentage: stats.birdieRate,
            color: color,
            size: 80,
            strokeWidth: 5,
            percentageFontSize: 22,
            internalLabel: '${stats.birdieCount}/${stats.totalHoles}',
            internalLabelFontSize: 10,
            labelFontSize: 11,
            labelSpacing: 8,
          ),
          const SizedBox(height: 12),
          // C1 in Reg bar
          _buildC1InRegBar(context),
        ],
      ),
    );
  }

  Widget _buildC1InRegBar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'C1 in Reg',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
            ),
            Row(
              children: [
                Text(
                  '${stats.c1InRegPct.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 12,
                      ),
                ),
                const SizedBox(width: 3),
                Text(
                  '(${stats.c1Count}/${stats.c1Total})',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: TurbColors.gray[400],
                        fontSize: 10,
                      ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: stats.c1InRegPct / 100,
            minHeight: 6,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
