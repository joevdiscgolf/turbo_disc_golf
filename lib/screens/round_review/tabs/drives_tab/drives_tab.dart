import 'package:flutter/material.dart';
import 'package:turbo_disc_golf/components/hole_breakdown_list.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/drives_tab/components/core_drive_stats_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/drives_tab/components/throw_type_list_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/drives_tab/components/throw_type_radar_chart.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/drives_tab/components/view_mode_toggle.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/drives_tab/models/shot_detail.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/drives_tab/models/throw_type_stats.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/drives_tab/screens/driving_stat_detail_screen.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/drives_tab/screens/throw_type_detail_screen.dart';
import 'package:turbo_disc_golf/services/round_statistics_service.dart';
import 'package:turbo_disc_golf/widgets/circular_stat_indicator.dart';

class DrivesTab extends StatefulWidget {
  const DrivesTab({super.key, required this.round});

  final DGRound round;

  @override
  State<DrivesTab> createState() => _DrivesTabState();
}

class _DrivesTabState extends State<DrivesTab> {
  DriveViewMode _viewMode = DriveViewMode.cards;

  void _navigateToStatDetail(
    BuildContext context,
    String statName,
    double percentage,
    Color color,
    List<DGHole> successHoles,
  ) {
    final List<HoleResult> holeResults = [];

    for (final DGHole hole in widget.round.holes) {
      final HoleResultStatus status = successHoles.contains(hole)
          ? HoleResultStatus.success
          : HoleResultStatus.failure;

      holeResults.add(HoleResult(holeNumber: hole.number, status: status));
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DrivingStatDetailScreen(
          statName: statName,
          percentage: percentage,
          color: color,
          successCount: successHoles.length,
          totalHoles: widget.round.holes.length,
          holeResults: holeResults,
        ),
      ),
    );
  }

  List<DGHole> _getC1InRegHoles() {
    final List<DGHole> c1InRegHoles = [];

    for (final DGHole hole in widget.round.holes) {
      final int regulationStrokes = hole.par - 2;
      if (regulationStrokes > 0) {
        for (int i = 0; i < hole.throws.length && i < regulationStrokes; i++) {
          final DiscThrow discThrow = hole.throws[i];
          if (discThrow.landingSpot == LandingSpot.circle1 ||
              discThrow.landingSpot == LandingSpot.parked) {
            c1InRegHoles.add(hole);
            break;
          }
        }
      }
    }

    return c1InRegHoles;
  }

  List<DGHole> _getC2InRegHoles() {
    final List<DGHole> c2InRegHoles = [];

    for (final DGHole hole in widget.round.holes) {
      final int regulationStrokes = hole.par - 2;
      if (regulationStrokes > 0) {
        for (int i = 0; i < hole.throws.length && i < regulationStrokes; i++) {
          final DiscThrow discThrow = hole.throws[i];
          if (discThrow.landingSpot == LandingSpot.circle1 ||
              discThrow.landingSpot == LandingSpot.parked ||
              discThrow.landingSpot == LandingSpot.circle2) {
            c2InRegHoles.add(hole);
            break;
          }
        }
      }
    }

    return c2InRegHoles;
  }

  List<DGHole> _getFairwayHoles() {
    final List<DGHole> fairwayHoles = [];

    for (final DGHole hole in widget.round.holes) {
      bool hitFairway = false;
      for (final DiscThrow discThrow in hole.throws) {
        if (discThrow.landingSpot == LandingSpot.fairway ||
            discThrow.landingSpot == LandingSpot.circle1 ||
            discThrow.landingSpot == LandingSpot.circle2 ||
            discThrow.landingSpot == LandingSpot.parked) {
          hitFairway = true;
          break;
        }
      }
      if (hitFairway) {
        fairwayHoles.add(hole);
      }
    }

    return fairwayHoles;
  }

  List<DGHole> _getOBHoles() {
    final List<DGHole> obHoles = [];

    for (final DGHole hole in widget.round.holes) {
      for (final DiscThrow discThrow in hole.throws) {
        if (discThrow.landingSpot == LandingSpot.outOfBounds) {
          obHoles.add(hole);
          break;
        }
      }
    }

    return obHoles;
  }

  List<DGHole> _getParkedHoles() {
    final List<DGHole> parkedHoles = [];

    for (final DGHole hole in widget.round.holes) {
      for (final DiscThrow discThrow in hole.throws) {
        if (discThrow.landingSpot == LandingSpot.parked) {
          parkedHoles.add(hole);
          break;
        }
      }
    }

    return parkedHoles;
  }

  ThrowTypeStats _calculateThrowTypeStats(
    String throwType,
    Map<String, dynamic> teeShotBirdieRates,
    Map<String, Map<String, double>> circleInRegByType,
    Map<String, List<MapEntry<DGHole, DiscThrow>>> allTeeShotsByType,
  ) {
    final birdieData = teeShotBirdieRates[throwType];
    final c1c2Data = circleInRegByType[throwType];

    // Calculate average distance
    double? averageDistance;
    final teeShots = allTeeShotsByType[throwType];
    if (teeShots != null && teeShots.isNotEmpty) {
      final holesWithDistance = teeShots
          .where((entry) => entry.key.feet != null)
          .toList();
      if (holesWithDistance.isNotEmpty) {
        final totalDistance = holesWithDistance.fold<double>(
          0,
          (sum, entry) => sum + (entry.key.feet?.toDouble() ?? 0),
        );
        averageDistance = totalDistance / holesWithDistance.length;
      }
    }

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
        averageDistance: averageDistance,
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
      averageDistance: averageDistance,
    );
  }

  List<ShotShapeStats> _getShotShapeStats(
    String throwType,
    Map<String, dynamic> shotShapeBirdieRates,
    Map<String, Map<String, double>> circleInRegByShape,
  ) {
    final List<ShotShapeStats> stats = [];

    for (final entry in shotShapeBirdieRates.entries) {
      final String shapeName = entry.key;
      if (!shapeName.toLowerCase().startsWith(throwType.toLowerCase())) {
        continue;
      }

      final birdieData = entry.value;
      final c1c2Data = circleInRegByShape[shapeName];

      if (birdieData != null && c1c2Data != null) {
        stats.add(
          ShotShapeStats(
            shapeName: shapeName,
            throwType: throwType,
            birdieRate: birdieData.percentage,
            birdieCount: birdieData.birdieCount,
            totalAttempts: birdieData.totalAttempts,
            c1InRegPct: c1c2Data['c1Percentage'] ?? 0,
            c1Count: (c1c2Data['c1Count'] ?? 0).toInt(),
            c1Total: (c1c2Data['totalAttempts'] ?? 0).toInt(),
            c2InRegPct: c1c2Data['c2Percentage'] ?? 0,
            c2Count: (c1c2Data['c2Count'] ?? 0).toInt(),
            c2Total: (c1c2Data['totalAttempts'] ?? 0).toInt(),
          ),
        );
      }
    }

    // Sort by birdie rate descending
    stats.sort((a, b) => b.birdieRate.compareTo(a.birdieRate));

    return stats;
  }

  /// Get shot details for a specific throw type (all shots of that type)
  List<ShotDetail> _getShotDetailsForThrowType(String throwType) {
    final List<ShotDetail> shotDetails = [];

    for (final DGHole hole in widget.round.holes) {
      for (int i = 0; i < hole.throws.length; i++) {
        final DiscThrow discThrow = hole.throws[i];

        // Check if this throw matches the throw type
        if (discThrow.technique?.name == throwType) {
          final ShotOutcome outcome = _calculateShotOutcome(hole, i);
          shotDetails.add(ShotDetail(
            hole: hole,
            throwIndex: i,
            shotOutcome: outcome,
          ));
        }
      }
    }

    return shotDetails;
  }

  /// Get shot details grouped by shot shape for a specific throw type
  Map<String, List<ShotDetail>> _getShotDetailsByShape(String throwType) {
    final Map<String, List<ShotDetail>> shotDetailsByShape = {};

    for (final DGHole hole in widget.round.holes) {
      for (int i = 0; i < hole.throws.length; i++) {
        final DiscThrow discThrow = hole.throws[i];

        // Check if this throw matches the throw type
        if (discThrow.technique?.name == throwType) {
          final String? shotShape = discThrow.shotShape?.name;
          if (shotShape != null) {
            final String shapeKey = '${throwType}_$shotShape';
            final ShotOutcome outcome = _calculateShotOutcome(hole, i);

            shotDetailsByShape.putIfAbsent(shapeKey, () => []);
            shotDetailsByShape[shapeKey]!.add(ShotDetail(
              hole: hole,
              throwIndex: i,
              shotOutcome: outcome,
            ));
          }
        }
      }
    }

    return shotDetailsByShape;
  }

  /// Calculate whether a shot was successful for various metrics
  ShotOutcome _calculateShotOutcome(DGHole hole, int throwIndex) {
    final DiscThrow discThrow = hole.throws[throwIndex];
    final bool isTeeShot = throwIndex == 0;

    // Determine if this led to a birdie
    final bool wasBirdie = hole.relativeHoleScore < 0;

    // Determine if this was C1 in regulation (tee shot that landed in C1)
    bool wasC1InReg = false;
    if (isTeeShot) {
      final LandingSpot? landing = discThrow.landingSpot;
      wasC1InReg = landing == LandingSpot.circle1 || landing == LandingSpot.parked;
    }

    // Determine if this was C2 in regulation (tee shot that landed in C2)
    bool wasC2InReg = false;
    if (isTeeShot) {
      final LandingSpot? landing = discThrow.landingSpot;
      wasC2InReg = landing == LandingSpot.circle2;
    }

    return ShotOutcome(
      wasBirdie: wasBirdie,
      wasC1InReg: wasC1InReg,
      wasC2InReg: wasC2InReg,
    );
  }

  void _navigateToThrowTypeDetail(
    BuildContext context,
    String throwType,
    ThrowTypeStats overallStats,
    Map<String, dynamic> shotShapeBirdieRates,
    Map<String, Map<String, double>> circleInRegByShape,
  ) {
    final List<ShotShapeStats> shotShapes = _getShotShapeStats(
      throwType,
      shotShapeBirdieRates,
      circleInRegByShape,
    );

    // Get shot details for overall performance
    final List<ShotDetail> overallShotDetails = _getShotDetailsForThrowType(throwType);

    // Get shot details grouped by shot shape
    final Map<String, List<ShotDetail>> shotShapeDetails = _getShotDetailsByShape(throwType);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ThrowTypeDetailScreen(
          throwType: throwType,
          overallStats: overallStats,
          shotShapeStats: shotShapes,
          overallShotDetails: overallShotDetails,
          shotShapeDetails: shotShapeDetails,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final RoundStatisticsService statsService = RoundStatisticsService(
      widget.round,
    );

    final coreStats = statsService.getCoreStats();
    final teeShotBirdieRates = statsService.getTeeShotBirdieRateStats();
    final allTeeShotsByType = statsService.getAllTeeShotsByType();
    final circleInRegByType = statsService.getCircleInRegByThrowType();
    final shotShapeBirdieRates = statsService
        .getShotShapeByTechniqueBirdieRateStats();
    final circleInRegByShape = statsService
        .getCircleInRegByShotShapeAndTechnique();
    final performanceByFairwayWidth = statsService
        .getPerformanceByFairwayWidth();

    // Generate stats for ALL throw types dynamically
    final List<ThrowTypeStats> allThrowTypes = [];
    for (final entry in teeShotBirdieRates.entries) {
      final ThrowTypeStats stats = _calculateThrowTypeStats(
        entry.key,
        teeShotBirdieRates,
        circleInRegByType,
        allTeeShotsByType,
      );
      allThrowTypes.add(stats);
    }

    // Sort by birdie rate descending to identify best/worst performers
    allThrowTypes.sort((a, b) => b.birdieRate.compareTo(a.birdieRate));

    return Container(
      color: const Color(0xFFF8F9FA),
      child: ListView(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 80,
        ),
        children: [
          // Core stats card
          CoreDriveStatsCard(
            coreStats: coreStats,
            onC1InRegPressed: () {
              _navigateToStatDetail(
                context,
                'C1 in Reg',
                coreStats.c1InRegPct,
                const Color(0xFF137e66),
                _getC1InRegHoles(),
              );
            },
            onC2InRegPressed: () {
              _navigateToStatDetail(
                context,
                'C2 in Reg',
                coreStats.c2InRegPct,
                const Color.fromARGB(255, 13, 21, 28),
                _getC2InRegHoles(),
              );
            },
            onFairwayPressed: () {
              _navigateToStatDetail(
                context,
                'Fairway',
                coreStats.fairwayHitPct,
                const Color(0xFF4CAF50),
                _getFairwayHoles(),
              );
            },
            onOBPressed: () {
              _navigateToStatDetail(
                context,
                'OB',
                coreStats.obPct,
                const Color(0xFFFF7A7A),
                _getOBHoles(),
              );
            },
            onParkedPressed: () {
              _navigateToStatDetail(
                context,
                'Parked',
                coreStats.parkedPct,
                const Color(0xFFFFA726),
                _getParkedHoles(),
              );
            },
          ),
          const SizedBox(height: 16),

          // Insight card
          // if (allThrowTypes.length >= 2) ...[
          //   InsightCard(
          //     bestThrowType: allThrowTypes.first.displayName,
          //     bestPercentage: allThrowTypes.first.birdieRate,
          //     worstThrowType: allThrowTypes.last.displayName,
          //     worstPercentage: allThrowTypes.last.birdieRate,
          //   ),
          //   const SizedBox(height: 16),
          // ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'Throw Type Performance',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          // View mode toggle
          ViewModeToggle(
            selectedMode: _viewMode,
            onModeChanged: (DriveViewMode mode) {
              setState(() {
                _viewMode = mode;
              });
            },
          ),
          const SizedBox(height: 16),

          // Conditional rendering based on view mode
          if (_viewMode == DriveViewMode.cards)
            ThrowTypeListCard(
              throwTypes: allThrowTypes,
              onThrowTypeTap: (ThrowTypeStats stats) {
                _navigateToThrowTypeDetail(
                  context,
                  stats.throwType,
                  stats,
                  shotShapeBirdieRates,
                  circleInRegByShape,
                );
              },
            )
          else
            ThrowTypeRadarChart(throwTypes: allThrowTypes),

          // Performance by fairway width
          if (performanceByFairwayWidth.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildPerformanceByFairwayWidth(context, performanceByFairwayWidth),
          ],
        ],
      ),
    );
  }

  // Widget _buildKPICard(
  //   BuildContext context,
  //   String label,
  //   String value,
  //   Color color,
  // ) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //     decoration: BoxDecoration(
  //       color: color.withValues(alpha: 0.1),
  //       borderRadius: BorderRadius.circular(8),
  //       border: Border.all(color: color.withValues(alpha: 0.3)),
  //     ),
  //     child: Column(
  //       children: [
  //         Text(
  //           value,
  //           style: Theme.of(context).textTheme.titleLarge?.copyWith(
  //             fontWeight: FontWeight.bold,
  //             color: color,
  //           ),
  //         ),
  //         const SizedBox(height: 4),
  //         Text(
  //           label,
  //           style: Theme.of(context).textTheme.bodySmall?.copyWith(
  //             color: Theme.of(context).colorScheme.onSurfaceVariant,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildBirdieRateByThrowType(
  //   BuildContext context,
  //   Map<String, dynamic> teeShotBirdieRates,
  //   Map<String, List<MapEntry<DGHole, DiscThrow>>> allTeeShotsByType,
  // ) {
  //   if (teeShotBirdieRates.isEmpty) {
  //     return const SizedBox.shrink();
  //   }

  //   final sortedEntries = teeShotBirdieRates.entries.toList()
  //     ..sort((a, b) => b.value.percentage.compareTo(a.value.percentage));

  //   return Card(
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             'Birdie Rate by Throw Type',
  //             style: Theme.of(
  //               context,
  //             ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
  //           ),
  //           const SizedBox(height: 16),
  //           ...sortedEntries.map((entry) {
  //             final technique = entry.key;
  //             final stats = entry.value;
  //             final percentage = stats.percentage;
  //             final allThrows = allTeeShotsByType[technique] ?? [];

  //             return Padding(
  //               padding: const EdgeInsets.only(bottom: 12),
  //               child: Theme(
  //                 data: Theme.of(
  //                   context,
  //                 ).copyWith(dividerColor: Colors.transparent),
  //                 child: ExpansionTile(
  //                   tilePadding: EdgeInsets.zero,
  //                   childrenPadding: const EdgeInsets.only(top: 8),
  //                   title: Row(
  //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                     children: [
  //                       Text(
  //                         technique.substring(0, 1).toUpperCase() +
  //                             technique.substring(1),
  //                         style: Theme.of(context).textTheme.bodyMedium,
  //                       ),
  //                       Text(
  //                         '${percentage.toStringAsFixed(0)}% (${stats.birdieCount}/${stats.totalAttempts})',
  //                         style: Theme.of(context).textTheme.bodyMedium
  //                             ?.copyWith(fontWeight: FontWeight.bold),
  //                       ),
  //                     ],
  //                   ),
  //                   subtitle: Padding(
  //                     padding: const EdgeInsets.only(top: 4),
  //                     child: ClipRRect(
  //                       borderRadius: BorderRadius.circular(4),
  //                       child: LinearProgressIndicator(
  //                         value: percentage / 100,
  //                         minHeight: 12,
  //                         backgroundColor: const Color(
  //                           0xFF137e66,
  //                         ).withValues(alpha: 0.2),
  //                         valueColor: const AlwaysStoppedAnimation<Color>(
  //                           Color(0xFF137e66),
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                   children: [
  //                     if (allThrows.isNotEmpty) ...[
  //                       const Divider(),
  //                       () {
  //                         final birdieThrows = allThrows
  //                             .where((e) => e.key.relativeHoleScore < 0)
  //                             .toList();
  //                         final nonBirdieThrows = allThrows
  //                             .where((e) => e.key.relativeHoleScore >= 0)
  //                             .toList();

  //                         return Column(
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           children: [
  //                             if (birdieThrows.isNotEmpty) ...[
  //                               Text(
  //                                 'Birdie Throws (${birdieThrows.length})',
  //                                 style: Theme.of(context).textTheme.bodySmall
  //                                     ?.copyWith(fontWeight: FontWeight.bold),
  //                               ),
  //                               const SizedBox(height: 8),
  //                               ...birdieThrows.map((entry) {
  //                                 final hole = entry.key;
  //                                 final teeShot = entry.value;

  //                                 return Padding(
  //                                   padding: const EdgeInsets.only(bottom: 4),
  //                                   child: Row(
  //                                     children: [
  //                                       Container(
  //                                         width: 24,
  //                                         height: 24,
  //                                         decoration: const BoxDecoration(
  //                                           color: Color(0xFF137e66),
  //                                           shape: BoxShape.circle,
  //                                         ),
  //                                         child: Center(
  //                                           child: Text(
  //                                             '${hole.number}',
  //                                             style: const TextStyle(
  //                                               color: Colors.white,
  //                                               fontWeight: FontWeight.bold,
  //                                               fontSize: 11,
  //                                             ),
  //                                           ),
  //                                         ),
  //                                       ),
  //                                       const SizedBox(width: 8),
  //                                       Expanded(
  //                                         child: Text(
  //                                           'Hole ${hole.number} - Par ${hole.par}${hole.feet != null ? ' • ${hole.feet} ft' : ''}',
  //                                           style: Theme.of(
  //                                             context,
  //                                           ).textTheme.bodySmall,
  //                                         ),
  //                                       ),
  //                                       if (teeShot.landingSpot != null)
  //                                         Container(
  //                                           padding: const EdgeInsets.symmetric(
  //                                             horizontal: 6,
  //                                             vertical: 2,
  //                                           ),
  //                                           decoration: BoxDecoration(
  //                                             color: const Color(
  //                                               0xFF137e66,
  //                                             ).withValues(alpha: 0.15),
  //                                             borderRadius:
  //                                                 BorderRadius.circular(8),
  //                                           ),
  //                                           child: Text(
  //                                             _landingSpotLabel(
  //                                               teeShot.landingSpot!,
  //                                             ),
  //                                             style: Theme.of(context)
  //                                                 .textTheme
  //                                                 .bodySmall
  //                                                 ?.copyWith(
  //                                                   fontSize: 10,
  //                                                   color: const Color(
  //                                                     0xFF137e66,
  //                                                   ),
  //                                                 ),
  //                                           ),
  //                                         ),
  //                                     ],
  //                                   ),
  //                                 );
  //                               }),
  //                             ],
  //                             if (birdieThrows.isNotEmpty &&
  //                                 nonBirdieThrows.isNotEmpty) ...[
  //                               const SizedBox(height: 12),
  //                               const Divider(),
  //                               const SizedBox(height: 8),
  //                             ],
  //                             if (nonBirdieThrows.isNotEmpty) ...[
  //                               Text(
  //                                 'Other Throws (${nonBirdieThrows.length})',
  //                                 style: Theme.of(context).textTheme.bodySmall
  //                                     ?.copyWith(fontWeight: FontWeight.bold),
  //                               ),
  //                               const SizedBox(height: 8),
  //                               ...nonBirdieThrows.map((entry) {
  //                                 final hole = entry.key;
  //                                 final teeShot = entry.value;

  //                                 return Padding(
  //                                   padding: const EdgeInsets.only(bottom: 4),
  //                                   child: Row(
  //                                     children: [
  //                                       Container(
  //                                         width: 24,
  //                                         height: 24,
  //                                         decoration: BoxDecoration(
  //                                           color: Theme.of(context)
  //                                               .colorScheme
  //                                               .surfaceContainerHighest,
  //                                           shape: BoxShape.circle,
  //                                         ),
  //                                         child: Center(
  //                                           child: Text(
  //                                             '${hole.number}',
  //                                             style: TextStyle(
  //                                               color: Theme.of(
  //                                                 context,
  //                                               ).colorScheme.onSurface,
  //                                               fontWeight: FontWeight.bold,
  //                                               fontSize: 11,
  //                                             ),
  //                                           ),
  //                                         ),
  //                                       ),
  //                                       const SizedBox(width: 8),
  //                                       Expanded(
  //                                         child: Text(
  //                                           'Hole ${hole.number} - Par ${hole.par}${hole.feet != null ? ' • ${hole.feet} ft' : ''}',
  //                                           style: Theme.of(
  //                                             context,
  //                                           ).textTheme.bodySmall,
  //                                         ),
  //                                       ),
  //                                       if (teeShot.landingSpot != null)
  //                                         Container(
  //                                           padding: const EdgeInsets.symmetric(
  //                                             horizontal: 6,
  //                                             vertical: 2,
  //                                           ),
  //                                           decoration: BoxDecoration(
  //                                             color: Theme.of(context)
  //                                                 .colorScheme
  //                                                 .surfaceContainerHighest,
  //                                             borderRadius:
  //                                                 BorderRadius.circular(8),
  //                                           ),
  //                                           child: Text(
  //                                             _landingSpotLabel(
  //                                               teeShot.landingSpot!,
  //                                             ),
  //                                             style: Theme.of(context)
  //                                                 .textTheme
  //                                                 .bodySmall
  //                                                 ?.copyWith(
  //                                                   fontSize: 10,
  //                                                   color: Theme.of(
  //                                                     context,
  //                                                   ).colorScheme.onSurface,
  //                                                 ),
  //                                           ),
  //                                         ),
  //                                     ],
  //                                   ),
  //                                 );
  //                               }),
  //                             ],
  //                           ],
  //                         );
  //                       }(),
  //                     ],
  //                   ],
  //                 ),
  //               ),
  //             );
  //           }),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // String _landingSpotLabel(LandingSpot spot) {
  //   switch (spot) {
  //     case LandingSpot.parked:
  //       return 'Parked';
  //     case LandingSpot.circle1:
  //       return 'C1';
  //     case LandingSpot.circle2:
  //       return 'C2';
  //     case LandingSpot.fairway:
  //       return 'Fairway';
  //     default:
  //       return '';
  //   }
  // }

  // String _scoreLabel(int relativeHoleScore) {
  //   if (relativeHoleScore <= -3) {
  //     return 'Albatross';
  //   } else if (relativeHoleScore == -2) {
  //     return 'Eagle';
  //   } else if (relativeHoleScore == -1) {
  //     return 'Birdie';
  //   } else if (relativeHoleScore == 0) {
  //     return 'Par';
  //   } else if (relativeHoleScore == 1) {
  //     return 'Bogey';
  //   } else if (relativeHoleScore == 2) {
  //     return 'Double Bogey';
  //   } else if (relativeHoleScore == 3) {
  //     return 'Triple Bogey';
  //   } else {
  //     return '+$relativeHoleScore';
  //   }
  // }

  // Widget _buildOverallC1InRegCard(BuildContext context, coreStats) {
  //   final c1InRegPct = coreStats.c1InRegPct;

  //   // Calculate which holes reached C1 in regulation
  //   final c1InRegHoles = <DGHole>[];
  //   final notC1InRegHoles = <DGHole>[];

  //   for (final hole in round.holes) {
  //     final regulationStrokes = hole.par - 2;
  //     bool reachedC1 = false;

  //     if (regulationStrokes > 0) {
  //       for (int i = 0; i < hole.throws.length && i < regulationStrokes; i++) {
  //         final discThrow = hole.throws[i];
  //         if (discThrow.landingSpot == LandingSpot.circle1 ||
  //             discThrow.landingSpot == LandingSpot.parked) {
  //           reachedC1 = true;
  //           break;
  //         }
  //       }
  //     }

  //     if (reachedC1) {
  //       c1InRegHoles.add(hole);
  //     } else {
  //       notC1InRegHoles.add(hole);
  //     }
  //   }

  //   return Card(
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Theme(
  //         data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
  //         child: ExpansionTile(
  //           tilePadding: EdgeInsets.zero,
  //           childrenPadding: const EdgeInsets.only(top: 8),
  //           title: Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               Text(
  //                 'C1 in Regulation',
  //                 style: Theme.of(context).textTheme.titleMedium?.copyWith(
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //               ),
  //               Text(
  //                 '${c1InRegPct.toStringAsFixed(0)}% (${c1InRegHoles.length}/${round.holes.length})',
  //                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //               ),
  //             ],
  //           ),
  //           subtitle: Padding(
  //             padding: const EdgeInsets.only(top: 8),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   'Holes where you reached C1 with a chance for birdie',
  //                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
  //                         color: Theme.of(context).colorScheme.onSurfaceVariant,
  //                       ),
  //                 ),
  //                 const SizedBox(height: 8),
  //                 ClipRRect(
  //                   borderRadius: BorderRadius.circular(4),
  //                   child: LinearProgressIndicator(
  //                     value: c1InRegPct / 100,
  //                     minHeight: 12,
  //                     backgroundColor:
  //                         const Color(0xFF137e66).withValues(alpha: 0.2),
  //                     valueColor: const AlwaysStoppedAnimation<Color>(
  //                       Color(0xFF137e66),
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //           children: [
  //             const Divider(),
  //             Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 if (c1InRegHoles.isNotEmpty) ...[
  //                   Text(
  //                     'C1 in Reg (${c1InRegHoles.length})',
  //                     style: Theme.of(context)
  //                         .textTheme
  //                         .bodySmall
  //                         ?.copyWith(fontWeight: FontWeight.bold),
  //                   ),
  //                   const SizedBox(height: 8),
  //                   ...c1InRegHoles.map((hole) {
  //                     return Padding(
  //                       padding: const EdgeInsets.only(bottom: 4),
  //                       child: Row(
  //                         children: [
  //                           Container(
  //                             width: 24,
  //                             height: 24,
  //                             decoration: const BoxDecoration(
  //                               color: Color(0xFF137e66),
  //                               shape: BoxShape.circle,
  //                             ),
  //                             child: Center(
  //                               child: Text(
  //                                 '${hole.number}',
  //                                 style: const TextStyle(
  //                                   color: Colors.white,
  //                                   fontWeight: FontWeight.bold,
  //                                   fontSize: 11,
  //                                 ),
  //                               ),
  //                             ),
  //                           ),
  //                           const SizedBox(width: 8),
  //                           Expanded(
  //                             child: Text(
  //                               'Hole ${hole.number} - Par ${hole.par}${hole.feet != null ? ' • ${hole.feet} ft' : ''}',
  //                               style: Theme.of(context).textTheme.bodySmall,
  //                             ),
  //                           ),
  //                           Container(
  //                             padding: const EdgeInsets.symmetric(
  //                               horizontal: 6,
  //                               vertical: 2,
  //                             ),
  //                             decoration: BoxDecoration(
  //                               color: const Color(0xFF137e66)
  //                                   .withValues(alpha: 0.15),
  //                               borderRadius: BorderRadius.circular(8),
  //                             ),
  //                             child: Text(
  //                               _scoreLabel(hole.relativeHoleScore),
  //                               style: Theme.of(context)
  //                                   .textTheme
  //                                   .bodySmall
  //                                   ?.copyWith(
  //                                     fontSize: 10,
  //                                     color: const Color(0xFF137e66),
  //                                   ),
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     );
  //                   }),
  //                 ],
  //                 if (c1InRegHoles.isNotEmpty && notC1InRegHoles.isNotEmpty) ...[
  //                   const SizedBox(height: 12),
  //                   const Divider(),
  //                   const SizedBox(height: 8),
  //                 ],
  //                 if (notC1InRegHoles.isNotEmpty) ...[
  //                   Text(
  //                     'Not C1 in Reg (${notC1InRegHoles.length})',
  //                     style: Theme.of(context)
  //                         .textTheme
  //                         .bodySmall
  //                         ?.copyWith(fontWeight: FontWeight.bold),
  //                   ),
  //                   const SizedBox(height: 8),
  //                   ...notC1InRegHoles.map((hole) {
  //                     return Padding(
  //                       padding: const EdgeInsets.only(bottom: 4),
  //                       child: Row(
  //                         children: [
  //                           Container(
  //                             width: 24,
  //                             height: 24,
  //                             decoration: BoxDecoration(
  //                               color: Theme.of(context)
  //                                   .colorScheme
  //                                   .surfaceContainerHighest,
  //                               shape: BoxShape.circle,
  //                             ),
  //                             child: Center(
  //                               child: Text(
  //                                 '${hole.number}',
  //                                 style: TextStyle(
  //                                   color:
  //                                       Theme.of(context).colorScheme.onSurface,
  //                                   fontWeight: FontWeight.bold,
  //                                   fontSize: 11,
  //                                 ),
  //                               ),
  //                             ),
  //                           ),
  //                           const SizedBox(width: 8),
  //                           Expanded(
  //                             child: Text(
  //                               'Hole ${hole.number} - Par ${hole.par}${hole.feet != null ? ' • ${hole.feet} ft' : ''}',
  //                               style: Theme.of(context).textTheme.bodySmall,
  //                             ),
  //                           ),
  //                           Container(
  //                             padding: const EdgeInsets.symmetric(
  //                               horizontal: 6,
  //                               vertical: 2,
  //                             ),
  //                             decoration: BoxDecoration(
  //                               color: Theme.of(context)
  //                                   .colorScheme
  //                                   .surfaceContainerHighest,
  //                               borderRadius: BorderRadius.circular(8),
  //                             ),
  //                             child: Text(
  //                               _scoreLabel(hole.relativeHoleScore),
  //                               style: Theme.of(context)
  //                                   .textTheme
  //                                   .bodySmall
  //                                   ?.copyWith(
  //                                     fontSize: 10,
  //                                     color: Theme.of(context)
  //                                         .colorScheme
  //                                         .onSurface,
  //                                   ),
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     );
  //                   }),
  //                 ],
  //               ],
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildOverallC2InRegCard(BuildContext context, coreStats) {
  //   final c2InRegPct = coreStats.c2InRegPct;

  //   // Calculate which holes reached C2 in regulation
  //   final c2InRegHoles = <DGHole>[];
  //   final notC2InRegHoles = <DGHole>[];

  //   for (final hole in round.holes) {
  //     final regulationStrokes = hole.par - 2;
  //     bool reachedC2 = false;

  //     if (regulationStrokes > 0) {
  //       for (int i = 0; i < hole.throws.length && i < regulationStrokes; i++) {
  //         final discThrow = hole.throws[i];
  //         if (discThrow.landingSpot == LandingSpot.circle1 ||
  //             discThrow.landingSpot == LandingSpot.parked ||
  //             discThrow.landingSpot == LandingSpot.circle2) {
  //           reachedC2 = true;
  //           break;
  //         }
  //       }
  //     }

  //     if (reachedC2) {
  //       c2InRegHoles.add(hole);
  //     } else {
  //       notC2InRegHoles.add(hole);
  //     }
  //   }

  //   return Card(
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Theme(
  //         data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
  //         child: ExpansionTile(
  //           tilePadding: EdgeInsets.zero,
  //           childrenPadding: const EdgeInsets.only(top: 8),
  //           title: Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               Text(
  //                 'C2 in Regulation',
  //                 style: Theme.of(context).textTheme.titleMedium?.copyWith(
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //               ),
  //               Text(
  //                 '${c2InRegPct.toStringAsFixed(0)}% (${c2InRegHoles.length}/${round.holes.length})',
  //                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //               ),
  //             ],
  //           ),
  //           subtitle: Padding(
  //             padding: const EdgeInsets.only(top: 8),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   'Holes where you reached C2 with a chance for birdie',
  //                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
  //                         color: Theme.of(context).colorScheme.onSurfaceVariant,
  //                       ),
  //                 ),
  //                 const SizedBox(height: 8),
  //                 ClipRRect(
  //                   borderRadius: BorderRadius.circular(4),
  //                   child: LinearProgressIndicator(
  //                     value: c2InRegPct / 100,
  //                     minHeight: 12,
  //                     backgroundColor:
  //                         const Color(0xFF2196F3).withValues(alpha: 0.2),
  //                     valueColor: const AlwaysStoppedAnimation<Color>(
  //                       Color(0xFF2196F3),
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //           children: [
  //             const Divider(),
  //             Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 if (c2InRegHoles.isNotEmpty) ...[
  //                   Text(
  //                     'C2 in Reg (${c2InRegHoles.length})',
  //                     style: Theme.of(context)
  //                         .textTheme
  //                         .bodySmall
  //                         ?.copyWith(fontWeight: FontWeight.bold),
  //                   ),
  //                   const SizedBox(height: 8),
  //                   ...c2InRegHoles.map((hole) {
  //                     return Padding(
  //                       padding: const EdgeInsets.only(bottom: 4),
  //                       child: Row(
  //                         children: [
  //                           Container(
  //                             width: 24,
  //                             height: 24,
  //                             decoration: const BoxDecoration(
  //                               color: Color(0xFF2196F3),
  //                               shape: BoxShape.circle,
  //                             ),
  //                             child: Center(
  //                               child: Text(
  //                                 '${hole.number}',
  //                                 style: const TextStyle(
  //                                   color: Colors.white,
  //                                   fontWeight: FontWeight.bold,
  //                                   fontSize: 11,
  //                                 ),
  //                               ),
  //                             ),
  //                           ),
  //                           const SizedBox(width: 8),
  //                           Expanded(
  //                             child: Text(
  //                               'Hole ${hole.number} - Par ${hole.par}${hole.feet != null ? ' • ${hole.feet} ft' : ''}',
  //                               style: Theme.of(context).textTheme.bodySmall,
  //                             ),
  //                           ),
  //                           Container(
  //                             padding: const EdgeInsets.symmetric(
  //                               horizontal: 6,
  //                               vertical: 2,
  //                             ),
  //                             decoration: BoxDecoration(
  //                               color: const Color(0xFF2196F3)
  //                                   .withValues(alpha: 0.15),
  //                               borderRadius: BorderRadius.circular(8),
  //                             ),
  //                             child: Text(
  //                               _scoreLabel(hole.relativeHoleScore),
  //                               style: Theme.of(context)
  //                                   .textTheme
  //                                   .bodySmall
  //                                   ?.copyWith(
  //                                     fontSize: 10,
  //                                     color: const Color(0xFF2196F3),
  //                                   ),
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     );
  //                   }),
  //                 ],
  //                 if (c2InRegHoles.isNotEmpty && notC2InRegHoles.isNotEmpty) ...[
  //                   const SizedBox(height: 12),
  //                   const Divider(),
  //                   const SizedBox(height: 8),
  //                 ],
  //                 if (notC2InRegHoles.isNotEmpty) ...[
  //                   Text(
  //                     'Not C2 in Reg (${notC2InRegHoles.length})',
  //                     style: Theme.of(context)
  //                         .textTheme
  //                         .bodySmall
  //                         ?.copyWith(fontWeight: FontWeight.bold),
  //                   ),
  //                   const SizedBox(height: 8),
  //                   ...notC2InRegHoles.map((hole) {
  //                     return Padding(
  //                       padding: const EdgeInsets.only(bottom: 4),
  //                       child: Row(
  //                         children: [
  //                           Container(
  //                             width: 24,
  //                             height: 24,
  //                             decoration: BoxDecoration(
  //                               color: Theme.of(context)
  //                                   .colorScheme
  //                                   .surfaceContainerHighest,
  //                               shape: BoxShape.circle,
  //                             ),
  //                             child: Center(
  //                               child: Text(
  //                                 '${hole.number}',
  //                                 style: TextStyle(
  //                                   color:
  //                                       Theme.of(context).colorScheme.onSurface,
  //                                   fontWeight: FontWeight.bold,
  //                                   fontSize: 11,
  //                                 ),
  //                               ),
  //                             ),
  //                           ),
  //                           const SizedBox(width: 8),
  //                           Expanded(
  //                             child: Text(
  //                               'Hole ${hole.number} - Par ${hole.par}${hole.feet != null ? ' • ${hole.feet} ft' : ''}',
  //                               style: Theme.of(context).textTheme.bodySmall,
  //                             ),
  //                           ),
  //                           Container(
  //                             padding: const EdgeInsets.symmetric(
  //                               horizontal: 6,
  //                               vertical: 2,
  //                             ),
  //                             decoration: BoxDecoration(
  //                               color: Theme.of(context)
  //                                   .colorScheme
  //                                   .surfaceContainerHighest,
  //                               borderRadius: BorderRadius.circular(8),
  //                             ),
  //                             child: Text(
  //                               _scoreLabel(hole.relativeHoleScore),
  //                               style: Theme.of(context)
  //                                   .textTheme
  //                                   .bodySmall
  //                                   ?.copyWith(
  //                                     fontSize: 10,
  //                                     color: Theme.of(context)
  //                                         .colorScheme
  //                                         .onSurface,
  //                                   ),
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     );
  //                   }),
  //                 ],
  //               ],
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildOverallParkedCard(BuildContext context, coreStats) {
  //   final parkedPct = coreStats.parkedPct;

  //   // Calculate which holes had parked throws
  //   final parkedHoles = <DGHole>[];
  //   final notParkedHoles = <DGHole>[];

  //   for (final hole in round.holes) {
  //     bool hadParkedThrow = false;

  //     for (final discThrow in hole.throws) {
  //       if (discThrow.landingSpot == LandingSpot.parked) {
  //         hadParkedThrow = true;
  //         break;
  //       }
  //     }

  //     if (hadParkedThrow) {
  //       parkedHoles.add(hole);
  //     } else {
  //       notParkedHoles.add(hole);
  //     }
  //   }

  //   return Card(
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Theme(
  //         data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
  //         child: ExpansionTile(
  //           tilePadding: EdgeInsets.zero,
  //           childrenPadding: const EdgeInsets.only(top: 8),
  //           title: Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               Text(
  //                 'Parked',
  //                 style: Theme.of(context).textTheme.titleMedium?.copyWith(
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //               ),
  //               Text(
  //                 '${parkedPct.toStringAsFixed(0)}% (${parkedHoles.length}/${round.holes.length})',
  //                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //               ),
  //             ],
  //           ),
  //           subtitle: Padding(
  //             padding: const EdgeInsets.only(top: 8),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   'Holes where you parked your disc (within 10 ft)',
  //                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
  //                         color: Theme.of(context).colorScheme.onSurfaceVariant,
  //                       ),
  //                 ),
  //                 const SizedBox(height: 8),
  //                 ClipRRect(
  //                   borderRadius: BorderRadius.circular(4),
  //                   child: LinearProgressIndicator(
  //                     value: parkedPct / 100,
  //                     minHeight: 12,
  //                     backgroundColor:
  //                         const Color(0xFFFFA726).withValues(alpha: 0.2),
  //                     valueColor: const AlwaysStoppedAnimation<Color>(
  //                       Color(0xFFFFA726),
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //           children: [
  //             const Divider(),
  //             Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 if (parkedHoles.isNotEmpty) ...[
  //                   Text(
  //                     'Parked (${parkedHoles.length})',
  //                     style: Theme.of(context)
  //                         .textTheme
  //                         .bodySmall
  //                         ?.copyWith(fontWeight: FontWeight.bold),
  //                   ),
  //                   const SizedBox(height: 8),
  //                   ...parkedHoles.map((hole) {
  //                     return Padding(
  //                       padding: const EdgeInsets.only(bottom: 4),
  //                       child: Row(
  //                         children: [
  //                           Container(
  //                             width: 24,
  //                             height: 24,
  //                             decoration: const BoxDecoration(
  //                               color: Color(0xFFFFA726),
  //                               shape: BoxShape.circle,
  //                             ),
  //                             child: Center(
  //                               child: Text(
  //                                 '${hole.number}',
  //                                 style: const TextStyle(
  //                                   color: Colors.white,
  //                                   fontWeight: FontWeight.bold,
  //                                   fontSize: 11,
  //                                 ),
  //                               ),
  //                             ),
  //                           ),
  //                           const SizedBox(width: 8),
  //                           Expanded(
  //                             child: Text(
  //                               'Hole ${hole.number} - Par ${hole.par}${hole.feet != null ? ' • ${hole.feet} ft' : ''}',
  //                               style: Theme.of(context).textTheme.bodySmall,
  //                             ),
  //                           ),
  //                           Container(
  //                             padding: const EdgeInsets.symmetric(
  //                               horizontal: 6,
  //                               vertical: 2,
  //                             ),
  //                             decoration: BoxDecoration(
  //                               color: const Color(0xFFFFA726)
  //                                   .withValues(alpha: 0.15),
  //                               borderRadius: BorderRadius.circular(8),
  //                             ),
  //                             child: Text(
  //                               _scoreLabel(hole.relativeHoleScore),
  //                               style: Theme.of(context)
  //                                   .textTheme
  //                                   .bodySmall
  //                                   ?.copyWith(
  //                                     fontSize: 10,
  //                                     color: const Color(0xFFFFA726),
  //                                   ),
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     );
  //                   }),
  //                 ],
  //                 if (parkedHoles.isNotEmpty && notParkedHoles.isNotEmpty) ...[
  //                   const SizedBox(height: 12),
  //                   const Divider(),
  //                   const SizedBox(height: 8),
  //                 ],
  //                 if (notParkedHoles.isNotEmpty) ...[
  //                   Text(
  //                     'Not Parked (${notParkedHoles.length})',
  //                     style: Theme.of(context)
  //                         .textTheme
  //                         .bodySmall
  //                         ?.copyWith(fontWeight: FontWeight.bold),
  //                   ),
  //                   const SizedBox(height: 8),
  //                   ...notParkedHoles.map((hole) {
  //                     return Padding(
  //                       padding: const EdgeInsets.only(bottom: 4),
  //                       child: Row(
  //                         children: [
  //                           Container(
  //                             width: 24,
  //                             height: 24,
  //                             decoration: BoxDecoration(
  //                               color: Theme.of(context)
  //                                   .colorScheme
  //                                   .surfaceContainerHighest,
  //                               shape: BoxShape.circle,
  //                             ),
  //                             child: Center(
  //                               child: Text(
  //                                 '${hole.number}',
  //                                 style: TextStyle(
  //                                   color:
  //                                       Theme.of(context).colorScheme.onSurface,
  //                                   fontWeight: FontWeight.bold,
  //                                   fontSize: 11,
  //                                 ),
  //                               ),
  //                             ),
  //                           ),
  //                           const SizedBox(width: 8),
  //                           Expanded(
  //                             child: Text(
  //                               'Hole ${hole.number} - Par ${hole.par}${hole.feet != null ? ' • ${hole.feet} ft' : ''}',
  //                               style: Theme.of(context).textTheme.bodySmall,
  //                             ),
  //                           ),
  //                           Container(
  //                             padding: const EdgeInsets.symmetric(
  //                               horizontal: 6,
  //                               vertical: 2,
  //                             ),
  //                             decoration: BoxDecoration(
  //                               color: Theme.of(context)
  //                                   .colorScheme
  //                                   .surfaceContainerHighest,
  //                               borderRadius: BorderRadius.circular(8),
  //                             ),
  //                             child: Text(
  //                               _scoreLabel(hole.relativeHoleScore),
  //                               style: Theme.of(context)
  //                                   .textTheme
  //                                   .bodySmall
  //                                   ?.copyWith(
  //                                     fontSize: 10,
  //                                     color: Theme.of(context)
  //                                         .colorScheme
  //                                         .onSurface,
  //                                   ),
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     );
  //                   }),
  //                 ],
  //               ],
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildOverallOBCard(BuildContext context, coreStats) {
  //   final obPct = coreStats.obPct;

  //   // Calculate which holes had OB throws
  //   final obHoles = <DGHole>[];
  //   final notOBHoles = <DGHole>[];

  //   for (final hole in round.holes) {
  //     bool hadOBThrow = false;

  //     for (final discThrow in hole.throws) {
  //       if (discThrow.landingSpot == LandingSpot.outOfBounds) {
  //         hadOBThrow = true;
  //         break;
  //       }
  //     }

  //     if (hadOBThrow) {
  //       obHoles.add(hole);
  //     } else {
  //       notOBHoles.add(hole);
  //     }
  //   }

  //   return Card(
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Theme(
  //         data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
  //         child: ExpansionTile(
  //           tilePadding: EdgeInsets.zero,
  //           childrenPadding: const EdgeInsets.only(top: 8),
  //           title: Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               Text(
  //                 'Out of Bounds',
  //                 style: Theme.of(context).textTheme.titleMedium?.copyWith(
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //               ),
  //               Text(
  //                 '${obPct.toStringAsFixed(0)}% (${obHoles.length}/${round.holes.length})',
  //                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //               ),
  //             ],
  //           ),
  //           subtitle: Padding(
  //             padding: const EdgeInsets.only(top: 8),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   'Holes where you went out of bounds',
  //                   style: Theme.of(context).textTheme.bodySmall?.copyWith(
  //                         color: Theme.of(context).colorScheme.onSurfaceVariant,
  //                       ),
  //                 ),
  //                 const SizedBox(height: 8),
  //                 ClipRRect(
  //                   borderRadius: BorderRadius.circular(4),
  //                   child: LinearProgressIndicator(
  //                     value: obPct / 100,
  //                     minHeight: 12,
  //                     backgroundColor:
  //                         const Color(0xFFFF7A7A).withValues(alpha: 0.2),
  //                     valueColor: const AlwaysStoppedAnimation<Color>(
  //                       Color(0xFFFF7A7A),
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //           children: [
  //             const Divider(),
  //             Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 if (obHoles.isNotEmpty) ...[
  //                   Text(
  //                     'OB (${obHoles.length})',
  //                     style: Theme.of(context)
  //                         .textTheme
  //                         .bodySmall
  //                         ?.copyWith(fontWeight: FontWeight.bold),
  //                   ),
  //                   const SizedBox(height: 8),
  //                   ...obHoles.map((hole) {
  //                     return Padding(
  //                       padding: const EdgeInsets.only(bottom: 4),
  //                       child: Row(
  //                         children: [
  //                           Container(
  //                             width: 24,
  //                             height: 24,
  //                             decoration: const BoxDecoration(
  //                               color: Color(0xFFFF7A7A),
  //                               shape: BoxShape.circle,
  //                             ),
  //                             child: Center(
  //                               child: Text(
  //                                 '${hole.number}',
  //                                 style: const TextStyle(
  //                                   color: Colors.white,
  //                                   fontWeight: FontWeight.bold,
  //                                   fontSize: 11,
  //                                 ),
  //                               ),
  //                             ),
  //                           ),
  //                           const SizedBox(width: 8),
  //                           Expanded(
  //                             child: Text(
  //                               'Hole ${hole.number} - Par ${hole.par}${hole.feet != null ? ' • ${hole.feet} ft' : ''}',
  //                               style: Theme.of(context).textTheme.bodySmall,
  //                             ),
  //                           ),
  //                           Container(
  //                             padding: const EdgeInsets.symmetric(
  //                               horizontal: 6,
  //                               vertical: 2,
  //                             ),
  //                             decoration: BoxDecoration(
  //                               color: const Color(0xFFFF7A7A)
  //                                   .withValues(alpha: 0.15),
  //                               borderRadius: BorderRadius.circular(8),
  //                             ),
  //                             child: Text(
  //                               _scoreLabel(hole.relativeHoleScore),
  //                               style: Theme.of(context)
  //                                   .textTheme
  //                                   .bodySmall
  //                                   ?.copyWith(
  //                                     fontSize: 10,
  //                                     color: const Color(0xFFFF7A7A),
  //                                   ),
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     );
  //                   }),
  //                 ],
  //                 if (obHoles.isNotEmpty && notOBHoles.isNotEmpty) ...[
  //                   const SizedBox(height: 12),
  //                   const Divider(),
  //                   const SizedBox(height: 8),
  //                 ],
  //                 if (notOBHoles.isNotEmpty) ...[
  //                   Text(
  //                     'No OB (${notOBHoles.length})',
  //                     style: Theme.of(context)
  //                         .textTheme
  //                         .bodySmall
  //                         ?.copyWith(fontWeight: FontWeight.bold),
  //                   ),
  //                   const SizedBox(height: 8),
  //                   ...notOBHoles.map((hole) {
  //                     return Padding(
  //                       padding: const EdgeInsets.only(bottom: 4),
  //                       child: Row(
  //                         children: [
  //                           Container(
  //                             width: 24,
  //                             height: 24,
  //                             decoration: BoxDecoration(
  //                               color: Theme.of(context)
  //                                   .colorScheme
  //                                   .surfaceContainerHighest,
  //                               shape: BoxShape.circle,
  //                             ),
  //                             child: Center(
  //                               child: Text(
  //                                 '${hole.number}',
  //                                 style: TextStyle(
  //                                   color:
  //                                       Theme.of(context).colorScheme.onSurface,
  //                                   fontWeight: FontWeight.bold,
  //                                   fontSize: 11,
  //                                 ),
  //                               ),
  //                             ),
  //                           ),
  //                           const SizedBox(width: 8),
  //                           Expanded(
  //                             child: Text(
  //                               'Hole ${hole.number} - Par ${hole.par}${hole.feet != null ? ' • ${hole.feet} ft' : ''}',
  //                               style: Theme.of(context).textTheme.bodySmall,
  //                             ),
  //                           ),
  //                           Container(
  //                             padding: const EdgeInsets.symmetric(
  //                               horizontal: 6,
  //                               vertical: 2,
  //                             ),
  //                             decoration: BoxDecoration(
  //                               color: Theme.of(context)
  //                                   .colorScheme
  //                                   .surfaceContainerHighest,
  //                               borderRadius: BorderRadius.circular(8),
  //                             ),
  //                             child: Text(
  //                               _scoreLabel(hole.relativeHoleScore),
  //                               style: Theme.of(context)
  //                                   .textTheme
  //                                   .bodySmall
  //                                   ?.copyWith(
  //                                     fontSize: 10,
  //                                     color: Theme.of(context)
  //                                         .colorScheme
  //                                         .onSurface,
  //                                   ),
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     );
  //                   }),
  //                 ],
  //               ],
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildC1InRegByThrowType(
  //   BuildContext context,
  //   Map<String, Map<String, double>> circleInRegByType,
  //   Map<String, List<MapEntry<DGHole, DiscThrow>>> allTeeShotsByType,
  // ) {
  //   if (circleInRegByType.isEmpty) {
  //     return const SizedBox.shrink();
  //   }

  //   final sortedEntries = circleInRegByType.entries.toList()
  //     ..sort(
  //       (a, b) => b.value['c1Percentage']!.compareTo(a.value['c1Percentage']!),
  //     );

  //   return Card(
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             'C1 in Regulation by Throw Type',
  //             style: Theme.of(
  //               context,
  //             ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
  //           ),
  //           const SizedBox(height: 8),
  //           Text(
  //             'Holes where you reached C1 with a chance for birdie',
  //             style: Theme.of(context).textTheme.bodySmall?.copyWith(
  //               color: Theme.of(context).colorScheme.onSurfaceVariant,
  //             ),
  //           ),
  //           const SizedBox(height: 16),
  //           ...sortedEntries.map((entry) {
  //             final technique = entry.key;
  //             final stats = entry.value;
  //             final c1Percentage = stats['c1Percentage']!;
  //             final totalAttempts = stats['totalAttempts']!.toInt();
  //             final c1Count = stats['c1Count']!.toInt();
  //             final allThrows = allTeeShotsByType[technique] ?? [];

  //             return Padding(
  //               padding: const EdgeInsets.only(bottom: 12),
  //               child: Theme(
  //                 data: Theme.of(
  //                   context,
  //                 ).copyWith(dividerColor: Colors.transparent),
  //                 child: ExpansionTile(
  //                   tilePadding: EdgeInsets.zero,
  //                   childrenPadding: const EdgeInsets.only(top: 8),
  //                   title: Row(
  //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                     children: [
  //                       Text(
  //                         technique.substring(0, 1).toUpperCase() +
  //                             technique.substring(1),
  //                         style: Theme.of(context).textTheme.bodyMedium,
  //                       ),
  //                       Text(
  //                         '${c1Percentage.toStringAsFixed(0)}% ($c1Count/$totalAttempts)',
  //                         style: Theme.of(context).textTheme.bodyMedium
  //                             ?.copyWith(fontWeight: FontWeight.bold),
  //                       ),
  //                     ],
  //                   ),
  //                   subtitle: Padding(
  //                     padding: const EdgeInsets.only(top: 4),
  //                     child: ClipRRect(
  //                       borderRadius: BorderRadius.circular(4),
  //                       child: LinearProgressIndicator(
  //                         value: c1Percentage / 100,
  //                         minHeight: 12,
  //                         backgroundColor: const Color(
  //                           0xFF4CAF50,
  //                         ).withValues(alpha: 0.2),
  //                         valueColor: const AlwaysStoppedAnimation<Color>(
  //                           Color(0xFF4CAF50),
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                   children: [
  //                     if (allThrows.isNotEmpty) ...[
  //                       const Divider(),
  //                       () {
  //                         final c1Throws = <MapEntry<DGHole, DiscThrow>>[];
  //                         final nonC1Throws = <MapEntry<DGHole, DiscThrow>>[];

  //                         for (final entry in allThrows) {
  //                           final hole = entry.key;
  //                           final regulationStrokes = hole.par - 2;
  //                           bool reachedC1 = false;

  //                           if (regulationStrokes > 0) {
  //                             for (
  //                               int i = 0;
  //                               i < hole.throws.length && i < regulationStrokes;
  //                               i++
  //                             ) {
  //                               final discThrow = hole.throws[i];
  //                               if (discThrow.landingSpot ==
  //                                       LandingSpot.circle1 ||
  //                                   discThrow.landingSpot ==
  //                                       LandingSpot.parked) {
  //                                 reachedC1 = true;
  //                                 break;
  //                               }
  //                             }
  //                           }

  //                           if (reachedC1) {
  //                             c1Throws.add(entry);
  //                           } else {
  //                             nonC1Throws.add(entry);
  //                           }
  //                         }

  //                         return Column(
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           children: [
  //                             if (c1Throws.isNotEmpty) ...[
  //                               Text(
  //                                 'C1 in Reg (${c1Throws.length})',
  //                                 style: Theme.of(context).textTheme.bodySmall
  //                                     ?.copyWith(fontWeight: FontWeight.bold),
  //                               ),
  //                               const SizedBox(height: 8),
  //                               ...c1Throws.map((entry) {
  //                                 final hole = entry.key;
  //                                 final teeShot = entry.value;
  //                                 return Padding(
  //                                   padding: const EdgeInsets.only(bottom: 4),
  //                                   child: Row(
  //                                     children: [
  //                                       Container(
  //                                         width: 24,
  //                                         height: 24,
  //                                         decoration: const BoxDecoration(
  //                                           color: Color(0xFF4CAF50),
  //                                           shape: BoxShape.circle,
  //                                         ),
  //                                         child: Center(
  //                                           child: Text(
  //                                             '${hole.number}',
  //                                             style: const TextStyle(
  //                                               color: Colors.white,
  //                                               fontWeight: FontWeight.bold,
  //                                               fontSize: 11,
  //                                             ),
  //                                           ),
  //                                         ),
  //                                       ),
  //                                       const SizedBox(width: 8),
  //                                       Expanded(
  //                                         child: Text(
  //                                           'Hole ${hole.number} - Par ${hole.par}${hole.feet != null ? ' • ${hole.feet} ft' : ''}',
  //                                           style: Theme.of(
  //                                             context,
  //                                           ).textTheme.bodySmall,
  //                                         ),
  //                                       ),
  //                                       if (teeShot.landingSpot != null)
  //                                         Container(
  //                                           padding: const EdgeInsets.symmetric(
  //                                             horizontal: 6,
  //                                             vertical: 2,
  //                                           ),
  //                                           decoration: BoxDecoration(
  //                                             color: const Color(
  //                                               0xFF4CAF50,
  //                                             ).withValues(alpha: 0.15),
  //                                             borderRadius:
  //                                                 BorderRadius.circular(8),
  //                                           ),
  //                                           child: Text(
  //                                             _landingSpotLabel(
  //                                               teeShot.landingSpot!,
  //                                             ),
  //                                             style: Theme.of(context)
  //                                                 .textTheme
  //                                                 .bodySmall
  //                                                 ?.copyWith(
  //                                                   fontSize: 10,
  //                                                   color: const Color(
  //                                                     0xFF4CAF50,
  //                                                   ),
  //                                                 ),
  //                                           ),
  //                                         ),
  //                                     ],
  //                                   ),
  //                                 );
  //                               }),
  //                             ],
  //                             if (c1Throws.isNotEmpty &&
  //                                 nonC1Throws.isNotEmpty) ...[
  //                               const SizedBox(height: 12),
  //                               const Divider(),
  //                               const SizedBox(height: 8),
  //                             ],
  //                             if (nonC1Throws.isNotEmpty) ...[
  //                               Text(
  //                                 'Other Throws (${nonC1Throws.length})',
  //                                 style: Theme.of(context).textTheme.bodySmall
  //                                     ?.copyWith(fontWeight: FontWeight.bold),
  //                               ),
  //                               const SizedBox(height: 8),
  //                               ...nonC1Throws.map((entry) {
  //                                 final hole = entry.key;
  //                                 final teeShot = entry.value;
  //                                 return Padding(
  //                                   padding: const EdgeInsets.only(bottom: 4),
  //                                   child: Row(
  //                                     children: [
  //                                       Container(
  //                                         width: 24,
  //                                         height: 24,
  //                                         decoration: BoxDecoration(
  //                                           color: Theme.of(context)
  //                                               .colorScheme
  //                                               .surfaceContainerHighest,
  //                                           shape: BoxShape.circle,
  //                                         ),
  //                                         child: Center(
  //                                           child: Text(
  //                                             '${hole.number}',
  //                                             style: TextStyle(
  //                                               color: Theme.of(
  //                                                 context,
  //                                               ).colorScheme.onSurface,
  //                                               fontWeight: FontWeight.bold,
  //                                               fontSize: 11,
  //                                             ),
  //                                           ),
  //                                         ),
  //                                       ),
  //                                       const SizedBox(width: 8),
  //                                       Expanded(
  //                                         child: Text(
  //                                           'Hole ${hole.number} - Par ${hole.par}${hole.feet != null ? ' • ${hole.feet} ft' : ''}',
  //                                           style: Theme.of(
  //                                             context,
  //                                           ).textTheme.bodySmall,
  //                                         ),
  //                                       ),
  //                                       if (teeShot.landingSpot != null)
  //                                         Container(
  //                                           padding: const EdgeInsets.symmetric(
  //                                             horizontal: 6,
  //                                             vertical: 2,
  //                                           ),
  //                                           decoration: BoxDecoration(
  //                                             color: Theme.of(context)
  //                                                 .colorScheme
  //                                                 .surfaceContainerHighest,
  //                                             borderRadius:
  //                                                 BorderRadius.circular(8),
  //                                           ),
  //                                           child: Text(
  //                                             _landingSpotLabel(
  //                                               teeShot.landingSpot!,
  //                                             ),
  //                                             style: Theme.of(context)
  //                                                 .textTheme
  //                                                 .bodySmall
  //                                                 ?.copyWith(
  //                                                   fontSize: 10,
  //                                                   color: Theme.of(
  //                                                     context,
  //                                                   ).colorScheme.onSurface,
  //                                                 ),
  //                                           ),
  //                                         ),
  //                                     ],
  //                                   ),
  //                                 );
  //                               }),
  //                             ],
  //                           ],
  //                         );
  //                       }(),
  //                     ],
  //                   ],
  //                 ),
  //               ),
  //             );
  //           }),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildC2InRegByThrowType(
  //   BuildContext context,
  //   Map<String, Map<String, double>> circleInRegByType,
  //   Map<String, List<MapEntry<DGHole, DiscThrow>>> allTeeShotsByType,
  // ) {
  //   if (circleInRegByType.isEmpty) {
  //     return const SizedBox.shrink();
  //   }

  //   final sortedEntries = circleInRegByType.entries.toList()
  //     ..sort(
  //       (a, b) => b.value['c2Percentage']!.compareTo(a.value['c2Percentage']!),
  //     );

  //   return Card(
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             'C2 in Regulation by Throw Type',
  //             style: Theme.of(
  //               context,
  //             ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
  //           ),
  //           const SizedBox(height: 8),
  //           Text(
  //             'Holes where you reached C2 with a chance for birdie',
  //             style: Theme.of(context).textTheme.bodySmall?.copyWith(
  //               color: Theme.of(context).colorScheme.onSurfaceVariant,
  //             ),
  //           ),
  //           const SizedBox(height: 16),
  //           ...sortedEntries.map((entry) {
  //             final technique = entry.key;
  //             final stats = entry.value;
  //             final c2Percentage = stats['c2Percentage']!;
  //             final totalAttempts = stats['totalAttempts']!.toInt();
  //             final c2Count = stats['c2Count']!.toInt();
  //             final allThrows = allTeeShotsByType[technique] ?? [];

  //             return Padding(
  //               padding: const EdgeInsets.only(bottom: 12),
  //               child: Theme(
  //                 data: Theme.of(
  //                   context,
  //                 ).copyWith(dividerColor: Colors.transparent),
  //                 child: ExpansionTile(
  //                   tilePadding: EdgeInsets.zero,
  //                   childrenPadding: const EdgeInsets.only(top: 8),
  //                   title: Row(
  //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                     children: [
  //                       Text(
  //                         technique.substring(0, 1).toUpperCase() +
  //                             technique.substring(1),
  //                         style: Theme.of(context).textTheme.bodyMedium,
  //                       ),
  //                       Text(
  //                         '${c2Percentage.toStringAsFixed(0)}% ($c2Count/$totalAttempts)',
  //                         style: Theme.of(context).textTheme.bodyMedium
  //                             ?.copyWith(fontWeight: FontWeight.bold),
  //                       ),
  //                     ],
  //                   ),
  //                   subtitle: Padding(
  //                     padding: const EdgeInsets.only(top: 4),
  //                     child: ClipRRect(
  //                       borderRadius: BorderRadius.circular(4),
  //                       child: LinearProgressIndicator(
  //                         value: c2Percentage / 100,
  //                         minHeight: 12,
  //                         backgroundColor: const Color(
  //                           0xFF2196F3,
  //                         ).withValues(alpha: 0.2),
  //                         valueColor: const AlwaysStoppedAnimation<Color>(
  //                           Color(0xFF2196F3),
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                   children: [
  //                     if (allThrows.isNotEmpty) ...[
  //                       const Divider(),
  //                       () {
  //                         final c2Throws = <MapEntry<DGHole, DiscThrow>>[];
  //                         final nonC2Throws = <MapEntry<DGHole, DiscThrow>>[];

  //                         for (final entry in allThrows) {
  //                           final hole = entry.key;
  //                           final regulationStrokes = hole.par - 2;
  //                           bool reachedC2 = false;

  //                           if (regulationStrokes > 0) {
  //                             for (
  //                               int i = 0;
  //                               i < hole.throws.length && i < regulationStrokes;
  //                               i++
  //                             ) {
  //                               final discThrow = hole.throws[i];
  //                               if (discThrow.landingSpot ==
  //                                       LandingSpot.circle1 ||
  //                                   discThrow.landingSpot ==
  //                                       LandingSpot.parked ||
  //                                   discThrow.landingSpot ==
  //                                       LandingSpot.circle2) {
  //                                 reachedC2 = true;
  //                                 break;
  //                               }
  //                             }
  //                           }

  //                           if (reachedC2) {
  //                             c2Throws.add(entry);
  //                           } else {
  //                             nonC2Throws.add(entry);
  //                           }
  //                         }

  //                         return Column(
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           children: [
  //                             if (c2Throws.isNotEmpty) ...[
  //                               Text(
  //                                 'C2 in Reg (${c2Throws.length})',
  //                                 style: Theme.of(context).textTheme.bodySmall
  //                                     ?.copyWith(fontWeight: FontWeight.bold),
  //                               ),
  //                               const SizedBox(height: 8),
  //                               ...c2Throws.map((entry) {
  //                                 final hole = entry.key;
  //                                 final teeShot = entry.value;
  //                                 return Padding(
  //                                   padding: const EdgeInsets.only(bottom: 4),
  //                                   child: Row(
  //                                     children: [
  //                                       Container(
  //                                         width: 24,
  //                                         height: 24,
  //                                         decoration: const BoxDecoration(
  //                                           color: Color(0xFF2196F3),
  //                                           shape: BoxShape.circle,
  //                                         ),
  //                                         child: Center(
  //                                           child: Text(
  //                                             '${hole.number}',
  //                                             style: const TextStyle(
  //                                               color: Colors.white,
  //                                               fontWeight: FontWeight.bold,
  //                                               fontSize: 11,
  //                                             ),
  //                                           ),
  //                                         ),
  //                                       ),
  //                                       const SizedBox(width: 8),
  //                                       Expanded(
  //                                         child: Text(
  //                                           'Hole ${hole.number} - Par ${hole.par}${hole.feet != null ? ' • ${hole.feet} ft' : ''}',
  //                                           style: Theme.of(
  //                                             context,
  //                                           ).textTheme.bodySmall,
  //                                         ),
  //                                       ),
  //                                       if (teeShot.landingSpot != null)
  //                                         Container(
  //                                           padding: const EdgeInsets.symmetric(
  //                                             horizontal: 6,
  //                                             vertical: 2,
  //                                           ),
  //                                           decoration: BoxDecoration(
  //                                             color: const Color(
  //                                               0xFF2196F3,
  //                                             ).withValues(alpha: 0.15),
  //                                             borderRadius:
  //                                                 BorderRadius.circular(8),
  //                                           ),
  //                                           child: Text(
  //                                             _landingSpotLabel(
  //                                               teeShot.landingSpot!,
  //                                             ),
  //                                             style: Theme.of(context)
  //                                                 .textTheme
  //                                                 .bodySmall
  //                                                 ?.copyWith(
  //                                                   fontSize: 10,
  //                                                   color: const Color(
  //                                                     0xFF2196F3,
  //                                                   ),
  //                                                 ),
  //                                           ),
  //                                         ),
  //                                     ],
  //                                   ),
  //                                 );
  //                               }),
  //                             ],
  //                             if (c2Throws.isNotEmpty &&
  //                                 nonC2Throws.isNotEmpty) ...[
  //                               const SizedBox(height: 12),
  //                               const Divider(),
  //                               const SizedBox(height: 8),
  //                             ],
  //                             if (nonC2Throws.isNotEmpty) ...[
  //                               Text(
  //                                 'Other Throws (${nonC2Throws.length})',
  //                                 style: Theme.of(context).textTheme.bodySmall
  //                                     ?.copyWith(fontWeight: FontWeight.bold),
  //                               ),
  //                               const SizedBox(height: 8),
  //                               ...nonC2Throws.map((entry) {
  //                                 final hole = entry.key;
  //                                 final teeShot = entry.value;
  //                                 return Padding(
  //                                   padding: const EdgeInsets.only(bottom: 4),
  //                                   child: Row(
  //                                     children: [
  //                                       Container(
  //                                         width: 24,
  //                                         height: 24,
  //                                         decoration: BoxDecoration(
  //                                           color: Theme.of(context)
  //                                               .colorScheme
  //                                               .surfaceContainerHighest,
  //                                           shape: BoxShape.circle,
  //                                         ),
  //                                         child: Center(
  //                                           child: Text(
  //                                             '${hole.number}',
  //                                             style: TextStyle(
  //                                               color: Theme.of(
  //                                                 context,
  //                                               ).colorScheme.onSurface,
  //                                               fontWeight: FontWeight.bold,
  //                                               fontSize: 11,
  //                                             ),
  //                                           ),
  //                                         ),
  //                                       ),
  //                                       const SizedBox(width: 8),
  //                                       Expanded(
  //                                         child: Text(
  //                                           'Hole ${hole.number} - Par ${hole.par}${hole.feet != null ? ' • ${hole.feet} ft' : ''}',
  //                                           style: Theme.of(
  //                                             context,
  //                                           ).textTheme.bodySmall,
  //                                         ),
  //                                       ),
  //                                       if (teeShot.landingSpot != null)
  //                                         Container(
  //                                           padding: const EdgeInsets.symmetric(
  //                                             horizontal: 6,
  //                                             vertical: 2,
  //                                           ),
  //                                           decoration: BoxDecoration(
  //                                             color: Theme.of(context)
  //                                                 .colorScheme
  //                                                 .surfaceContainerHighest,
  //                                             borderRadius:
  //                                                 BorderRadius.circular(8),
  //                                           ),
  //                                           child: Text(
  //                                             _landingSpotLabel(
  //                                               teeShot.landingSpot!,
  //                                             ),
  //                                             style: Theme.of(context)
  //                                                 .textTheme
  //                                                 .bodySmall
  //                                                 ?.copyWith(
  //                                                   fontSize: 10,
  //                                                   color: Theme.of(
  //                                                     context,
  //                                                   ).colorScheme.onSurface,
  //                                                 ),
  //                                           ),
  //                                         ),
  //                                     ],
  //                                   ),
  //                                 );
  //                               }),
  //                             ],
  //                           ],
  //                         );
  //                       }(),
  //                     ],
  //                   ],
  //                 ),
  //               ),
  //             );
  //           }),
  //         ],
  //       ),
  //     ),
  //   );
  // }

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
  //         const Color(0xFF137e66),
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
                      const Color(0xFF137e66),
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

enum _StatType { c1InReg, c2InReg, parked, outOfBounds }

enum _ThrowTypeStatType { birdieRate, c1InReg, c2InReg }

class _CombinedStatsCard extends StatefulWidget {
  final DGRound round;
  final dynamic coreStats;

  const _CombinedStatsCard({required this.round, required this.coreStats});

  @override
  State<_CombinedStatsCard> createState() => _CombinedStatsCardState();
}

class _CombinedStatsCardState extends State<_CombinedStatsCard> {
  _StatType _selectedStat = _StatType.c1InReg;

  double _getPercentage() {
    switch (_selectedStat) {
      case _StatType.c1InReg:
        return widget.coreStats.c1InRegPct;
      case _StatType.c2InReg:
        return widget.coreStats.c2InRegPct;
      case _StatType.parked:
        return widget.coreStats.parkedPct;
      case _StatType.outOfBounds:
        return widget.coreStats.obPct;
    }
  }

  Color _getColor() {
    switch (_selectedStat) {
      case _StatType.c1InReg:
        return const Color(0xFF137e66);
      case _StatType.c2InReg:
        return const Color(0xFF2196F3);
      case _StatType.parked:
        return const Color(0xFFFFA726);
      case _StatType.outOfBounds:
        return const Color(0xFFFF7A7A);
    }
  }

  (List<DGHole>, List<DGHole>) _getHoleLists() {
    final qualifyingHoles = <DGHole>[];
    final notQualifyingHoles = <DGHole>[];

    for (final hole in widget.round.holes) {
      bool qualifies = false;

      switch (_selectedStat) {
        case _StatType.c1InReg:
          final regulationStrokes = hole.par - 2;
          if (regulationStrokes > 0) {
            for (
              int i = 0;
              i < hole.throws.length && i < regulationStrokes;
              i++
            ) {
              final discThrow = hole.throws[i];
              if (discThrow.landingSpot == LandingSpot.circle1 ||
                  discThrow.landingSpot == LandingSpot.parked) {
                qualifies = true;
                break;
              }
            }
          }
          break;

        case _StatType.c2InReg:
          final regulationStrokes = hole.par - 2;
          if (regulationStrokes > 0) {
            for (
              int i = 0;
              i < hole.throws.length && i < regulationStrokes;
              i++
            ) {
              final discThrow = hole.throws[i];
              if (discThrow.landingSpot == LandingSpot.circle1 ||
                  discThrow.landingSpot == LandingSpot.parked ||
                  discThrow.landingSpot == LandingSpot.circle2) {
                qualifies = true;
                break;
              }
            }
          }
          break;

        case _StatType.parked:
          for (final discThrow in hole.throws) {
            if (discThrow.landingSpot == LandingSpot.parked) {
              qualifies = true;
              break;
            }
          }
          break;

        case _StatType.outOfBounds:
          for (final discThrow in hole.throws) {
            if (discThrow.landingSpot == LandingSpot.outOfBounds) {
              qualifies = true;
              break;
            }
          }
          break;
      }

      if (qualifies) {
        qualifyingHoles.add(hole);
      } else {
        notQualifyingHoles.add(hole);
      }
    }

    return (qualifyingHoles, notQualifyingHoles);
  }

  String _getQualifyingLabel() {
    switch (_selectedStat) {
      case _StatType.c1InReg:
        return 'C1 in Reg';
      case _StatType.c2InReg:
        return 'C2 in Reg';
      case _StatType.parked:
        return 'Parked';
      case _StatType.outOfBounds:
        return 'OB';
    }
  }

  String _getNotQualifyingLabel() {
    switch (_selectedStat) {
      case _StatType.c1InReg:
        return 'Not C1 in Reg';
      case _StatType.c2InReg:
        return 'Not C2 in Reg';
      case _StatType.parked:
        return 'Not Parked';
      case _StatType.outOfBounds:
        return 'No OB';
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

  void _navigateToDetailScreen(
    BuildContext context,
    List<DGHole> qualifyingHoles,
    List<DGHole> notQualifyingHoles,
  ) {
    // Create HoleResult list for all holes in the round
    final List<HoleResult> holeResults = [];

    for (final DGHole hole in widget.round.holes) {
      HoleResultStatus status;

      if (qualifyingHoles.contains(hole)) {
        status = HoleResultStatus.success;
      } else if (notQualifyingHoles.contains(hole)) {
        status = HoleResultStatus.failure;
      } else {
        status = HoleResultStatus.noData;
      }

      holeResults.add(HoleResult(holeNumber: hole.number, status: status));
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DrivingStatDetailScreen(
          statName: _getQualifyingLabel(),
          percentage: _getPercentage(),
          color: _getColor(),
          successCount: qualifyingHoles.length,
          totalHoles: widget.round.holes.length,
          holeResults: holeResults,
        ),
      ),
    );
  }

  Widget _buildTextButton(
    BuildContext context,
    String label,
    _StatType statType,
  ) {
    final isSelected = _selectedStat == statType;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedStat = statType;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final percentage = _getPercentage();
    final color = _getColor();
    final (qualifyingHoles, notQualifyingHoles) = _getHoleLists();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text-based selector
            Row(
              children: [
                Expanded(
                  child: _buildTextButton(context, 'C1 reg', _StatType.c1InReg),
                ),
                Expanded(
                  child: _buildTextButton(context, 'C2 reg', _StatType.c2InReg),
                ),
                Expanded(
                  child: _buildTextButton(context, 'Parked', _StatType.parked),
                ),
                Expanded(
                  child: _buildTextButton(context, 'OB', _StatType.outOfBounds),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Expansion tile with stats
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 8),
                title: Center(
                  child: CircularStatIndicator(
                    label:
                        '${qualifyingHoles.length}/${widget.round.holes.length}',
                    percentage: percentage,
                    color: color,
                    size: 80,
                    strokeWidth: 8,
                    shouldAnimate: true,
                    onPressed: () {
                      _navigateToDetailScreen(
                        context,
                        qualifyingHoles,
                        notQualifyingHoles,
                      );
                    },
                  ),
                ),
                children: [
                  const Divider(),
                  HoleBreakdownList(
                    classifications: [
                      HoleClassification(
                        label:
                            '${_getQualifyingLabel()} (${qualifyingHoles.length})',
                        circleColor: color,
                        holes: qualifyingHoles,
                        getBadgeLabel: (hole) =>
                            _scoreLabel(hole.relativeHoleScore),
                        badgeColor: color,
                      ),
                      HoleClassification(
                        label:
                            '${_getNotQualifyingLabel()} (${notQualifyingHoles.length})',
                        circleColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        holes: notQualifyingHoles,
                        getBadgeLabel: (hole) =>
                            _scoreLabel(hole.relativeHoleScore),
                        badgeColor: Theme.of(context).colorScheme.onSurface,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CombinedThrowTypeStatsCard extends StatefulWidget {
  final Map<String, dynamic> teeShotBirdieRates;
  final Map<String, Map<String, double>> circleInRegByType;
  final Map<String, List<MapEntry<DGHole, DiscThrow>>> allTeeShotsByType;

  const _CombinedThrowTypeStatsCard({
    required this.teeShotBirdieRates,
    required this.circleInRegByType,
    required this.allTeeShotsByType,
  });

  @override
  State<_CombinedThrowTypeStatsCard> createState() =>
      _CombinedThrowTypeStatsCardState();
}

class _CombinedThrowTypeStatsCardState
    extends State<_CombinedThrowTypeStatsCard> {
  _ThrowTypeStatType _selectedStat = _ThrowTypeStatType.birdieRate;

  String _getTitle() {
    switch (_selectedStat) {
      case _ThrowTypeStatType.birdieRate:
        return 'Birdie Rate by Throw Type';
      case _ThrowTypeStatType.c1InReg:
        return 'C1 in Regulation by Throw Type';
      case _ThrowTypeStatType.c2InReg:
        return 'C2 in Regulation by Throw Type';
    }
  }

  String _getDescription() {
    switch (_selectedStat) {
      case _ThrowTypeStatType.birdieRate:
        return '';
      case _ThrowTypeStatType.c1InReg:
        return 'Holes where you reached C1 with a chance for birdie';
      case _ThrowTypeStatType.c2InReg:
        return 'Holes where you reached C2 with a chance for birdie';
    }
  }

  Color _getColor() {
    switch (_selectedStat) {
      case _ThrowTypeStatType.birdieRate:
        return const Color(0xFF137e66);
      case _ThrowTypeStatType.c1InReg:
        return const Color(0xFF4CAF50);
      case _ThrowTypeStatType.c2InReg:
        return const Color(0xFF2196F3);
    }
  }

  List<MapEntry<String, dynamic>> _getSortedEntries() {
    switch (_selectedStat) {
      case _ThrowTypeStatType.birdieRate:
        return widget.teeShotBirdieRates.entries.toList()
          ..sort((a, b) => b.value.percentage.compareTo(a.value.percentage));
      case _ThrowTypeStatType.c1InReg:
        return widget.circleInRegByType.entries.toList()..sort(
          (a, b) =>
              b.value['c1Percentage']!.compareTo(a.value['c1Percentage']!),
        );
      case _ThrowTypeStatType.c2InReg:
        return widget.circleInRegByType.entries.toList()..sort(
          (a, b) =>
              b.value['c2Percentage']!.compareTo(a.value['c2Percentage']!),
        );
    }
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

  Widget _buildTextButton(
    BuildContext context,
    String label,
    _ThrowTypeStatType statType,
  ) {
    final isSelected = _selectedStat == statType;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedStat = statType;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildBirdieRateContent(
    BuildContext context,
    String technique,
    dynamic stats,
    List<MapEntry<DGHole, DiscThrow>> allThrows,
  ) {
    final birdieThrows = allThrows
        .where((e) => e.key.relativeHoleScore < 0)
        .toList();
    final nonBirdieThrows = allThrows
        .where((e) => e.key.relativeHoleScore >= 0)
        .toList();
    final color = _getColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (birdieThrows.isNotEmpty) ...[
          Text(
            'Birdie Throws (${birdieThrows.length})',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
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
                    decoration: BoxDecoration(
                      color: color,
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
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _landingSpotLabel(teeShot.landingSpot!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: color,
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
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
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
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
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
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _landingSpotLabel(teeShot.landingSpot!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
  }

  Widget _buildCircleInRegContent(
    BuildContext context,
    String technique,
    List<MapEntry<DGHole, DiscThrow>> allThrows,
    String circleType, // 'c1' or 'c2'
  ) {
    final qualifyingThrows = <MapEntry<DGHole, DiscThrow>>[];
    final nonQualifyingThrows = <MapEntry<DGHole, DiscThrow>>[];
    final color = _getColor();

    for (final entry in allThrows) {
      final hole = entry.key;
      final regulationStrokes = hole.par - 2;
      bool reachedCircle = false;

      if (regulationStrokes > 0) {
        for (int i = 0; i < hole.throws.length && i < regulationStrokes; i++) {
          final discThrow = hole.throws[i];
          if (circleType == 'c1') {
            if (discThrow.landingSpot == LandingSpot.circle1 ||
                discThrow.landingSpot == LandingSpot.parked) {
              reachedCircle = true;
              break;
            }
          } else {
            // c2
            if (discThrow.landingSpot == LandingSpot.circle1 ||
                discThrow.landingSpot == LandingSpot.parked ||
                discThrow.landingSpot == LandingSpot.circle2) {
              reachedCircle = true;
              break;
            }
          }
        }
      }

      if (reachedCircle) {
        qualifyingThrows.add(entry);
      } else {
        nonQualifyingThrows.add(entry);
      }
    }

    final label = circleType == 'c1' ? 'C1 in Reg' : 'C2 in Reg';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (qualifyingThrows.isNotEmpty) ...[
          Text(
            '$label (${qualifyingThrows.length})',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...qualifyingThrows.map((entry) {
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
                      color: color,
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
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _landingSpotLabel(teeShot.landingSpot!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: color,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
        if (qualifyingThrows.isNotEmpty && nonQualifyingThrows.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
        ],
        if (nonQualifyingThrows.isNotEmpty) ...[
          Text(
            'Other Throws (${nonQualifyingThrows.length})',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...nonQualifyingThrows.map((entry) {
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
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
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
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _landingSpotLabel(teeShot.landingSpot!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
  }

  @override
  Widget build(BuildContext context) {
    if ((_selectedStat == _ThrowTypeStatType.birdieRate &&
            widget.teeShotBirdieRates.isEmpty) ||
        (_selectedStat != _ThrowTypeStatType.birdieRate &&
            widget.circleInRegByType.isEmpty)) {
      return const SizedBox.shrink();
    }

    final sortedEntries = _getSortedEntries();
    final color = _getColor();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text-based selector
            Row(
              children: [
                Expanded(
                  child: _buildTextButton(
                    context,
                    'Birdie Rate',
                    _ThrowTypeStatType.birdieRate,
                  ),
                ),
                Expanded(
                  child: _buildTextButton(
                    context,
                    'C1 in Reg',
                    _ThrowTypeStatType.c1InReg,
                  ),
                ),
                Expanded(
                  child: _buildTextButton(
                    context,
                    'C2 in Reg',
                    _ThrowTypeStatType.c2InReg,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getTitle(),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (_getDescription().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _getDescription(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            ...sortedEntries.map((entry) {
              final technique = entry.key;
              final allThrows = widget.allTeeShotsByType[technique] ?? [];

              String percentageText;
              double percentage;

              if (_selectedStat == _ThrowTypeStatType.birdieRate) {
                final stats = entry.value;
                percentage = stats.percentage;
                percentageText =
                    '${percentage.toStringAsFixed(0)}% (${stats.birdieCount}/${stats.totalAttempts})';
              } else if (_selectedStat == _ThrowTypeStatType.c1InReg) {
                final stats = entry.value;
                percentage = stats['c1Percentage']!;
                final totalAttempts = stats['totalAttempts']!.toInt();
                final c1Count = stats['c1Count']!.toInt();
                percentageText =
                    '${percentage.toStringAsFixed(0)}% ($c1Count/$totalAttempts)';
              } else {
                // c2InReg
                final stats = entry.value;
                percentage = stats['c2Percentage']!;
                final totalAttempts = stats['totalAttempts']!.toInt();
                final c2Count = stats['c2Count']!.toInt();
                percentageText =
                    '${percentage.toStringAsFixed(0)}% ($c2Count/$totalAttempts)';
              }

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
                          percentageText,
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
                          backgroundColor: color.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ),
                    children: [
                      if (allThrows.isNotEmpty) ...[
                        const Divider(),
                        if (_selectedStat == _ThrowTypeStatType.birdieRate)
                          _buildBirdieRateContent(
                            context,
                            technique,
                            entry.value,
                            allThrows,
                          )
                        else if (_selectedStat == _ThrowTypeStatType.c1InReg)
                          _buildCircleInRegContent(
                            context,
                            technique,
                            allThrows,
                            'c1',
                          )
                        else
                          _buildCircleInRegContent(
                            context,
                            technique,
                            allThrows,
                            'c2',
                          ),
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
}
