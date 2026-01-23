import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turbo_disc_golf/locator.dart';
import 'package:turbo_disc_golf/models/data/hole_data.dart';
import 'package:turbo_disc_golf/models/data/round_data.dart';
import 'package:turbo_disc_golf/models/data/throw_data.dart';
import 'package:turbo_disc_golf/models/statistics_models.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/drives_detail/components/core_drive_stats_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/drives_detail/components/throw_type_list_card.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/drives_detail/components/throw_type_radar_chart.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/drives_detail/components/view_mode_toggle.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/drives_detail/models/shot_detail.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/drives_detail/models/throw_type_stats.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/drives_detail/screens/driving_stat_detail_screen.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/drives_detail/screens/throw_type_detail_screen.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/drives_detail/tabs/landing_spots_tab.dart';
import 'package:turbo_disc_golf/screens/round_review/tabs/round_stats_tab/detail_screens/drives_detail/tabs/shot_types_tab.dart';
import 'package:turbo_disc_golf/services/feature_flags/feature_flag_service.dart';
import 'package:turbo_disc_golf/services/logging/logging_service.dart';
import 'package:turbo_disc_golf/services/round_statistics_service.dart';
import 'package:turbo_disc_golf/utils/layout_helpers.dart';
import 'package:turbo_disc_golf/utils/constants/regulation_constants.dart';
import 'package:turbo_disc_golf/utils/navigation_helpers.dart';

class DrivesDetailScreen extends StatefulWidget {
  static const String screenName = 'Drives Detail';

  const DrivesDetailScreen({super.key, required this.round});

  final DGRound round;

  @override
  State<DrivesDetailScreen> createState() => _DrivesDetailScreenState();
}

