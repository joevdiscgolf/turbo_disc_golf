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

    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 80),
      children: addRunSpacing(
        [
          _buildCoreStatsKPIs(context, coreStats),
          _buildBirdieRateByThrowType(
            context,
            teeShotBirdieRates,
            allTeeShotsByType,
          ),
          _buildC1InRegByThrowType(context, circleInRegByType, allTeeShotsByType),
          _buildC2InRegByThrowType(context, circleInRegByType, allTeeShotsByType),
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
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
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
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
                          backgroundColor: const Color(0xFF00F5D4).withValues(
                            alpha: 0.2,
                          ),
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
                          final birdieThrows = allThrows.where((e) => e.key.relativeHoleScore < 0).toList();
                          final nonBirdieThrows = allThrows.where((e) => e.key.relativeHoleScore >= 0).toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (birdieThrows.isNotEmpty) ...[
                                Text(
                                  'Birdie Throws (${birdieThrows.length})',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
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
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                        ),
                                        if (teeShot.landingSpot != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF00F5D4).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _landingSpotLabel(teeShot.landingSpot!),
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
                              if (birdieThrows.isNotEmpty && nonBirdieThrows.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 8),
                              ],
                              if (nonBirdieThrows.isNotEmpty) ...[
                                Text(
                                  'Other Throws (${nonBirdieThrows.length})',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
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
                                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${hole.number}',
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.onSurface,
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
                                        if (teeShot.landingSpot != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _landingSpotLabel(teeShot.landingSpot!),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    fontSize: 10,
                                                    color: Theme.of(context).colorScheme.onSurface,
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

  Widget _buildC1InRegByThrowType(
    BuildContext context,
    Map<String, Map<String, double>> circleInRegByType,
    Map<String, List<MapEntry<DGHole, DiscThrow>>> allTeeShotsByType,
  ) {
    if (circleInRegByType.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedEntries = circleInRegByType.entries.toList()
      ..sort((a, b) => b.value['c1Percentage']!.compareTo(a.value['c1Percentage']!));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'C1 in Regulation by Throw Type',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
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
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
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
                          backgroundColor: const Color(0xFF4CAF50).withValues(
                            alpha: 0.2,
                          ),
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
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
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
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                        ),
                                        if (teeShot.landingSpot != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF4CAF50)
                                                  .withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _landingSpotLabel(teeShot.landingSpot!),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    fontSize: 10,
                                                    color: const Color(0xFF4CAF50),
                                                  ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                              if (c1Throws.isNotEmpty && nonC1Throws.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 8),
                              ],
                              if (nonC1Throws.isNotEmpty) ...[
                                Text(
                                  'Other Throws (${nonC1Throws.length})',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
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
                                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${hole.number}',
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.onSurface,
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
                                        if (teeShot.landingSpot != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _landingSpotLabel(teeShot.landingSpot!),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    fontSize: 10,
                                                    color: Theme.of(context).colorScheme.onSurface,
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
      ..sort((a, b) => b.value['c2Percentage']!.compareTo(a.value['c2Percentage']!));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'C2 in Regulation by Throw Type',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
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
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
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
                          backgroundColor: const Color(0xFF2196F3).withValues(
                            alpha: 0.2,
                          ),
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
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
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
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                        ),
                                        if (teeShot.landingSpot != null)
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
                                              _landingSpotLabel(teeShot.landingSpot!),
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
                              if (c2Throws.isNotEmpty && nonC2Throws.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 8),
                              ],
                              if (nonC2Throws.isNotEmpty) ...[
                                Text(
                                  'Other Throws (${nonC2Throws.length})',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
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
                                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${hole.number}',
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.onSurface,
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
                                        if (teeShot.landingSpot != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _landingSpotLabel(teeShot.landingSpot!),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    fontSize: 10,
                                                    color: Theme.of(context).colorScheme.onSurface,
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
}
