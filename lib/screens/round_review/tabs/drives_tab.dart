import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/services/round_statistics_service.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';

class DrivesTab extends StatelessWidget {
  final DGRound round;

  const DrivesTab({super.key, required this.round});

  @override
  Widget build(BuildContext context) {
    final RoundStatisticsService statsService = RoundStatisticsService(round);

    final coreStats = statsService.getCoreStats();
    final teeShotBirdieRates = statsService.getTeeShotBirdieRateStats();
    final allTeeShotsByType = statsService.getAllTeeShotsByType();
    final circleInRegByType = statsService.getCircleInRegByThrowType();
    // final techniqueComparison = statsService.getTechniqueComparison();
    final shotShapeBirdieRates = statsService
        .getShotShapeByTechniqueBirdieRateStats();
    final circleInRegByShape = statsService
        .getCircleInRegByShotShapeAndTechnique();
    final performanceByFairwayWidth = statsService
        .getPerformanceByFairwayWidth();

    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 80),
      children: addRunSpacing(
        [
          _buildCoreStatsKPIs(context, coreStats),

          _buildOverallC1InRegCard(context, coreStats),
          _buildOverallC2InRegCard(context, coreStats),
          _buildOverallParkedCard(context, coreStats),
          _buildOverallOBCard(context, coreStats),

          _buildBirdieRateByThrowType(
            context,
            teeShotBirdieRates,
            allTeeShotsByType,
          ),
          _buildC1InRegByThrowType(
            context,
            circleInRegByType,
            allTeeShotsByType,
          ),
          _buildC2InRegByThrowType(
            context,
            circleInRegByType,
            allTeeShotsByType,
          ),
          _buildShotShapeAndTechniqueCard(
            context,
            shotShapeBirdieRates,
            circleInRegByShape,
          ),
          if (performanceByFairwayWidth.isNotEmpty)
            _buildPerformanceByFairwayWidth(context, performanceByFairwayWidth),
          _buildInsightCard(context, teeShotBirdieRates),
        ],
        runSpacing: 16,
        axis: Axis.vertical,
      ),
    );
  }

  Widget _buildCoreStatsKPIs(BuildContext context, coreStats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Driving Performance',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildKPICard(
                  context,
                  'Fairway Hit',
                  '${coreStats.fairwayHitPct.toStringAsFixed(0)}%',
                  const Color(0xFF4CAF50),
                ),
                _buildKPICard(
                  context,
                  'C1 in Reg',
                  '${coreStats.c1InRegPct.toStringAsFixed(0)}%',
                  const Color(0xFF00F5D4),
                ),
                _buildKPICard(
                  context,
                  'C2 in Reg',
                  '${coreStats.c2InRegPct.toStringAsFixed(0)}%',
                  const Color(0xFF2196F3),
                ),
                _buildKPICard(
                  context,
                  'OB',
                  '${coreStats.obPct.toStringAsFixed(0)}%',
                  const Color(0xFFFF7A7A),
                ),
                _buildKPICard(
                  context,
                  'Parked',
                  '${coreStats.parkedPct.toStringAsFixed(0)}%',
                  const Color(0xFFFFA726),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICard(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
      ),
    );
  }

  Widget _buildBirdieRateByThrowType(
    BuildContext context,
    Map<String, dynamic> teeShotBirdieRates,
    Map<String, List<MapEntry<DGHole, DiscThrow>>> allTeeShotsByType,
  ) {
    if (teeShotBirdieRates.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedEntries = teeShotBirdieRates.entries.toList()
      ..sort((a, b) => b.value.percentage.compareTo(a.value.percentage));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Birdie Rate by Throw Type',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...sortedEntries.map((entry) {
              final technique = entry.key;
              final stats = entry.value;
              final percentage = stats.percentage;
              final allThrows = allTeeShotsByType[technique] ?? [];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(top: 8),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          technique.substring(0, 1).toUpperCase() +
                              technique.substring(1),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '${percentage.toStringAsFixed(0)}% (${stats.birdieCount}/${stats.totalAttempts})',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          minHeight: 12,
                          backgroundColor: const Color(
                            0xFF00F5D4,
                          ).withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF00F5D4),
                          ),
                        ),
                      ),
                    ),
                    children: [
                      if (allThrows.isNotEmpty) ...[
                        const Divider(),
                        () {
                          final birdieThrows = allThrows
                              .where((e) => e.key.relativeHoleScore < 0)
                              .toList();
                          final nonBirdieThrows = allThrows
                              .where((e) => e.key.relativeHoleScore >= 0)
                              .toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (birdieThrows.isNotEmpty) ...[
                                Text(
                                  'Birdie Throws (${birdieThrows.length})',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                ...birdieThrows.map((entry) {
                                  final hole = entry.key;
                                  final teeShot = entry.value;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF00F5D4),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${hole.number}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Hole ${hole.number} - Par ${hole.par}${hole.feet != null ? ' • ${hole.feet} ft' : ''}',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ),
                                        if (teeShot.landingSpot != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF00F5D4,
                                              ).withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _landingSpotLabel(
                                                teeShot.landingSpot!,
                                              ),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    fontSize: 10,
                                                    color: const Color(
                                                      0xFF00F5D4,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                              if (birdieThrows.isNotEmpty &&
                                  nonBirdieThrows.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 8),
                              ],
                              if (nonBirdieThrows.isNotEmpty) ...[
                                Text(
                                  'Other Throws (${nonBirdieThrows.length})',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                ...nonBirdieThrows.map((entry) {
                                  final hole = entry.key;
                                  final teeShot = entry.value;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${hole.number}',
                                              style: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Hole ${hole.number} - Par ${hole.par}${hole.feet != null ? ' • ${hole.feet} ft' : ''}',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ),
                                        if (teeShot.landingSpot != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _landingSpotLabel(
                                                teeShot.landingSpot!,
                                              ),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    fontSize: 10,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface,
                                                  ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ],
                          );
                        }(),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _landingSpotLabel(LandingSpot spot) {
    switch (spot) {
      case LandingSpot.parked:
        return 'Parked';
      case LandingSpot.circle1:
        return 'C1';
      case LandingSpot.circle2:
        return 'C2';
      case LandingSpot.fairway:
        return 'Fairway';
      default:
        return '';
    }
  }

  String _scoreLabel(int relativeHoleScore) {
    if (relativeHoleScore <= -3) {
      return 'Albatross';
    } else if (relativeHoleScore == -2) {
      return 'Eagle';
    } else if (relativeHoleScore == -1) {
      return 'Birdie';
    } else if (relativeHoleScore == 0) {
      return 'Par';
    } else if (relativeHoleScore == 1) {
      return 'Bogey';
    } else if (relativeHoleScore == 2) {
      return 'Double Bogey';
    } else if (relativeHoleScore == 3) {
      return 'Triple Bogey';
    } else {
      return '+$relativeHoleScore';
    }
  }

  Widget _buildOverallC1InRegCard(BuildContext context, coreStats) {
    final c1InRegPct = coreStats.c1InRegPct;

    // Calculate which holes reached C1 in regulation
    final c1InRegHoles = <DGHole>[];
    final notC1InRegHoles = <DGHole>[];

    for (final hole in round.holes) {
      final regulationStrokes = hole.par - 2;
      bool reachedC1 = false;

      if (regulationStrokes > 0) {
        for (int i = 0; i < hole.throws.length && i < regulationStrokes; i++) {
          final discThrow = hole.throws[i];
          if (discThrow.landingSpot == LandingSpot.circle1 ||
              discThrow.landingSpot == LandingSpot.parked) {
            reachedC1 = true;
            break;
          }
        }
      }

      if (reachedC1) {
        c1InRegHoles.add(hole);
      } else {
        notC1InRegHoles.add(hole);
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(top: 8),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'C1 in Regulation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${c1InRegPct.toStringAsFixed(0)}% (${c1InRegHoles.length}/${round.holes.length})',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Holes where you reached C1 with a chance for birdie',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: c1InRegPct / 100,
                      minHeight: 12,
                      backgroundColor:
                          const Color(0xFF00F5D4).withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF00F5D4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            children: [
              const Divider(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (c1InRegHoles.isNotEmpty) ...[
                    Text(
                      'C1 in Reg (${c1InRegHoles.length})',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...c1InRegHoles.map((hole) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00F5D4),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${hole.number}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Hole ${hole.number} - Par ${hole.par}${hole.feet != null ? ' • ${hole.feet} ft' : ''}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00F5D4)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _scoreLabel(hole.relativeHoleScore),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontSize: 10,
                                      color: const Color(0xFF00F5D4),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  if (c1InRegHoles.isNotEmpty && notC1InRegHoles.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                  ],
                  if (notC1InRegHoles.isNotEmpty) ...[
                    Text(
                      'Not C1 in Reg (${notC1InRegHoles.length})',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...notC1InRegHoles.map((hole) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${hole.number}',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Hole ${hole.number} - Par ${hole.par}${hole.feet != null ? ' • ${hole.feet} ft' : ''}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _scoreLabel(hole.relativeHoleScore),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontSize: 10,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverallC2InRegCard(BuildContext context, coreStats) {
    final c2InRegPct = coreStats.c2InRegPct;

    // Calculate which holes reached C2 in regulation
    final c2InRegHoles = <DGHole>[];
    final notC2InRegHoles = <DGHole>[];

    for (final hole in round.holes) {
      final regulationStrokes = hole.par - 2;
      bool reachedC2 = false;

      if (regulationStrokes > 0) {
        for (int i = 0; i < hole.throws.length && i < regulationStrokes; i++) {
          final discThrow = hole.throws[i];
          if (discThrow.landingSpot == LandingSpot.circle1 ||
              discThrow.landingSpot == LandingSpot.parked ||
              discThrow.landingSpot == LandingSpot.circle2) {
            reachedC2 = true;
            break;
          }
        }
      }

      if (reachedC2) {
        c2InRegHoles.add(hole);
      } else {
        notC2InRegHoles.add(hole);
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(top: 8),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'C2 in Regulation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${c2InRegPct.toStringAsFixed(0)}% (${c2InRegHoles.length}/${round.holes.length})',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Holes where you reached C2 with a chance for birdie',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: c2InRegPct / 100,
                      minHeight: 12,
                      backgroundColor:
                          const Color(0xFF2196F3).withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF2196F3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            children: [
              const Divider(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (c2InRegHoles.isNotEmpty) ...[
                    Text(
                      'C2 in Reg (${c2InRegHoles.length})',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...c2InRegHoles.map((hole) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Color(0xFF2196F3),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${hole.number}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Hole ${hole.number} - Par ${hole.par}${hole.feet != null ? ' • ${hole.feet} ft' : ''}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2196F3)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _scoreLabel(hole.relativeHoleScore),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontSize: 10,
                                      color: const Color(0xFF2196F3),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  if (c2InRegHoles.isNotEmpty && notC2InRegHoles.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                  ],
                  if (notC2InRegHoles.isNotEmpty) ...[
                    Text(
                      'Not C2 in Reg (${notC2InRegHoles.length})',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...notC2InRegHoles.map((hole) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${hole.number}',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Hole ${hole.number} - Par ${hole.par}${hole.feet != null ? ' • ${hole.feet} ft' : ''}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _scoreLabel(hole.relativeHoleScore),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontSize: 10,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverallParkedCard(BuildContext context, coreStats) {
    final parkedPct = coreStats.parkedPct;

    // Calculate which holes had parked throws
    final parkedHoles = <DGHole>[];
    final notParkedHoles = <DGHole>[];

    for (final hole in round.holes) {
      bool hadParkedThrow = false;

      for (final discThrow in hole.throws) {
        if (discThrow.landingSpot == LandingSpot.parked) {
          hadParkedThrow = true;
          break;
        }
      }

      if (hadParkedThrow) {
        parkedHoles.add(hole);
      } else {
        notParkedHoles.add(hole);
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(top: 8),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Parked',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${parkedPct.toStringAsFixed(0)}% (${parkedHoles.length}/${round.holes.length})',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Holes where you parked your disc (within 10 ft)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: parkedPct / 100,
                      minHeight: 12,
                      backgroundColor:
                          const Color(0xFFFFA726).withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFFFA726),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            children: [
              const Divider(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (parkedHoles.isNotEmpty) ...[
                    Text(
                      'Parked (${parkedHoles.length})',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...parkedHoles.map((hole) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFA726),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${hole.number}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Hole ${hole.number} - Par ${hole.par}${hole.feet != null ? ' • ${hole.feet} ft' : ''}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFA726)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _scoreLabel(hole.relativeHoleScore),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontSize: 10,
                                      color: const Color(0xFFFFA726),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  if (parkedHoles.isNotEmpty && notParkedHoles.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                  ],
                  if (notParkedHoles.isNotEmpty) ...[
                    Text(
                      'Not Parked (${notParkedHoles.length})',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...notParkedHoles.map((hole) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${hole.number}',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Hole ${hole.number} - Par ${hole.par}${hole.feet != null ? ' • ${hole.feet} ft' : ''}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _scoreLabel(hole.relativeHoleScore),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontSize: 10,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverallOBCard(BuildContext context, coreStats) {
    final obPct = coreStats.obPct;

    // Calculate which holes had OB throws
    final obHoles = <DGHole>[];
    final notOBHoles = <DGHole>[];

    for (final hole in round.holes) {
      bool hadOBThrow = false;

      for (final discThrow in hole.throws) {
        if (discThrow.landingSpot == LandingSpot.outOfBounds) {
          hadOBThrow = true;
          break;
        }
      }

      if (hadOBThrow) {
        obHoles.add(hole);
      } else {
        notOBHoles.add(hole);
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(top: 8),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Out of Bounds',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${obPct.toStringAsFixed(0)}% (${obHoles.length}/${round.holes.length})',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Holes where you went out of bounds',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: obPct / 100,
                      minHeight: 12,
                      backgroundColor:
                          const Color(0xFFFF7A7A).withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFFF7A7A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            children: [
              const Divider(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (obHoles.isNotEmpty) ...[
                    Text(
                      'OB (${obHoles.length})',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...obHoles.map((hole) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF7A7A),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${hole.number}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Hole ${hole.number} - Par ${hole.par}${hole.feet != null ? ' • ${hole.feet} ft' : ''}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF7A7A)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _scoreLabel(hole.relativeHoleScore),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontSize: 10,
                                      color: const Color(0xFFFF7A7A),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  if (obHoles.isNotEmpty && notOBHoles.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                  ],
                  if (notOBHoles.isNotEmpty) ...[
                    Text(
                      'No OB (${notOBHoles.length})',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...notOBHoles.map((hole) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${hole.number}',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Hole ${hole.number} - Par ${hole.par}${hole.feet != null ? ' • ${hole.feet} ft' : ''}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _scoreLabel(hole.relativeHoleScore),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontSize: 10,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildC1InRegByThrowType(
    BuildContext context,
    Map<String, Map<String, double>> circleInRegByType,
    Map<String, List<MapEntry<DGHole, DiscThrow>>> allTeeShotsByType,
  ) {
    if (circleInRegByType.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedEntries = circleInRegByType.entries.toList()
      ..sort(
        (a, b) => b.value['c1Percentage']!.compareTo(a.value['c1Percentage']!),
      );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'C1 in Regulation by Throw Type',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Holes where you reached C1 with a chance for birdie',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedEntries.map((entry) {
              final technique = entry.key;
              final stats = entry.value;
              final c1Percentage = stats['c1Percentage']!;
              final totalAttempts = stats['totalAttempts']!.toInt();
              final c1Count = stats['c1Count']!.toInt();
              final allThrows = allTeeShotsByType[technique] ?? [];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(top: 8),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          technique.substring(0, 1).toUpperCase() +
                              technique.substring(1),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '${c1Percentage.toStringAsFixed(0)}% ($c1Count/$totalAttempts)',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: c1Percentage / 100,
                          minHeight: 12,
                          backgroundColor: const Color(
                            0xFF4CAF50,
                          ).withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                    ),
                    children: [
                      if (allThrows.isNotEmpty) ...[
                        const Divider(),
                        () {
                          final c1Throws = <MapEntry<DGHole, DiscThrow>>[];
                          final nonC1Throws = <MapEntry<DGHole, DiscThrow>>[];

                          for (final entry in allThrows) {
                            final hole = entry.key;
                            final regulationStrokes = hole.par - 2;
                            bool reachedC1 = false;

                            if (regulationStrokes > 0) {
                              for (
                                int i = 0;
                                i < hole.throws.length && i < regulationStrokes;
                                i++
                              ) {
                                final discThrow = hole.throws[i];
                                if (discThrow.landingSpot ==
                                        LandingSpot.circle1 ||
                                    discThrow.landingSpot ==
                                        LandingSpot.parked) {
                                  reachedC1 = true;
                                  break;
                                }
                              }
                            }

                            if (reachedC1) {
                              c1Throws.add(entry);
                            } else {
                              nonC1Throws.add(entry);
                            }
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (c1Throws.isNotEmpty) ...[
                                Text(
                                  'C1 in Reg (${c1Throws.length})',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                ...c1Throws.map((entry) {
                                  final hole = entry.key;
                                  final teeShot = entry.value;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF4CAF50),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${hole.number}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Hole ${hole.number} - Par ${hole.par}${hole.feet != null ? ' • ${hole.feet} ft' : ''}',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ),
                                        if (teeShot.landingSpot != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF4CAF50,
                                              ).withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _landingSpotLabel(
                                                teeShot.landingSpot!,
                                              ),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    fontSize: 10,
                                                    color: const Color(
                                                      0xFF4CAF50,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                              if (c1Throws.isNotEmpty &&
                                  nonC1Throws.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 8),
                              ],
                              if (nonC1Throws.isNotEmpty) ...[
                                Text(
                                  'Other Throws (${nonC1Throws.length})',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                ...nonC1Throws.map((entry) {
                                  final hole = entry.key;
                                  final teeShot = entry.value;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${hole.number}',
                                              style: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Hole ${hole.number} - Par ${hole.par}${hole.feet != null ? ' • ${hole.feet} ft' : ''}',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ),
                                        if (teeShot.landingSpot != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _landingSpotLabel(
                                                teeShot.landingSpot!,
                                              ),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    fontSize: 10,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface,
                                                  ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ],
                          );
                        }(),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildC2InRegByThrowType(
    BuildContext context,
    Map<String, Map<String, double>> circleInRegByType,
    Map<String, List<MapEntry<DGHole, DiscThrow>>> allTeeShotsByType,
  ) {
    if (circleInRegByType.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedEntries = circleInRegByType.entries.toList()
      ..sort(
        (a, b) => b.value['c2Percentage']!.compareTo(a.value['c2Percentage']!),
      );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'C2 in Regulation by Throw Type',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Holes where you reached C2 with a chance for birdie',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedEntries.map((entry) {
              final technique = entry.key;
              final stats = entry.value;
              final c2Percentage = stats['c2Percentage']!;
              final totalAttempts = stats['totalAttempts']!.toInt();
              final c2Count = stats['c2Count']!.toInt();
              final allThrows = allTeeShotsByType[technique] ?? [];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(top: 8),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          technique.substring(0, 1).toUpperCase() +
                              technique.substring(1),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '${c2Percentage.toStringAsFixed(0)}% ($c2Count/$totalAttempts)',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: c2Percentage / 100,
                          minHeight: 12,
                          backgroundColor: const Color(
                            0xFF2196F3,
                          ).withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF2196F3),
                          ),
                        ),
                      ),
                    ),
                    children: [
                      if (allThrows.isNotEmpty) ...[
                        const Divider(),
                        () {
                          final c2Throws = <MapEntry<DGHole, DiscThrow>>[];
                          final nonC2Throws = <MapEntry<DGHole, DiscThrow>>[];

                          for (final entry in allThrows) {
                            final hole = entry.key;
                            final regulationStrokes = hole.par - 2;
                            bool reachedC2 = false;

                            if (regulationStrokes > 0) {
                              for (
                                int i = 0;
                                i < hole.throws.length && i < regulationStrokes;
                                i++
                              ) {
                                final discThrow = hole.throws[i];
                                if (discThrow.landingSpot ==
                                        LandingSpot.circle1 ||
                                    discThrow.landingSpot ==
                                        LandingSpot.parked ||
                                    discThrow.landingSpot ==
                                        LandingSpot.circle2) {
                                  reachedC2 = true;
                                  break;
                                }
                              }
                            }

                            if (reachedC2) {
                              c2Throws.add(entry);
                            } else {
                              nonC2Throws.add(entry);
                            }
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (c2Throws.isNotEmpty) ...[
                                Text(
                                  'C2 in Reg (${c2Throws.length})',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                ...c2Throws.map((entry) {
                                  final hole = entry.key;
                                  final teeShot = entry.value;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF2196F3),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${hole.number}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Hole ${hole.number} - Par ${hole.par}${hole.feet != null ? ' • ${hole.feet} ft' : ''}',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ),
                                        if (teeShot.landingSpot != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF2196F3,
                                              ).withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _landingSpotLabel(
                                                teeShot.landingSpot!,
                                              ),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    fontSize: 10,
                                                    color: const Color(
                                                      0xFF2196F3,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                              if (c2Throws.isNotEmpty &&
                                  nonC2Throws.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 8),
                              ],
                              if (nonC2Throws.isNotEmpty) ...[
                                Text(
                                  'Other Throws (${nonC2Throws.length})',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                ...nonC2Throws.map((entry) {
                                  final hole = entry.key;
                                  final teeShot = entry.value;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${hole.number}',
                                              style: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Hole ${hole.number} - Par ${hole.par}${hole.feet != null ? ' • ${hole.feet} ft' : ''}',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ),
                                        if (teeShot.landingSpot != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _landingSpotLabel(
                                                teeShot.landingSpot!,
                                              ),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    fontSize: 10,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface,
                                                  ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ],
                          );
                        }(),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(
    BuildContext context,
    Map<String, dynamic> teeShotBirdieRates,
  ) {
    if (teeShotBirdieRates.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedEntries = teeShotBirdieRates.entries.toList()
      ..sort((a, b) => b.value.percentage.compareTo(a.value.percentage));

    if (sortedEntries.length < 2) {
      return const SizedBox.shrink();
    }

    final best = sortedEntries.first;
    final worst = sortedEntries.last;

    final bestName =
        best.key.substring(0, 1).toUpperCase() + best.key.substring(1);
    final worstName =
        worst.key.substring(0, 1).toUpperCase() + worst.key.substring(1);

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$bestName drives resulted in birdies ${best.value.percentage.toStringAsFixed(0)}% of the time vs ${worst.value.percentage.toStringAsFixed(0)}% for $worstName.',
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

  Widget _buildShotShapeAndTechniqueCard(
    BuildContext context,
    Map<String, dynamic> shotShapeBirdieRates,
    Map<String, Map<String, double>> circleInRegByShape,
  ) {
    // If no data available, don't show the card
    if (shotShapeBirdieRates.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shot Shape & Technique Success',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Technique Comparison Section - COMMENTED OUT
            // if (techniqueComparison.isNotEmpty) ...[
            //   Text(
            //     'Technique Comparison',
            //     style: Theme.of(
            //       context,
            //     ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            //   ),
            //   const SizedBox(height: 12),
            //   _buildTechniqueComparisonRows(context, techniqueComparison),
            // ],
            // Shot Shape Analysis Section
            if (shotShapeBirdieRates.isNotEmpty) ...[
              Text(
                'Shot Shape Performance',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildShotShapeRows(
                context,
                shotShapeBirdieRates,
                circleInRegByShape,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // COMMENTED OUT - Technique Comparison is no longer used
  // Widget _buildTechniqueComparisonRows(
  //   BuildContext context,
  //   Map<String, Map<String, double>> techniqueComparison,
  // ) {
  //   final backhand = techniqueComparison['backhand'];
  //   final forehand = techniqueComparison['forehand'];

  //   if (backhand == null && forehand == null) {
  //     return const SizedBox.shrink();
  //   }

  //   return Column(
  //     children: [
  //       _buildComparisonRow(
  //         context,
  //         'Birdie %',
  //         'Backhand',
  //         backhand?['birdiePercentage'] ?? 0,
  //         backhand?['totalAttempts']?.toInt() ?? 0,
  //         'Forehand',
  //         forehand?['birdiePercentage'] ?? 0,
  //         forehand?['totalAttempts']?.toInt() ?? 0,
  //         const Color(0xFF00F5D4),
  //       ),
  //       const SizedBox(height: 12),
  //       _buildComparisonRow(
  //         context,
  //         'C1 in Reg',
  //         'Backhand',
  //         backhand?['c1InRegPercentage'] ?? 0,
  //         backhand?['totalAttempts']?.toInt() ?? 0,
  //         'Forehand',
  //         forehand?['c1InRegPercentage'] ?? 0,
  //         forehand?['totalAttempts']?.toInt() ?? 0,
  //         const Color(0xFF4CAF50),
  //       ),
  //       const SizedBox(height: 12),
  //       _buildComparisonRow(
  //         context,
  //         'C2 in Reg',
  //         'Backhand',
  //         backhand?['c2InRegPercentage'] ?? 0,
  //         backhand?['totalAttempts']?.toInt() ?? 0,
  //         'Forehand',
  //         forehand?['c2InRegPercentage'] ?? 0,
  //         forehand?['totalAttempts']?.toInt() ?? 0,
  //         const Color(0xFF2196F3),
  //       ),
  //     ],
  //   );
  // }

  // COMMENTED OUT - Only used by technique comparison which is no longer active
  // Widget _buildComparisonRow(
  //   BuildContext context,
  //   String label,
  //   String technique1,
  //   double percentage1,
  //   int count1,
  //   String technique2,
  //   double percentage2,
  //   int count2,
  //   Color color,
  // ) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         label,
  //         style: Theme.of(
  //           context,
  //         ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
  //       ),
  //       const SizedBox(height: 8),
  //       Row(
  //         children: [
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Row(
  //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                   children: [
  //                     Text(
  //                       technique1,
  //                       style: Theme.of(context).textTheme.bodySmall,
  //                     ),
  //                     Text(
  //                       count1 > 0
  //                           ? '${percentage1.toStringAsFixed(0)}% ($count1)'
  //                           : 'No data',
  //                       style: Theme.of(context).textTheme.bodySmall?.copyWith(
  //                         fontWeight: FontWeight.bold,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //                 const SizedBox(height: 4),
  //                 if (count1 > 0)
  //                   ClipRRect(
  //                     borderRadius: BorderRadius.circular(4),
  //                     child: LinearProgressIndicator(
  //                       value: percentage1 / 100,
  //                       minHeight: 8,
  //                       backgroundColor: color.withValues(alpha: 0.2),
  //                       valueColor: AlwaysStoppedAnimation<Color>(color),
  //                     ),
  //                   ),
  //               ],
  //             ),
  //           ),
  //           const SizedBox(width: 16),
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Row(
  //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                   children: [
  //                     Text(
  //                       technique2,
  //                       style: Theme.of(context).textTheme.bodySmall,
  //                     ),
  //                     Text(
  //                       count2 > 0
  //                           ? '${percentage2.toStringAsFixed(0)}% ($count2)'
  //                           : 'No data',
  //                       style: Theme.of(context).textTheme.bodySmall?.copyWith(
  //                         fontWeight: FontWeight.bold,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //                 const SizedBox(height: 4),
  //                 if (count2 > 0)
  //                   ClipRRect(
  //                     borderRadius: BorderRadius.circular(4),
  //                     child: LinearProgressIndicator(
  //                       value: percentage2 / 100,
  //                       minHeight: 8,
  //                       backgroundColor: color.withValues(alpha: 0.2),
  //                       valueColor: AlwaysStoppedAnimation<Color>(color),
  //                     ),
  //                   ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }

  Widget _buildShotShapeRows(
    BuildContext context,
    Map<String, dynamic> shotShapeBirdieRates,
    Map<String, Map<String, double>> circleInRegByShape,
  ) {
    // Filter for relevant technique+shape combinations
    final relevantShapes = ['hyzer', 'flat', 'anhyzer'];
    final relevantTechniques = ['backhand', 'forehand'];

    final filteredCombos = shotShapeBirdieRates.entries.where((entry) {
      // Entry key format: "technique_shape" (e.g., "backhand_hyzer")
      final parts = entry.key.split('_');
      if (parts.length != 2) return false;
      final technique = parts[0];
      final shape = parts[1];
      return relevantTechniques.contains(technique) &&
          relevantShapes.contains(shape);
    }).toList();

    if (filteredCombos.isEmpty) {
      return Text(
        'No shot shape data available',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    // Sort by overall success (combination of birdie rate and C1 in reg)
    filteredCombos.sort((a, b) {
      final aStats = circleInRegByShape[a.key];
      final bStats = circleInRegByShape[b.key];
      final aScore = a.value.percentage + (aStats?['c1Percentage'] ?? 0);
      final bScore = b.value.percentage + (bStats?['c1Percentage'] ?? 0);
      return bScore.compareTo(aScore);
    });

    return Column(
      children: filteredCombos.map((entry) {
        final comboKey = entry.key;
        final shapeStats = entry.value;
        final circleStats = circleInRegByShape[comboKey];

        // Parse the combination key: "backhand_hyzer" -> "Backhand Hyzer"
        final parts = comboKey.split('_');
        final technique =
            parts[0].substring(0, 1).toUpperCase() + parts[0].substring(1);
        final shape =
            parts[1].substring(0, 1).toUpperCase() + parts[1].substring(1);
        final displayName = '$technique $shape';

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildShapeMetricRow(
                context,
                'Birdie',
                shapeStats.percentage,
                shapeStats.totalAttempts,
                const Color(0xFF00F5D4),
              ),
              const SizedBox(height: 6),
              _buildShapeMetricRow(
                context,
                'C1 in Reg',
                circleStats?['c1Percentage'] ?? 0,
                circleStats?['totalAttempts']?.toInt() ?? 0,
                const Color(0xFF4CAF50),
              ),
              const SizedBox(height: 6),
              _buildShapeMetricRow(
                context,
                'C2 in Reg',
                circleStats?['c2Percentage'] ?? 0,
                circleStats?['totalAttempts']?.toInt() ?? 0,
                const Color(0xFF2196F3),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildShapeMetricRow(
    BuildContext context,
    String label,
    double percentage,
    int count,
    Color color,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
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
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            count > 0
                ? '${percentage.toStringAsFixed(0)}% ($count)'
                : 'No data',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceByFairwayWidth(
    BuildContext context,
    Map<String, Map<String, double>> performanceByFairwayWidth,
  ) {
    if (performanceByFairwayWidth.isEmpty) {
      return const SizedBox.shrink();
    }

    // Define display order and labels for fairway widths
    final widthOrder = ['open', 'moderate', 'tight', 'veryTight'];
    final widthLabels = {
      'open': 'Open',
      'moderate': 'Moderate',
      'tight': 'Tight',
      'veryTight': 'Very Tight',
    };

    // Filter and sort by defined order
    final sortedWidths = widthOrder
        .where((width) => performanceByFairwayWidth.containsKey(width))
        .toList();

    if (sortedWidths.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance by Fairway Width',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...sortedWidths.map((width) {
              final stats = performanceByFairwayWidth[width]!;
              final displayName = widthLabels[width] ?? width;
              final holesPlayed = stats['holesPlayed']?.toInt() ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$displayName ($holesPlayed hole${holesPlayed != 1 ? 's' : ''})',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildShapeMetricRow(
                      context,
                      'Birdie',
                      stats['birdieRate'] ?? 0,
                      holesPlayed,
                      const Color(0xFF00F5D4),
                    ),
                    const SizedBox(height: 6),
                    _buildShapeMetricRow(
                      context,
                      'C1 in Reg',
                      stats['c1InRegRate'] ?? 0,
                      holesPlayed,
                      const Color(0xFF4CAF50),
                    ),
                    const SizedBox(height: 6),
                    _buildShapeMetricRow(
                      context,
                      'C2 in Reg',
                      stats['c2InRegRate'] ?? 0,
                      holesPlayed,
                      const Color(0xFF2196F3),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