class _DrivesDetailScreenState extends State<DrivesDetailScreen>
    with SingleTickerProviderStateMixin {
  DriveViewMode _viewMode = DriveViewMode.cards;
  late final LoggingServiceBase _logger;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _logger = locator.get<LoggingService>().withBaseProperties({
      'screen_name': DrivesDetailScreen.screenName,
    });
    _logger.logScreenImpression('DrivesTab');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

    _logger.track(
      'Driving Stat Detail Tapped',
      properties: {
        'stat_name': statName,
        'percentage': percentage,
        'success_count': successHoles.length,
        'total_holes': widget.round.holes.length,
      },
    );

    Navigator.of(context).push(
      CupertinoPageRoute(
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

    // Calculate average distance and landing spot stats
    double? averageDistance;
    int parkedCount = 0;
    int fairwayCount = 0;
    int totalTeeShotsByType = 0;

    final teeShots = allTeeShotsByType[throwType];
    if (teeShots != null && teeShots.isNotEmpty) {
      totalTeeShotsByType = teeShots.length;

      final holesWithDistance = teeShots
          .where((entry) => entry.key.feet > 0)
          .toList();
      if (holesWithDistance.isNotEmpty) {
        final totalDistance = holesWithDistance.fold<double>(
          0,
          (sum, entry) => sum + (entry.key.feet.toDouble()),
        );
        averageDistance = totalDistance / holesWithDistance.length;
      }

      // Count parked and fairway landings
      for (final entry in teeShots) {
        final DiscThrow throw_ = entry.value;
        final LandingSpot? landing = throw_.landingSpot;

        if (landing == LandingSpot.parked) {
          parkedCount++;
        }

        if (landing == LandingSpot.fairway ||
            landing == LandingSpot.circle1 ||
            landing == LandingSpot.circle2 ||
            landing == LandingSpot.parked) {
          fairwayCount++;
        }
      }
    }

    final double parkedPct = totalTeeShotsByType > 0
        ? (parkedCount / totalTeeShotsByType) * 100
        : 0.0;
    final double fairwayPct = totalTeeShotsByType > 0
        ? (fairwayCount / totalTeeShotsByType) * 100
        : 0.0;

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
        parkedPct: parkedPct,
        parkedCount: parkedCount,
        fairwayPct: fairwayPct,
        fairwayCount: fairwayCount,
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
      parkedPct: parkedPct,
      parkedCount: parkedCount,
      fairwayPct: fairwayPct,
      fairwayCount: fairwayCount,
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
          shotDetails.add(
            ShotDetail(hole: hole, throwIndex: i, shotOutcome: outcome),
          );
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
            shotDetailsByShape[shapeKey]!.add(
              ShotDetail(hole: hole, throwIndex: i, shotOutcome: outcome),
            );
          }
        }
      }
    }

    return shotDetailsByShape;
  }

  /// Calculate whether a shot was successful for various metrics
  ShotOutcome _calculateShotOutcome(DGHole hole, int throwIndex) {
    final DiscThrow discThrow = hole.throws[throwIndex];
    final bool isEligibleForCircleInReg =
        isThrowEligibleForCircleInReg(throwIndex, hole.par);

    // Determine if this led to a birdie
    final bool wasBirdie = hole.relativeHoleScore < 0;

    // Only count circle in regulation for throws that could realistically reach C1
    // Par 3: tee shot (throwIndex 0), Par 4: approach (throwIndex 1), etc.
    bool wasC1InReg = false;
    bool wasC2InReg = false;
    if (isEligibleForCircleInReg) {
      wasC1InReg = isC1Landing(discThrow.landingSpot);
      wasC2InReg = isC2Landing(discThrow.landingSpot);
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
    final List<ShotDetail> overallShotDetails = _getShotDetailsForThrowType(
      throwType,
    );

    // Get shot details grouped by shot shape
    final Map<String, List<ShotDetail>> shotShapeDetails =
        _getShotDetailsByShape(throwType);

    _logger.track(
      'Throw Type Detail Tapped',
      properties: {
        'throw_type': throwType,
        'birdie_rate': overallStats.birdieRate,
        'c1_in_reg_pct': overallStats.c1InRegPct,
        'total_holes': overallStats.totalHoles,
      },
    );

    pushCupertinoRoute(
      context,
      ThrowTypeDetailScreen(
        throwType: throwType,
        overallStats: overallStats,
        shotShapeStats: shotShapes,
        overallShotDetails: overallShotDetails,
        shotShapeDetails: shotShapeDetails,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final RoundStatisticsService statsService = RoundStatisticsService(
      widget.round,
    );
    final featureFlagService = locator.get<FeatureFlagService>();
    final useV2 = featureFlagService.drivesDetailScreenV2;

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

    if (useV2) {
      // Get landing spot distribution for V2 layout
      final landingSpotData = statsService.getLandingSpotDistributionByPar();

      return Column(
        children: [
          TabBar(
            controller: _tabController,
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black54,
            indicatorColor: Colors.black,
            indicatorWeight: 2,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
            labelPadding: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            indicatorPadding: EdgeInsets.zero,
            onTap: (_) => HapticFeedback.lightImpact(),
            tabs: const [
              Tab(text: 'Landing spots'),
              Tab(text: 'Technique'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                LandingSpotsTab(
                  coreStats: coreStats,
                  landingSpotDistributionByPar: landingSpotData,
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
                ShotTypesTab(
                  allThrowTypes: allThrowTypes,
                  shotShapeBirdieRates: shotShapeBirdieRates,
                  circleInRegByShape: circleInRegByShape,
                  onThrowTypeTap: (ThrowTypeStats stats) {
                    _navigateToThrowTypeDetail(
                      context,
                      stats.throwType,
                      stats,
                      shotShapeBirdieRates,
                      circleInRegByShape,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }

    return _buildLayoutV1(
      context,
      allThrowTypes,
      coreStats,
      performanceByFairwayWidth,
      shotShapeBirdieRates,
      circleInRegByShape,
    );
  }

  /// Build V1 layout (original layout)
  Widget _buildLayoutV1(
    BuildContext context,
    List<ThrowTypeStats> allThrowTypes,
    CoreStats coreStats,
    Map<String, Map<String, double>> performanceByFairwayWidth,
    Map<String, dynamic> shotShapeBirdieRates,
    Map<String, Map<String, double>> circleInRegByShape,
  ) {
    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 80),
      children: addRunSpacing(
        [
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
          ViewModeToggle(
            selectedMode: _viewMode,
            onModeChanged: (DriveViewMode mode) {
              _logger.track(
                'Drives View Mode Changed',
                properties: {
                  'view_mode': mode == DriveViewMode.cards ? 'cards' : 'radar',
                },
              );
              setState(() {
                _viewMode = mode;
              });
            },
          ),
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
          if (performanceByFairwayWidth.isNotEmpty)
            _buildPerformanceByFairwayWidth(context, performanceByFairwayWidth),
        ],
        runSpacing: 8,
        axis: Axis.vertical,
      ),
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
